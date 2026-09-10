import type { ResourceItem, ResourceType, RiskLevel } from '../types/domain'

export const RESOURCE_CATALOG: ResourceType[] = [
  { id: 'equipe', label: 'Equipe leve com kit de combate', icon: 'Users' },
  { id: 'caminhao_pipa', label: 'Caminhão-pipa', icon: 'Truck' },
  { id: 'maquina_aceiro', label: 'Máquina para aceiro', icon: 'Tractor' },
  { id: 'aeronave', label: 'Aeronave de combate', icon: 'Plane' },
]

export const RISK_LEVEL_LABELS: Record<RiskLevel, string> = {
  baixo: 'Baixo',
  medio_1: 'Médio I',
  alto_1: 'Alto I',
  alto_2: 'Alto II',
  altissimo: 'Altíssimo',
}

export const RISK_LEVEL_CRITERIA: Record<RiskLevel, string> = {
  baixo: 'Foco distante da área de risco, vegetação de queima lenta, sem tendência de avanço.',
  medio_1: 'Foco se aproximando da área de risco, propagação moderada.',
  alto_1: 'Foco dentro da área de risco, propagação moderada/rápida.',
  alto_2: 'Foco dentro da área de risco, propagação rápida ou extensão relevante.',
  altissimo: 'Foco dentro da área de risco, propagação muito rápida, grande extensão ou múltiplos focos.',
}

/** Pacote padrão de recursos por nível de risco — configurável pela empresa. */
export const DEFAULT_RESOURCE_PACKAGES: Record<RiskLevel, ResourceItem[]> = {
  baixo: [{ resourceId: 'equipe', quantity: 1 }],
  medio_1: [{ resourceId: 'equipe', quantity: 2 }],
  alto_1: [
    { resourceId: 'equipe', quantity: 3 },
    { resourceId: 'caminhao_pipa', quantity: 1 },
  ],
  alto_2: [
    { resourceId: 'equipe', quantity: 3 },
    { resourceId: 'caminhao_pipa', quantity: 2 },
    { resourceId: 'aeronave', quantity: 1 },
  ],
  altissimo: [
    { resourceId: 'equipe', quantity: 5 },
    { resourceId: 'caminhao_pipa', quantity: 2 },
    { resourceId: 'aeronave', quantity: 1 },
    { resourceId: 'maquina_aceiro', quantity: 1 },
  ],
}
