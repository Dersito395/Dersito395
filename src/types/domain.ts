// Modelo de dados — entidades do copiloto de decisão para combate a incêndios florestais.
// Ocorrência, Foco, Vegetação, Área de Risco, Recurso, Recomendação, Feedback.

export type VegetationId =
  | 'cana_de_acucar'
  | 'eucalipto_seco'
  | 'eucalipto_umido'
  | 'nativa_pastagem'
  | 'material_industrial'

export type PropagationSpeedClass = 'lenta' | 'moderada' | 'rapida' | 'muito_rapida'

/** Vegetação/material em combustão — parametrizável pela empresa. */
export interface VegetationType {
  id: VegetationId
  label: string
  description: string
  propagationSpeedClass: PropagationSpeedClass
  /** Tempo médio de propagação, em minutos por km, até atingir uma área de risco. Parametrizável. */
  avgMinutesPerKm: number
  /** Afinidade da assinatura de fumaça (0-1) usada pelo classificador heurístico. */
  smokeSignature: {
    color: Record<SmokeColor, number>
    density: Record<SmokeDensity, number>
    /** Direção do efeito da umidade do solo: 'alta_favorece' = mais úmido aumenta a chance; 'baixa_favorece' = mais seco aumenta a chance. */
    humidityEffect: 'alta_favorece' | 'baixa_favorece' | 'neutro'
  }
}

export type SmokeColor = 'branca_clara' | 'cinza_clara' | 'cinza_escura' | 'preta'
export type SmokeDensity = 'baixa' | 'media' | 'alta'

export type FocusSource = 'api_monitoramento' | 'manual'

/** Foco — o alerta bruto de fumaça, vindo da API de monitoramento ou inserido manualmente. */
export interface Focus {
  id: string
  source: FocusSource
  detectedAt: string
  coordinates?: { lat: number; lng: number }
  soilHumidityPercent: number
  mediaNote?: string
}

export type RiskAreaKind = 'eucalipto' | 'nativa' | 'outra'

/** Área de risco — plantios/áreas nativas georreferenciadas da empresa. */
export interface RiskArea {
  id: string
  name: string
  kind: RiskAreaKind
  notes?: string
}

/** Uma das 2-3 hipóteses geradas pelo módulo de classificação de imagem/fumaça. */
export interface SmokeHypothesis {
  vegetationId: VegetationId
  probabilityPercent: number
}

export interface SmokeClassificationInput {
  color: SmokeColor
  density: SmokeDensity
  soilHumidityPercent: number
}

export interface SmokeClassificationResult {
  input: SmokeClassificationInput
  hypotheses: SmokeHypothesis[] // ordenado desc, sempre 2-3 hipóteses
  generatedAt: string
}

/** Confirmação/complementação manual do operador (Etapa 3). */
export interface OperatorConfirmation {
  confirmedVegetationId: VegetationId
  matchedTopHypothesis: boolean
  distanceKm: number
  insideRiskArea: boolean
  riskAreaId?: string
  multipleFoci: boolean
  extentHectares: number
  /** Override manual do tempo de propagação padrão da vegetação, se o operador tiver informação melhor. */
  propagationOverrideMinutesPerKm?: number
  confirmedAt: string
}

export type RiskLevel = 'baixo' | 'medio_1' | 'alto_1' | 'alto_2' | 'altissimo'

export interface RiskCalculation {
  level: RiskLevel
  rationale: string[]
  estimatedMinutesToReach: number | null
  calculatedAt: string
}

export type ResourceUnit = 'equipe' | 'caminhao_pipa' | 'aeronave' | 'maquina_aceiro'

/** Recurso — item do catálogo de recursos de combate. */
export interface ResourceType {
  id: ResourceUnit
  label: string
  icon: string
}

export interface ResourceItem {
  resourceId: ResourceUnit
  quantity: number
}

export type OperatorAction = 'aceito' | 'ajustado' | 'substituido'

/** Recomendação — pacote de recursos sugerido e a decisão final do operador. */
export interface Recommendation {
  riskLevel: RiskLevel
  suggestedResources: ResourceItem[]
  operatorAction: OperatorAction
  finalResources: ResourceItem[]
  justification?: string
  decidedAt: string
}

export type ResourceAdequacy = 'insuficiente' | 'adequado' | 'excessivo'

/** Feedback pós-ocorrência — retroalimenta o loop de aprendizado. */
export interface Feedback {
  confirmedVegetationId: VegetationId
  realMinutesPerKm?: number
  areaBurnedHectares: number
  resourcesActuallyUsed: ResourceItem[]
  adequacy: ResourceAdequacy
  controlTimeMinutes: number
  notes?: string
  registeredAt: string
}

export type OccurrenceStatus = 'rascunho' | 'em_andamento' | 'concluida'

/** Ocorrência — agregado raiz que amarra todo o histórico auditável do foco. */
export interface Occurrence {
  id: string
  status: OccurrenceStatus
  createdAt: string
  focus: Focus
  classification?: SmokeClassificationResult
  confirmation?: OperatorConfirmation
  riskCalculation?: RiskCalculation
  recommendation?: Recommendation
  feedback?: Feedback
}
