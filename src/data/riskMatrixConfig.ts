/**
 * Pontos de configuração da lógica de risco. Todos os valores abaixo são
 * ajustáveis pela empresa na tela de Configurações (distância, tempo de
 * propagação, tamanho de equipe e disponibilidade de frota variam por
 * região e por época do ano — seca x chuvosa).
 */
export interface RiskMatrixConfig {
  /** Se o tempo estimado para o fogo atingir a área de risco for <= este valor, já é Médio I em vez de Baixo. */
  approachWindowMinutes: number
  /** Extensão (ha) a partir da qual um foco dentro da área de risco escala de Alto I para Alto II. */
  alto2ExtentHectares: number
  /** Extensão (ha) a partir da qual um foco dentro da área de risco escala para Altíssimo. */
  altissimoExtentHectares: number
}

export const DEFAULT_RISK_MATRIX_CONFIG: RiskMatrixConfig = {
  approachWindowMinutes: 120,
  alto2ExtentHectares: 5,
  altissimoExtentHectares: 20,
}
