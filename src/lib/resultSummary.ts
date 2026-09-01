import type { SimulationResult } from '../engine/riskEngine'
import { levelMeta } from './riskLevel'
import { COMPANY } from './contact'

export function buildResultSummaryText(propertyTypeLabel: string, result: SimulationResult): string {
  const lines: string[] = []
  lines.push('Check - Incêndios (Fire Command) — Resultado do simulador de risco de incêndio')
  lines.push('')
  lines.push(`Tipo de imóvel: ${propertyTypeLabel}`)
  lines.push(`Score geral de segurança: ${result.overallSafetyScore}/100 (${levelMeta(result.overallLevel).label})`)
  lines.push('')
  lines.push('Score por ambiente:')
  for (const area of result.areaResults) {
    lines.push(`- ${area.label}: ${area.safetyScore}/100 (${levelMeta(area.level).label})`)
  }
  lines.push('')
  lines.push('Equipamentos recomendados:')
  for (const { product, quantityNote } of result.recommendedProducts) {
    lines.push(`- ${product.name} (${product.price}) — ${quantityNote}`)
  }
  lines.push('')
  lines.push(
    'Este resultado é uma ferramenta educativa e orientativa, com base nas classes de incêndio e diretrizes ' +
      'gerais do Corpo de Bombeiros de São Paulo. Não substitui vistoria técnica nem laudo (AVCB).',
  )
  lines.push('')
  lines.push(`${COMPANY.name} — ${COMPANY.contact} — ${COMPANY.address}`)
  return lines.join('\n')
}
