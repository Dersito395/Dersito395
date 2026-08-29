import type { RiskLevel } from '../types/domain'

export const levelColors: Record<RiskLevel, { ring: string; text: string; bg: string; label: string }> = {
  baixo: { ring: '#22c55e', text: 'text-green-400', bg: 'bg-green-500/10', label: 'Risco baixo' },
  medio: { ring: '#eab308', text: 'text-yellow-400', bg: 'bg-yellow-500/10', label: 'Risco médio' },
  alto: { ring: '#f97316', text: 'text-orange-400', bg: 'bg-orange-500/10', label: 'Risco alto' },
  critico: { ring: '#ef4444', text: 'text-red-400', bg: 'bg-red-500/10', label: 'Risco crítico' },
}

export function levelMeta(level: RiskLevel) {
  return levelColors[level]
}
