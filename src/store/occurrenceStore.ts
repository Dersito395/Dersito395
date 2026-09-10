import { create } from 'zustand'
import { DEFAULT_RESOURCE_PACKAGES } from '../data/resourcesConfig'
import { DEFAULT_RISK_AREAS } from '../data/riskAreasConfig'
import { DEFAULT_RISK_MATRIX_CONFIG, type RiskMatrixConfig } from '../data/riskMatrixConfig'
import { DEFAULT_VEGETATION_TYPES } from '../data/vegetationConfig'
import { generateId } from '../lib/id'
import { isSupabaseConfigured, supabase } from '../lib/supabaseClient'
import type {
  Feedback,
  Focus,
  FocusSource,
  Occurrence,
  OccurrenceStatus,
  OperatorConfirmation,
  Recommendation,
  ResourceItem,
  RiskArea,
  RiskCalculation,
  RiskLevel,
  SmokeClassificationResult,
  VegetationType,
} from '../types/domain'

export interface AppConfig {
  vegetationTypes: VegetationType[]
  riskAreas: RiskArea[]
  resourcePackages: Record<RiskLevel, ResourceItem[]>
  riskMatrix: RiskMatrixConfig
}

const DEFAULT_CONFIG: AppConfig = {
  vegetationTypes: DEFAULT_VEGETATION_TYPES,
  riskAreas: DEFAULT_RISK_AREAS,
  resourcePackages: DEFAULT_RESOURCE_PACKAGES,
  riskMatrix: DEFAULT_RISK_MATRIX_CONFIG,
}

const CONFIG_ROW_ID = 'default'

type ConnectionStatus = 'idle' | 'loading' | 'ready' | 'not_configured' | 'error'

interface OccurrenceRow {
  id: string
  status: OccurrenceStatus
  created_at: string
  focus: Focus
  classification: SmokeClassificationResult | null
  confirmation: OperatorConfirmation | null
  risk_calculation: RiskCalculation | null
  recommendation: Recommendation | null
  feedback: Feedback | null
}

interface ConfigRow {
  id: string
  vegetation_types: VegetationType[]
  risk_areas: RiskArea[]
  resource_packages: Record<RiskLevel, ResourceItem[]>
  risk_matrix: RiskMatrixConfig
}

function rowToOccurrence(row: OccurrenceRow): Occurrence {
  return {
    id: row.id,
    status: row.status,
    createdAt: row.created_at,
    focus: row.focus,
    classification: row.classification ?? undefined,
    confirmation: row.confirmation ?? undefined,
    riskCalculation: row.risk_calculation ?? undefined,
    recommendation: row.recommendation ?? undefined,
    feedback: row.feedback ?? undefined,
  }
}

function occurrenceToRow(o: Occurrence): OccurrenceRow {
  return {
    id: o.id,
    status: o.status,
    created_at: o.createdAt,
    focus: o.focus,
    classification: o.classification ?? null,
    confirmation: o.confirmation ?? null,
    risk_calculation: o.riskCalculation ?? null,
    recommendation: o.recommendation ?? null,
    feedback: o.feedback ?? null,
  }
}

function rowToConfig(row: ConfigRow): AppConfig {
  return {
    vegetationTypes: row.vegetation_types,
    riskAreas: row.risk_areas,
    resourcePackages: row.resource_packages,
    riskMatrix: row.risk_matrix,
  }
}

function configToRow(config: AppConfig): ConfigRow {
  return {
    id: CONFIG_ROW_ID,
    vegetation_types: config.vegetationTypes,
    risk_areas: config.riskAreas,
    resource_packages: config.resourcePackages,
    risk_matrix: config.riskMatrix,
  }
}

interface OccurrenceState {
  occurrences: Record<string, Occurrence>
  config: AppConfig
  connectionStatus: ConnectionStatus
  connectionError: string | null
  /** Erro da última tentativa de sincronizar uma escrita com o backend (não bloqueia a UI, é exibido como aviso). */
  syncError: string | null

  init: () => Promise<void>
  createFocus: (input: {
    source: FocusSource
    coordinates?: { lat: number; lng: number }
    soilHumidityPercent: number
    mediaNote?: string
  }) => string
  setClassification: (id: string, result: SmokeClassificationResult) => void
  setConfirmation: (id: string, confirmation: OperatorConfirmation) => void
  setRiskCalculation: (id: string, calc: RiskCalculation) => void
  setRecommendation: (id: string, rec: Recommendation) => void
  setFeedback: (id: string, feedback: Feedback) => void
  updateConfig: (partial: Partial<AppConfig>) => void
  resetConfig: () => void
}

