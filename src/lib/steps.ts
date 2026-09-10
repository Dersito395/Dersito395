export const OCCURRENCE_STEPS = [
  { suffix: '/novo', label: 'Foco' },
  { suffix: '/classificacao', label: 'Fumaça' },
  { suffix: '/confirmacao', label: 'Confirmação' },
  { suffix: '/risco', label: 'Risco' },
  { suffix: '/recomendacao', label: 'Recursos' },
] as const

export function stepProgress(pathname: string): { index: number; total: number; percent: number } | null {
  const total = OCCURRENCE_STEPS.length
  const index = OCCURRENCE_STEPS.findIndex((s) => pathname.endsWith(s.suffix))
  if (index === -1) return null
  const percent = ((index + 1) / total) * 100
  return { index, total, percent }
}
