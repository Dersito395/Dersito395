/**
 * Camada de analytics do MVP. Hoje persiste localmente (localStorage) para
 * permitir validar o funil e a aderência de produtos sem backend. A função
 * `track` é o único ponto de integração: trocar seu corpo por uma chamada de
 * API é suficiente para migrar para um backend real sem tocar nas páginas.
 */

export type AnalyticsEvent =
  | { name: 'simulador_iniciado' }
  | { name: 'tipo_imovel_selecionado'; propertyTypeId: string }
  | { name: 'areas_selecionadas'; areaIds: string[] }
  | { name: 'pergunta_respondida'; questionId: string; areaId: string; optionIds: string[] }
  | { name: 'etapa_abandonada'; step: string }
  | { name: 'simulacao_concluida'; overallSafetyScore: number; overallLevel: string }
  | { name: 'produto_recomendado_visualizado'; productId: string; relevance: number }
  | { name: 'produto_clicado'; productId: string; origin: 'resultado' | 'vitrine' }
  | { name: 'cta_contato_clicado'; productId: string; channel: 'whatsapp' | 'orcamento' }
  | { name: 'resultado_salvo'; method: 'email' | 'pdf' }

interface StoredEvent {
  id: string
  timestamp: string
  event: AnalyticsEvent
}

const STORAGE_KEY = 'fireapp_analytics_events'

function readEvents(): StoredEvent[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? (JSON.parse(raw) as StoredEvent[]) : []
  } catch {
    return []
  }
}

function writeEvents(events: StoredEvent[]) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(events.slice(-500)))
  } catch {
    // localStorage indisponível (modo privado, quota excedida) — falha silenciosa
  }
}

export function track(event: AnalyticsEvent) {
  const stored: StoredEvent = {
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    timestamp: new Date().toISOString(),
    event,
  }
  const events = readEvents()
  events.push(stored)
  writeEvents(events)
  if (import.meta.env.DEV) {
    // eslint-disable-next-line no-console
    console.debug('[analytics]', event.name, event)
  }
}

export function getEvents(): StoredEvent[] {
  return readEvents()
}

export function clearEvents() {
  writeEvents([])
}

export function exportEventsAsJson(): string {
  return JSON.stringify(readEvents(), null, 2)
}

export function getProductClickCounts(): Record<string, number> {
  const counts: Record<string, number> = {}
  for (const { event } of readEvents()) {
    if (event.name === 'produto_clicado') {
      counts[event.productId] = (counts[event.productId] ?? 0) + 1
    }
  }
  return counts
}
