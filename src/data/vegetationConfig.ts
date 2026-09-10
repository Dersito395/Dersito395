import type { VegetationType } from '../types/domain'

/**
 * Vegetação/material em combustão. Velocidade de propagação e assinatura de
 * fumaça são parametrizáveis pela empresa (região, época seca x chuvosa).
 */
export const DEFAULT_VEGETATION_TYPES: VegetationType[] = [
  {
    id: 'cana_de_acucar',
    label: 'Cana-de-açúcar',
    description: 'Queima muito rápida, alta liberação de fumaça escura e densa.',
    propagationSpeedClass: 'muito_rapida',
    avgMinutesPerKm: 4,
    smokeSignature: {
      color: { branca_clara: 0.05, cinza_clara: 0.15, cinza_escura: 0.55, preta: 0.9 },
      density: { baixa: 0.1, media: 0.4, alta: 0.85 },
      humidityEffect: 'baixa_favorece',
    },
  },
  {
    id: 'eucalipto_seco',
    label: 'Eucalipto (seco)',
    description: 'Propagação rápida em período de estiagem, fumaça escura e densa.',
    propagationSpeedClass: 'rapida',
    avgMinutesPerKm: 7,
    smokeSignature: {
      color: { branca_clara: 0.05, cinza_clara: 0.25, cinza_escura: 0.7, preta: 0.6 },
      density: { baixa: 0.15, media: 0.5, alta: 0.75 },
      humidityEffect: 'baixa_favorece',
    },
  },
  {
    id: 'eucalipto_umido',
    label: 'Eucalipto (úmido/normal)',
    description: 'Propagação mais lenta, fumaça mais clara e menos densa.',
    propagationSpeedClass: 'moderada',
    avgMinutesPerKm: 14,
    smokeSignature: {
      color: { branca_clara: 0.35, cinza_clara: 0.6, cinza_escura: 0.35, preta: 0.1 },
      density: { baixa: 0.5, media: 0.5, alta: 0.2 },
      humidityEffect: 'alta_favorece',
    },
  },
  {
    id: 'nativa_pastagem',
    label: 'Vegetação nativa / pastagem',
    description: 'Comportamento variável; com solo úmido tende a fumaça clara e propagação lenta.',
    propagationSpeedClass: 'lenta',
    avgMinutesPerKm: 20,
    smokeSignature: {
      color: { branca_clara: 0.85, cinza_clara: 0.5, cinza_escura: 0.15, preta: 0.05 },
      density: { baixa: 0.7, media: 0.35, alta: 0.1 },
      humidityEffect: 'alta_favorece',
    },
  },
  {
    id: 'material_industrial',
    label: 'Material industrial (fábrica/carvoaria)',
    description: 'Fumaça muito escura e densa mesmo com solo úmido — indício de fonte não vegetal.',
    propagationSpeedClass: 'moderada',
    avgMinutesPerKm: 999, // não se propaga como vegetação — sinaliza para investigação, não para a matriz de risco florestal
    smokeSignature: {
      color: { branca_clara: 0.02, cinza_clara: 0.1, cinza_escura: 0.4, preta: 0.85 },
      density: { baixa: 0.05, media: 0.3, alta: 0.9 },
      humidityEffect: 'neutro',
    },
  },
]
