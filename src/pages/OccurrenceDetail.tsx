import { Link, useParams } from 'react-router-dom'
import { Button } from '../components/Button'
import { Card, SectionTitle } from '../components/Card'
import { Icon } from '../components/Icon'
import { RESOURCE_CATALOG, RISK_LEVEL_LABELS } from '../data/resourcesConfig'
import { RISK_LEVEL_STYLES } from '../lib/riskLevel'
import { useOccurrenceStore } from '../store/occurrenceStore'

const ADEQUACY_LABEL: Record<string, string> = {
  insuficiente: 'Recursos insuficientes',
  adequado: 'Recursos adequados',
  excessivo: 'Recursos ociosos',
}

export function OccurrenceDetail() {
  const { id } = useParams<{ id: string }>()
  const occurrence = useOccurrenceStore((s) => s.occurrences[id!])
  const config = useOccurrenceStore((s) => s.config)

  if (!occurrence) return <p className="text-slate-400">Ocorrência não encontrada.</p>

  const { focus, classification, confirmation, riskCalculation, recommendation, feedback } = occurrence
  const vegetation = config.vegetationTypes.find((v) => v.id === confirmation?.confirmedVegetationId)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Registro da ocorrência</h1>
        <p className="text-slate-400 text-sm mt-1">Etapa 6 — trilha auditável completa desta ocorrência.</p>
      </div>

      <Card>
        <SectionTitle>Foco</SectionTitle>
        <dl className="text-sm space-y-1 text-slate-300">
          <div className="flex justify-between"><dt className="text-slate-500">Origem</dt><dd>{focus.source === 'manual' ? 'Manual' : 'API de monitoramento'}</dd></div>
          <div className="flex justify-between"><dt className="text-slate-500">Detectado em</dt><dd>{new Date(focus.detectedAt).toLocaleString('pt-BR')}</dd></div>
          {focus.coordinates && (
            <div className="flex justify-between"><dt className="text-slate-500">Coordenadas</dt><dd>{focus.coordinates.lat}, {focus.coordinates.lng}</dd></div>
          )}
          <div className="flex justify-between"><dt className="text-slate-500">Umidade do solo</dt><dd>{focus.soilHumidityPercent}%</dd></div>
        </dl>
      </Card>

      {classification && (
        <Card>
          <SectionTitle>Classificação da fumaça</SectionTitle>
          <ul className="text-sm text-slate-300 space-y-1">
            {classification.hypotheses.map((h) => (
              <li key={h.vegetationId} className="flex justify-between">
                <span>{config.vegetationTypes.find((v) => v.id === h.vegetationId)?.label}</span>
                <span className="text-slate-500">{h.probabilityPercent.toFixed(1)}%</span>
              </li>
            ))}
          </ul>
        </Card>
      )}

      {confirmation && vegetation && (
        <Card>
          <SectionTitle>Confirmação do operador</SectionTitle>
          <dl className="text-sm space-y-1 text-slate-300">
            <div className="flex justify-between"><dt className="text-slate-500">Vegetação confirmada</dt><dd>{vegetation.label}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Bateu com a hipótese principal?</dt><dd>{confirmation.matchedTopHypothesis ? 'Sim' : 'Não — corrigida'}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Dentro da área de risco?</dt><dd>{confirmation.insideRiskArea ? 'Sim' : 'Não'}</dd></div>
            {!confirmation.insideRiskArea && <div className="flex justify-between"><dt className="text-slate-500">Distância</dt><dd>{confirmation.distanceKm} km</dd></div>}
            {confirmation.insideRiskArea && <div className="flex justify-between"><dt className="text-slate-500">Extensão</dt><dd>{confirmation.extentHectares} ha</dd></div>}
          </dl>
        </Card>
      )}

      {riskCalculation && (
        <Card className={`${RISK_LEVEL_STYLES[riskCalculation.level].bg} border-transparent`}>
          <SectionTitle>Nível de risco</SectionTitle>
          <p className={`text-xl font-bold ${RISK_LEVEL_STYLES[riskCalculation.level].text}`}>{RISK_LEVEL_LABELS[riskCalculation.level]}</p>
          <ul className="mt-2 text-sm text-slate-300 list-disc list-inside space-y-1">
            {riskCalculation.rationale.map((r, i) => <li key={i}>{r}</li>)}
          </ul>
        </Card>
      )}

      {recommendation && (
        <Card>
          <SectionTitle>Recomendação e decisão</SectionTitle>
          <p className="text-sm text-slate-400 mb-2">
            Decisão do operador: <span className="text-slate-200 font-medium">{recommendation.operatorAction}</span>
          </p>
          <ul className="space-y-1.5">
            {recommendation.finalResources.map((r) => {
              const resource = RESOURCE_CATALOG.find((c) => c.id === r.resourceId)!
              return (
                <li key={r.resourceId} className="flex items-center gap-2 text-sm text-slate-200">
                  <Icon name={resource.icon} size={15} className="text-orange-400" /> {r.quantity}x {resource.label}
                </li>
              )
            })}
          </ul>
          {recommendation.justification && <p className="text-xs text-slate-500 mt-2">Justificativa: {recommendation.justification}</p>}
        </Card>
      )}

      {feedback ? (
        <Card>
          <SectionTitle>Feedback pós-incêndio</SectionTitle>
          <dl className="text-sm space-y-1 text-slate-300">
            <div className="flex justify-between"><dt className="text-slate-500">Vegetação real confirmada</dt><dd>{config.vegetationTypes.find((v) => v.id === feedback.confirmedVegetationId)?.label}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Área queimada</dt><dd>{feedback.areaBurnedHectares} ha</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Tempo de controle</dt><dd>{feedback.controlTimeMinutes} min</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Adequação dos recursos</dt><dd>{ADEQUACY_LABEL[feedback.adequacy]}</dd></div>
          </dl>
        </Card>
      ) : recommendation ? (
        <Link to={`/ocorrencias/${id}/feedback`}>
          <Button variant="secondary">Registrar feedback pós-incêndio</Button>
        </Link>
      ) : null}
    </div>
  )
}
