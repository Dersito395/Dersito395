import { Link } from 'react-router-dom'
import { AlertTriangle, ClipboardList, Plus } from 'lucide-react'
import { Button } from '../components/Button'
import { Card } from '../components/Card'
import { computeModelMetrics } from '../lib/metrics'
import { RISK_LEVEL_LABELS } from '../data/resourcesConfig'
import { RISK_LEVEL_STYLES } from '../lib/riskLevel'
import { getOccurrenceList, useOccurrenceStore } from '../store/occurrenceStore'

const STATUS_LABEL: Record<string, string> = {
  rascunho: 'Em preenchimento',
  em_andamento: 'Em andamento',
  concluida: 'Concluída',
}

export function Home() {
  const occurrences = useOccurrenceStore((s) => s.occurrences)
  const list = getOccurrenceList(occurrences)
  const metrics = computeModelMetrics(list)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Painel de ocorrências</h1>
        <p className="text-slate-400 text-sm mt-1">Copiloto de decisão para focos de incêndio florestal.</p>
      </div>

      <Card className="flex items-start gap-3 border-orange-900/50 bg-orange-950/20">
        <AlertTriangle className="text-orange-400 shrink-0 mt-0.5" size={18} />
        <p className="text-sm text-orange-200">{metrics.confidenceLabel} Toda recomendação é uma sugestão — a decisão final é sempre do operador.</p>
      </Card>

      <Link to="/novo">
        <Button className="flex items-center justify-center gap-2">
          <Plus size={18} /> Registrar novo foco
        </Button>
      </Link>

      <div>
        <div className="flex items-center gap-2 mb-3">
          <ClipboardList size={16} className="text-slate-500" />
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">Ocorrências</h2>
        </div>

        {list.length === 0 ? (
          <Card className="text-center text-slate-500 text-sm">Nenhuma ocorrência registrada ainda.</Card>
        ) : (
          <div className="space-y-3">
            {list.map((o) => {
              const level = o.riskCalculation?.level
              return (
                <Link key={o.id} to={`/ocorrencias/${o.id}`}>
                  <Card className="flex items-center justify-between hover:border-slate-700 transition-colors">
                    <div>
                      <p className="text-sm font-medium">
                        Foco {new Date(o.focus.detectedAt).toLocaleString('pt-BR')}
                      </p>
                      <p className="text-xs text-slate-500 mt-0.5">{STATUS_LABEL[o.status]}</p>
                    </div>
                    {level && (
                      <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${RISK_LEVEL_STYLES[level].bg} ${RISK_LEVEL_STYLES[level].text}`}>
                        {RISK_LEVEL_LABELS[level]}
                      </span>
                    )}
                  </Card>
                </Link>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
