import type { RiskArea } from '../types/domain'

export const DEFAULT_RISK_AREAS: RiskArea[] = [
  { id: 'talhao_eucalipto_norte', name: 'Talhão de eucalipto — Setor Norte', kind: 'eucalipto' },
  { id: 'talhao_eucalipto_sul', name: 'Talhão de eucalipto — Setor Sul', kind: 'eucalipto' },
  { id: 'reserva_nativa_leste', name: 'Reserva legal / área nativa — Setor Leste', kind: 'nativa' },
]
