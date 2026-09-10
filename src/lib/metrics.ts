import type { Occurrence } from '../types/domain'

/**
 * Indicadores do loop de aprendizado (seção 5 da especificação). Calculados
 * a partir do histórico de ocorrências já registrado — sem esses dados
 * reais, o app deixa isso explícito em vez de simular acurácia.
 */
export interface ModelMetrics {
  totalOccurrences: number
  totalWithFeedback: number
  /** % de ocorrências em que a hipótese de maior probabilidade do classificador já bateu com a confirmação do operador em campo. */
  topHypothesisMatchRate: number | null
  /** % de ocorrências com feedback em que a vegetação confirmada em campo se confirmou depois do incêndio controlado. */
  postIncidentAccuracyRate: number | null
  /** % de recomendações aceitas sem alteração pelo operador. */
  recommendationAcceptedRate: number | null
  /** % de ocorrências com feedback em que os recursos foram insuficientes. */
  underProvisionedRate: number | null
  /** % de ocorrências com feedback em que os recursos ficaram ociosos. */
  overProvisionedRate: number | null
  confidenceLabel: string
}

function percent(count: number, total: number): number | null {
  if (total === 0) return null
  return Math.round((count / total) * 1000) / 10
}

export function computeModelMetrics(occurrences: Occurrence[]): ModelMetrics {
  const withClassificationAndConfirmation = occurrences.filter((o) => o.classification && o.confirmation)
  const withRecommendation = occurrences.filter((o) => o.recommendation)
  const withFeedback = occurrences.filter((o) => o.feedback)

  const topMatches = withClassificationAndConfirmation.filter(
    (o) => o.classification!.hypotheses[0]?.vegetationId === o.confirmation!.confirmedVegetationId,
  )
  const postIncidentMatches = withFeedback.filter(
    (o) => o.confirmation && o.feedback!.confirmedVegetationId === o.confirmation.confirmedVegetationId,
  )
  const accepted = withRecommendation.filter((o) => o.recommendation!.operatorAction === 'aceito')
  const underProvisioned = withFeedback.filter((o) => o.feedback!.adequacy === 'insuficiente')
  const overProvisioned = withFeedback.filter((o) => o.feedback!.adequacy === 'excessivo')

  const totalOccurrences = occurrences.length
  const totalWithFeedback = withFeedback.length

  return {
    totalOccurrences,
    totalWithFeedback,
    topHypothesisMatchRate: percent(topMatches.length, withClassificationAndConfirmation.length),
    postIncidentAccuracyRate: percent(postIncidentMatches.length, withFeedback.length),
    recommendationAcceptedRate: percent(accepted.length, withRecommendation.length),
    underProvisionedRate: percent(underProvisioned.length, withFeedback.length),
    overProvisionedRate: percent(overProvisioned.length, withFeedback.length),
    confidenceLabel:
      totalOccurrences === 0
        ? 'Nenhuma ocorrência registrada ainda — o modelo está usando apenas as premissas padrão.'
        : `Baseado em ${totalOccurrences} ocorrência${totalOccurrences === 1 ? '' : 's'} registrada${totalOccurrences === 1 ? '' : 's'}, ${totalWithFeedback} com feedback pós-incêndio.`,
  }
}
