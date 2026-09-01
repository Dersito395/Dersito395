export type PropertyTypeId =
  | 'apartamento'
  | 'casa_urbana'
  | 'casa_quintal'
  | 'sitio_rural'
  | 'comercio'
  | 'industria'

export type AreaId =
  | 'cozinha'
  | 'sala'
  | 'quarto'
  | 'garagem'
  | 'area_servico'
  | 'deposito'
  | 'area_externa_vegetacao'
  | 'sala_baterias'
  | 'quadro_eletrico'

export type FireClass = 'A' | 'B' | 'C' | 'D' | 'K' | 'LITIO'

export type ProductId =
  | 'detector_fumaca'
  | 'extintor_classe_l'
  | 'kit_incendio_florestal'
  | 'extintor_abc'
  | 'manta_incendio'
  | 'iluminacao_emergencia'
  | 'detector_gas'
  | 'kit_incendio_florestal_manual'
  | 'mangueira_incendio'

export type RiskLevel = 'baixo' | 'medio' | 'alto' | 'critico'

export interface PropertyType {
  id: PropertyTypeId
  label: string
  description: string
  icon: string
  /** Pontos de risco base já embutidos nesse tipo de imóvel (0-100 parcial) */
  baseRiskPoints: number
  /** Áreas sugeridas/pré-marcadas para esse tipo de imóvel */
  suggestedAreas: AreaId[]
}

export interface Area {
  id: AreaId
  label: string
  description: string
  icon: string
}

export interface AnswerOption {
  id: string
  label: string
  /** pontos de risco somados ao score da área (0-10 típico) */
  riskPoints: number
  fireClasses?: FireClass[]
  /** produtos do catálogo que essa resposta reforça, com peso de relevância */
  productBoost?: Partial<Record<ProductId, number>>
  /** marca se essa resposta indica que o usuário já tem proteção (reduz risco) */
  isProtective?: boolean
}

export interface Question {
  id: string
  areaId: AreaId | 'global'
  text: string
  helpText?: string
  multiple?: boolean
  options: AnswerOption[]
}

export interface Product {
  id: ProductId
  name: string
  tagline: string
  description: string
  image: string
  price: string
  specs: string[]
  appliesTo: string[]
  fireClasses: FireClass[]
  standardsNote: string
  idealFor: string[]
  /** 'per-area': sugere 1 unidade por cômodo/área que gerou a recomendação. 'fixed': item único para a propriedade toda. */
  quantityModel: 'per-area' | 'fixed'
}

export type AnswersMap = Record<string, string[]>
