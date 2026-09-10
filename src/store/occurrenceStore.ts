import { create } from 'zustand'
import { DEFAULT_RESOURCE_PACKAGES } from '../data/resourcesConfig'
import { DEFAULT_RISK_AREAS } from '../data/riskAreasConfig'
import { DEFAULT_RISK_MATRIX_CONFIG, type RiskMatrixConfig } from '../data/riskMatrixConfig'
import { DEFAULT_VEGETATION_TYPES } from '../data/vegetationConfig'
import { generateId } from '../lib/id'
import { loadFromStorage, saveToStorage } from '../lib/storage'
import type {
  Feedback,
  Focus,
  FocusSource,
  Occurrence,
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

const OCCURRENCES_KEY = 'aceiro_occurrences'
const CONFIG_KEY = 'aceiro_config'

interface OccurrenceState {
  occurrences: Record<string, Occurrence>
  config: AppConfig

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

function persistOccurrences(occurrences: Record<string, Occurrence>) {
  saveToStorage(OCCURRENCES_KEY, occurrences)
}

export const useOccurrenceStore = create<OccurrenceState>((set) => ({
  occurrences: loadFromStorage(OCCURRENCES_KEY, {}),
  config: loadFromStorage(CONFIG_KEY, DEFAULT_CONFIG),

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
    set((state) => {
      const occurrences = { ...state.occurrences, [id]: occurrence }
      persistOccurrences(occurrences)
      return { occurrences }
    })
    return id
  },

  setClassification: (id, result) =>
    set((state) => {
      const occurrence = state.occurrences[id]
      if (!occurrence) return state
      const occurrences = { ...state.occurrences, [id]: { ...occurrence, classification: result } }
      persistOccurrences(occurrences)
      return { occurrences }
    }),

  setConfirmation: (id, confirmation) =>
    set((state) => {
      const occurrence = state.occurrences[id]
      if (!occurrence) return state
      const occurrences = { ...state.occurrences, [id]: { ...occurrence, confirmation } }
      persistOccurrences(occurrences)
      return { occurrences }
    }),

  setRiskCalculation: (id, calc) =>
    set((state) => {
      const occurrence = state.occurrences[id]
      if (!occurrence) return state
      const occurrences = { ...state.occurrences, [id]: { ...occurrence, riskCalculation: calc } }
      persistOccurrences(occurrences)
      return { occurrences }
    }),

  setRecommendation: (id, rec) =>
    set((state) => {
      const occurrence = state.occurrences[id]
      if (!occurrence) return state
      const occurrences = { ...state.occurrences, [id]: { ...occurrence, recommendation: rec, status: 'em_andamento' as const } }
      persistOccurrences(occurrences)
      return { occurrences }
    }),

  setFeedback: (id, feedback) =>
    set((state) => {
      const occurrence = state.occurrences[id]
      if (!occurrence) return state
      const occurrences = { ...state.occurrences, [id]: { ...occurrence, feedback, status: 'concluida' as const } }
      persistOccurrences(occurrences)
      return { occurrences }
    }),

  updateConfig: (partial) =>
    set((state) => {
      const config = { ...state.config, ...partial }
      saveToStorage(CONFIG_KEY, config)
      return { config }
    }),

  resetConfig: () => {
    saveToStorage(CONFIG_KEY, DEFAULT_CONFIG)
    set({ config: DEFAULT_CONFIG })
  },
}))

export function getOccurrenceList(occurrences: Record<string, Occurrence>): Occurrence[] {
  return Object.values(occurrences).sort((a, b) => b.createdAt.localeCompare(a.createdAt))
}
