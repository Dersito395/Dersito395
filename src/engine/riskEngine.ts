import { areas } from '../data/areas'
import { propertyTypes } from '../data/propertyTypes'
import { products } from '../data/products'
import { globalQuestions, questionsByArea } from '../data/questions'
import type {
  AnswersMap,
  AreaId,
  FireClass,
  Product,
  ProductId,
  PropertyTypeId,
  Question,
  RiskLevel,
} from '../types/domain'

export interface AreaResult {
  areaId: AreaId
  label: string
  safetyScore: number
  level: RiskLevel
  identifiedRisks: string[]
  fireClasses: FireClass[]
}

export interface RecommendedProduct {
  product: Product
  relevance: number
  reasons: string[]
  suggestedQuantity: number
  quantityNote: string
}

export interface SimulationResult {
  overallSafetyScore: number
  overallLevel: RiskLevel
  areaResults: AreaResult[]
  recommendedProducts: RecommendedProduct[]
}

function levelFromSafetyScore(score: number): RiskLevel {
  if (score >= 75) return 'baixo'
  if (score >= 50) return 'medio'
  if (score >= 25) return 'alto'
  return 'critico'
}

function questionMaxPoints(question: Question): number {
  return Math.max(...question.options.map((o) => Math.max(o.riskPoints, 0)), 0)
}

function emptyProductMap<T>(factory: () => T): Record<ProductId, T> {
  return products.reduce(
    (acc, p) => {
      acc[p.id] = factory()
      return acc
    },
    {} as Record<ProductId, T>,
  )
}

function quantityNoteFor(product: Product, areaLabels: Set<string>): { quantity: number; note: string } {
  if (product.quantityModel === 'fixed') {
    return { quantity: 1, note: '1 unidade recomendada para a propriedade' }
  }
  const quantity = Math.max(1, areaLabels.size)
  const note =
    areaLabels.size > 0
      ? `${quantity} unidade${quantity > 1 ? 's' : ''} sugerida${quantity > 1 ? 's' : ''} — ${Array.from(areaLabels)
          .map((label) => `1 para ${label}`)
          .join(', ')}`
      : '1 unidade sugerida'
  return { quantity, note }
}

export function calculateSimulation(
  propertyTypeId: PropertyTypeId,
  selectedAreas: AreaId[],
  answers: AnswersMap,
): SimulationResult {
  const propertyType = propertyTypes.find((p) => p.id === propertyTypeId)
  const productScores = emptyProductMap<number>(() => 0)
  const productReasons = emptyProductMap<Set<string>>(() => new Set<string>())
  const productAreas = emptyProductMap<Set<string>>(() => new Set<string>())

  let globalRaw = 0
  let globalMax = 0
  for (const q of globalQuestions) {
    globalMax += questionMaxPoints(q)
    const selectedIds = answers[q.id] ?? []
    for (const optId of selectedIds) {
      const opt = q.options.find((o) => o.id === optId)
      if (!opt) continue
      globalRaw += opt.riskPoints
      if (opt.productBoost) {
        for (const [pid, weight] of Object.entries(opt.productBoost)) {
          productScores[pid as ProductId] += weight ?? 0
        }
      }
    }
  }

  const areaResults: AreaResult[] = selectedAreas.map((areaId) => {
    const areaMeta = areas.find((a) => a.id === areaId)!
    const areaQuestions = questionsByArea[areaId] ?? []
    let raw = 0
    let max = 0
    const identifiedRisks: string[] = []
    const fireClasses = new Set<FireClass>()

    for (const q of areaQuestions) {
      max += questionMaxPoints(q)
      const selectedIds = answers[q.id] ?? []
      for (const optId of selectedIds) {
        const opt = q.options.find((o) => o.id === optId)
        if (!opt) continue
        raw += opt.riskPoints
        if (opt.riskPoints > 0) {
          identifiedRisks.push(q.text)
          opt.fireClasses?.forEach((fc) => fireClasses.add(fc))
        }
        if (opt.productBoost) {
          for (const [pid, weight] of Object.entries(opt.productBoost)) {
            productScores[pid as ProductId] += weight ?? 0
            productReasons[pid as ProductId].add(`${areaMeta.label}: ${q.text}`)
            productAreas[pid as ProductId].add(areaMeta.label)
          }
        }
      }
    }

    const normalizedRaw = max > 0 ? Math.max(0, Math.min(1, raw / max)) : 0
    const safetyScore = Math.round(100 - normalizedRaw * 100)

    return {
      areaId,
      label: areaMeta.label,
      safetyScore,
      level: levelFromSafetyScore(safetyScore),
      identifiedRisks,
      fireClasses: Array.from(fireClasses),
    }
  })

  const areaAvgSafety =
    areaResults.length > 0
      ? areaResults.reduce((sum, a) => sum + a.safetyScore, 0) / areaResults.length
      : 100

  const globalNormalized = globalMax > 0 ? Math.max(-1, Math.min(1, globalRaw / globalMax)) : 0
  const basePenalty = propertyType ? propertyType.baseRiskPoints : 0

  const overallRaw = areaAvgSafety - globalNormalized * 15 - basePenalty
  const overallSafetyScore = Math.round(Math.max(0, Math.min(100, overallRaw)))
  const overallLevel = levelFromSafetyScore(overallSafetyScore)

  const recommendedProducts: RecommendedProduct[] = products
    .map((product) => {
      const { quantity, note } = quantityNoteFor(product, productAreas[product.id])
      return {
        product,
        relevance: productScores[product.id],
        reasons: Array.from(productReasons[product.id]),
        suggestedQuantity: quantity,
        quantityNote: note,
      }
    })
    .sort((a, b) => b.relevance - a.relevance)
    .filter((r, idx) => r.relevance > 0 || idx === 0)

  if (recommendedProducts.every((r) => r.relevance === 0)) {
    const detector = recommendedProducts.find((r) => r.product.id === 'detector_fumaca')
    if (detector) {
      detector.reasons.push('Monitoramento preventivo recomendado mesmo em ambientes de baixo risco.')
    }
  }

  return { overallSafetyScore, overallLevel, areaResults, recommendedProducts }
}
