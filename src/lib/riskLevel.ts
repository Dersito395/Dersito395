import type { RiskLevel } from '../types/domain'

export const RISK_LEVEL_STYLES: Record<RiskLevel, { bg: string; text: string; ring: string }> = {
  baixo: { bg: 'bg-emerald-500/15', text: 'text-emerald-400', ring: '#34d399' },
  medio_1: { bg: 'bg-yellow-500/15', text: 'text-yellow-400', ring: '#facc15' },
  alto_1: { bg: 'bg-orange-500/15', text: 'text-orange-400', ring: '#fb923c' },
  alto_2: { bg: 'bg-red-500/15', text: 'text-red-400', ring: '#f87171' },
  altissimo: { bg: 'bg-fuchsia-600/20', text: 'text-fuchsia-400', ring: '#e879f9' },
}
