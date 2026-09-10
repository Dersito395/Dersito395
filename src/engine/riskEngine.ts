import type { RiskMatrixConfig } from '../data/riskMatrixConfig'
import type { OperatorConfirmation, RiskCalculation, RiskLevel, VegetationType } from '../types/domain'

const SPEED_LABEL: Record<VegetationType['propagationSpeedClass'], string> = {
  lenta: 'lenta',
  moderada: 'moderada',
  rapida: 'rápida',
  muito_rapida: 'muito rápida',
}

/**
 * Lógica de cálculo de risco (Etapa 4). Cruza vegetação confirmada,
 * velocidade de propagação, distância/tempo estimado até a área de risco e
 * se o foco já está dentro dela. Todos os limiares usados vêm de
 * `RiskMatrixConfig`, configurável pela empresa — a função em si nunca tem
 * números "mágicos" embutidos, para que a régua de decisão fique auditável.
 */
export function calculateRisk(
  confirmation: OperatorConfirmation,
  vegetation: VegetationType,
  config: RiskMatrixConfig,
): RiskCalculation {
  const minutesPerKm = confirmation.propagationOverrideMinutesPerKm ?? vegetation.avgMinutesPerKm
  const estimatedMinutesToReach = confirmation.insideRiskArea ? null : confirmation.distanceKm * minutesPerKm

  const rationale: string[] = [
    `Vegetação confirmada: ${vegetation.label} (propagação ${SPEED_LABEL[vegetation.propagationSpeedClass]}, ~${minutesPerKm} min/km).`,
  ]

  let level: RiskLevel

  if (confirmation.insideRiskArea) {
    rationale.push(`Foco já está dentro da área de risco${confirmation.riskAreaId ? ` (${confirmation.riskAreaId})` : ''}.`)
    rationale.push(`Extensão estimada: ${confirmation.extentHectares} ha${confirmation.multipleFoci ? ', múltiplos focos ativos' : ''}.`)

    if (
      confirmation.multipleFoci ||
      vegetation.propagationSpeedClass === 'muito_rapida' ||
      confirmation.extentHectares >= config.altissimoExtentHectares
    ) {
      level = 'altissimo'
      rationale.push(
        confirmation.multipleFoci
          ? 'Múltiplos focos ativos → escalado para Altíssimo.'
          : vegetation.propagationSpeedClass === 'muito_rapida'
            ? 'Propagação muito rápida → escalado para Altíssimo.'
            : `Extensão ≥ ${config.altissimoExtentHectares} ha → escalado para Altíssimo.`,
      )
    } else if (vegetation.propagationSpeedClass === 'rapida' || confirmation.extentHectares >= config.alto2ExtentHectares) {
      level = 'alto_2'
      rationale.push(
        vegetation.propagationSpeedClass === 'rapida'
          ? 'Propagação rápida dentro da área de risco → Alto II.'
          : `Extensão ≥ ${config.alto2ExtentHectares} ha → Alto II.`,
      )
    } else {
      level = 'alto_1'
      rationale.push('Foco dentro da área de risco com propagação moderada/lenta e sem outros fatores de escalada → Alto I (mínimo de resposta para foco já dentro da área).')
    }
  } else {
    rationale.push(
      `Foco fora da área de risco. Distância: ${confirmation.distanceKm} km → tempo estimado até atingir a área: ${Math.round(estimatedMinutesToReach ?? 0)} min.`,
    )

    if ((estimatedMinutesToReach ?? Infinity) <= config.approachWindowMinutes) {
      level = 'medio_1'
      rationale.push(`Tempo estimado ≤ ${config.approachWindowMinutes} min → foco classificado como "se aproximando" (Médio I).`)
    } else {
      level = 'baixo'
      rationale.push(`Tempo estimado > ${config.approachWindowMinutes} min e sem tendência imediata de avanço → Baixo.`)
    }
  }

  return { level, rationale, estimatedMinutesToReach, calculatedAt: new Date().toISOString() }
}