/** Aplica uma escrita em segundo plano: a UI já foi atualizada de forma otimista, isto só reporta falha de sincronização. */
function syncInBackground(promise: PromiseLike<{ error: { message: string } | null }>) {
  Promise.resolve(promise).then(({ error }) => {
    useOccurrenceStore.setState({ syncError: error ? error.message : null })
  })
}

function updateOccurrence(id: string, patch: (o: Occurrence) => Occurrence) {
  const state = useOccurrenceStore.getState()
  const occurrence = state.occurrences[id]
  if (!occurrence) return
  const updated = patch(occurrence)
  useOccurrenceStore.setState({ occurrences: { ...state.occurrences, [id]: updated } })
  syncInBackground(supabase.from('occurrences').update(occurrenceToRow(updated)).eq('id', id))
}

export const useOccurrenceStore = create<OccurrenceState>((set, get) => ({
  occurrences: {},
  config: DEFAULT_CONFIG,
  connectionStatus: 'idle',
  connectionError: null,
  syncError: null,

  init: async () => {
    if (get().connectionStatus === 'loading' || get().connectionStatus === 'ready') return
    if (!isSupabaseConfigured) {
      set({ connectionStatus: 'not_configured' })
      return
    }
    set({ connectionStatus: 'loading' })
    try {
      const [occurrencesRes, configRes] = await Promise.all([
        supabase.from('occurrences').select('*').order('created_at', { ascending: false }),
        supabase.from('app_config').select('*').eq('id', CONFIG_ROW_ID).maybeSingle(),
      ])
      if (occurrencesRes.error) throw occurrencesRes.error
      if (configRes.error) throw configRes.error

      const occurrences: Record<string, Occurrence> = {}
      for (const row of (occurrencesRes.data ?? []) as OccurrenceRow[]) {
        occurrences[row.id] = rowToOccurrence(row)
      }

      let config = DEFAULT_CONFIG
      if (configRes.data) {
        config = rowToConfig(configRes.data as ConfigRow)
      } else {
        // Primeira vez que este projeto Supabase é usado: grava os padrões.
        const { error } = await supabase.from('app_config').insert(configToRow(DEFAULT_CONFIG))
        if (error) throw error
      }

      set({ occurrences, config, connectionStatus: 'ready', connectionError: null })
    } catch (err) {
      set({ connectionStatus: 'error', connectionError: err instanceof Error ? err.message : 'Falha ao conectar ao backend.' })
    }
  },

  createFocus: (input) => {
    const id = generateId('oco')
    const focus: Focus = {
      id: generateId('foco'),
      source: input.source,
      detectedAt: new Date().toISOString(),
      coordinates: input.coordinates,
      soilHumidityPercent: input.soilHumidityPercent,
      mediaNote: input.mediaNote,
    }
    const occurrence: Occurrence = { id, status: 'rascunho', createdAt: new Date().toISOString(), focus }
    set((state) => ({ occurrences: { ...state.occurrences, [id]: occurrence } }))
    syncInBackground(supabase.from('occurrences').insert(occurrenceToRow(occurrence)))
    return id
  },

  setClassification: (id, result) => updateOccurrence(id, (o) => ({ ...o, classification: result })),

  setConfirmation: (id, confirmation) => updateOccurrence(id, (o) => ({ ...o, confirmation })),

  setRiskCalculation: (id, calc) => updateOccurrence(id, (o) => ({ ...o, riskCalculation: calc })),

  setRecommendation: (id, rec) => updateOccurrence(id, (o) => ({ ...o, recommendation: rec, status: 'em_andamento' as const })),

  setFeedback: (id, feedback) => updateOccurrence(id, (o) => ({ ...o, feedback, status: 'concluida' as const })),

  updateConfig: (partial) => {
    const config = { ...get().config, ...partial }
    set({ config })
    syncInBackground(supabase.from('app_config').upsert(configToRow(config)))
  },

  resetConfig: () => {
    set({ config: DEFAULT_CONFIG })
    syncInBackground(supabase.from('app_config').upsert(configToRow(DEFAULT_CONFIG)))
  },
}))

export function getOccurrenceList(occurrences: Record<string, Occurrence>): Occurrence[] {
  return Object.values(occurrences).sort((a, b) => b.createdAt.localeCompare(a.createdAt))
}
