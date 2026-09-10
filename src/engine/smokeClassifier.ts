import type { SmokeClassificationInput, SmokeClassificationResult, SmokeHypothesis, VegetationType } from '../types/domain'

/**
 * Módulo de classificação de imagem/fumaça (MVP heurístico).
 *
 * Entradas: cor e densidade predominantes da fumaça (hoje informadas pelo
 * operador a partir da foto/vídeo do foco; numa integração real seriam a
 * saída de um modelo de visão computacional) + umidade do solo da região.
 *
 * Saída: 2-3 hipóteses de vegetação/material, cada uma com um percentual de
 * confiança — nunca uma afirmação categórica única. Os percentuais vêm de
 * uma pontuação por afinidade (cor, densidade, efeito da umidade) normalizada
 * para somar 100%. Este é o ponto de recalibração do loop de aprendizado
 * (seção 5 da especificação): as afinidades por vegetação evoluem com o
 * histórico de confirmações e feedback pós-ocorrência.
 */
export function classifySmoke(
  input: SmokeClassificationInput,
  vegetationTypes: VegetationType[],
): SmokeClassificationResult {
  const humidityFactor = input.soilHumidityPercent / 100

  const scores = vegetationTypes.map((veg) => {
    const colorScore = veg.smokeSignature.color[input.color] ?? 0
    const densityScore = veg.smokeSignature.density[input.density] ?? 0

    let humidityScore = 0.5
    if (veg.smokeSignature.humidityEffect === 'alta_favorece') humidityScore = humidityFactor
    if (veg.smokeSignature.humidityEffect === 'baixa_favorece') humidityScore = 1 - humidityFactor

    const combined = colorScore * 0.45 + densityScore * 0.35 + humidityScore * 0.2
    return { vegetationId: veg.id, score: Math.max(combined, 0.001) }
  })

  const total = scores.reduce((sum, s) => sum + s.score, 0)
  const hypotheses: SmokeHypothesis[] = scores
    .map((s) => ({ vegetationId: s.vegetationId, probabilityPercent: Math.round((s.score / total) * 1000) / 10 }))
    .sort((a, b) => b.probabilityPercent - a.probabilityPercent)
    .slice(0, 3)

  return { input, hypotheses, generatedAt: new Date().toISOString() }
}
