import { Card, SectionTitle } from '../components/Card'
import { computeModelMetrics } from '../lib/metrics'
import { getOccurrenceList, useOccurrenceStore } from '../store/occurrenceStore'

function MetricRow({ label, value }: { label: string; value: number | null }) {
  return (
    <div className="flex items-center justify-between py-2 border-b border-slate-800 last:border-0">
      <span className="text-sm text-slate-300">{label}</span>
      <span className="text-sm font-semibold text-slate-100">{value === null ? '— sem dados' : `${value}%`}</span>
    </div>
  )
}

export function ModelDashboard() {
  const occurrences = useOccurrenceStore((s) => s.occurrences)
  const metrics = computeModelMetrics(getOccurrenceList(occurrences))

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Painel do modelo</h1>
        <p className="text-slate-400 text-sm mt-1">
          Indicadores do loop de aprendizado — o app é uma ferramenta em evolução, não uma verdade absoluta.
        </p>
      </div>

      <Card className="border-orange-900/50 bg-orange-950/20">
        <p className="text-sm text-orange-200">{metrics.confidenceLabel}</p>
      </Card>

      <Card>
        <SectionTitle>Acurácia da classificação de vegetação</SectionTitle>
        <MetricRow label="Hipótese principal ≡ confirmação em campo" value={metrics.topHypothesisMatchRate} />
        <MetricRow label="Confirmação em campo ≡ resultado real pós-incêndio" value={metrics.postIncidentAccuracyRate} />
      </Card>

      <Card>
        <SectionTitle>Adequação das recomendações</SectionTitle>
        <MetricRow label="Recomendações aceitas sem alteração" value={metrics.recommendationAcceptedRate} />
        <MetricRow label="Ocorrências com recursos insuficientes" value={metrics.underProvisionedRate} />
        <MetricRow label="Ocorrências com recursos ociosos" value={metrics.overProvisionedRate} />
      </Card>

      <p className="text-xs text-slate-500">
        Estes indicadores alimentam a recalibração periódica do classificador de fumaça, da estimativa de tempo de
        propagação e da matriz de risco × recursos (ver Configurações).
      </p>
    </div>
  )
}
