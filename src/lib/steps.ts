export const SIMULATOR_STEPS = [
  { path: '/tipo-imovel', label: 'Imóvel' },
  { path: '/areas', label: 'Áreas' },
  { path: '/perguntas', label: 'Riscos' },
  { path: '/resultado', label: 'Resultado' },
] as const

export function stepProgress(pathname: string): { index: number; total: number; percent: number } {
  const total = SIMULATOR_STEPS.length
  const index = SIMULATOR_STEPS.findIndex((s) => pathname.startsWith(s.path))
  if (index === -1) return { index: 0, total, percent: 0 }
  const percent = ((index + 1) / total) * 100
  return { index, total, percent }
}
