import { useEffect, useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Button } from '../components/Button'
import { Card, SectionTitle } from '../components/Card'
import { RISK_LEVEL_CRITERIA, RISK_LEVEL_LABELS } from '../data/resourcesConfig'
import { calculateRisk } from '../engine/riskEngine'
import { RISK_LEVEL_STYLES } from '../lib/riskLevel'
import { useOccurrenceStore } from '../store/occurrenceStore'

export function RiskResult() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const occurrence = useOccurrenceStore((s) => s.occurrences[id!])
  const config = useOccurrenceStore((s) => s.config)
  const setRiskCalculation = useOccurrenceStore((s) => s.setRiskCalculation)

  const vegetation = config.vegetationTypes.find((v) => v.id === occurrence?.confirmation?.confirmedVegetationId)

  const calc = useMemo(() => {
    if (!occurrence?.confirmation || !vegetation) return null
    return calculateRisk(occurrence.confirmation, vegetation, config.riskMatrix)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [occurrence?.confirmation, vegetation, config.riskMatrix])

  useEffect(() => {
    if (calc && !occurrence?.riskCalculation) setRiskCalculation(id!, calc)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  if (!occurrence?.confirmation || !vegetation || !calc) return <p className="text-slate-400">Confirme os dados do foco antes de calcular o risco.</p>

  const style = RISK_LEVEL_STYLES[calc.level]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Nível de risco</h1>
        <p className="text-slate-400 text-sm mt-1">Etapa 4 de 6 — cálculo com a régua de decisão visível.</p>
      </div>

      <Card className={`${style.bg} border-transparent text-center`}>
        <p className={`text-3xl font-extrabold ${style.text}`}>{RISK_LEVEL_LABELS[calc.level]}</p>
        <p className="text-sm text-slate-300 mt-2">{RISK_LEVEL_CRITERIA[calc.level]}</p>
      </Card>

      <Card>
        <SectionTitle>Por que o app chegou a essa recomendação</SectionTitle>
        <ul className="space-y-2 text-sm text-slate-300 list-disc list-inside">
          {calc.rationale.map((r, i) => (
            <li key={i}>{r}</li>
          ))}
        </ul>
      </Card>

      <Button onClick={() => navigate(`/ocorrencias/${id}/recomendacao`)}>Ver recursos recomendados</Button>
    </div>
  )
}
