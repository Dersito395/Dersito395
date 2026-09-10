import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Button } from '../components/Button'
import { Card, SectionTitle } from '../components/Card'
import { Field, Select, TextInput } from '../components/Field'
import { useOccurrenceStore } from '../store/occurrenceStore'
import type { VegetationId } from '../types/domain'

export function Confirmation() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const occurrence = useOccurrenceStore((s) => s.occurrences[id!])
  const config = useOccurrenceStore((s) => s.config)
  const setConfirmation = useOccurrenceStore((s) => s.setConfirmation)

  const topHypothesis = occurrence?.classification?.hypotheses[0]?.vegetationId
  const [vegetationId, setVegetationId] = useState<VegetationId>(topHypothesis ?? config.vegetationTypes[0].id)
  const [distanceKm, setDistanceKm] = useState('1')
  const [insideRiskArea, setInsideRiskArea] = useState(false)
  const [riskAreaId, setRiskAreaId] = useState(config.riskAreas[0]?.id ?? '')
  const [multipleFoci, setMultipleFoci] = useState(false)
  const [extentHectares, setExtentHectares] = useState('0.5')
  const [overrideMinutes, setOverrideMinutes] = useState('')

  if (!occurrence) return <p className="text-slate-400">Ocorrência não encontrada.</p>

  const selectedVeg = config.vegetationTypes.find((v) => v.id === vegetationId)!

  function handleSubmit() {
    setConfirmation(id!, {
      confirmedVegetationId: vegetationId,
      matchedTopHypothesis: vegetationId === topHypothesis,
      distanceKm: Number(distanceKm),
      insideRiskArea,
      riskAreaId: insideRiskArea ? riskAreaId : undefined,
      multipleFoci,
      extentHectares: Number(extentHectares),
      propagationOverrideMinutesPerKm: overrideMinutes ? Number(overrideMinutes) : undefined,
      confirmedAt: new Date().toISOString(),
    })
    navigate(`/ocorrencias/${id}/risco`)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Confirmação do operador</h1>
        <p className="text-slate-400 text-sm mt-1">Etapa 3 de 6 — confirme ou corrija a vegetação e complete os dados de campo.</p>
      </div>

      <Card>
        <SectionTitle>Vegetação / material</SectionTitle>
        <Field label="Vegetação confirmada" help="Pré-selecionada com a hipótese de maior probabilidade. Corrigir aqui alimenta o loop de aprendizado.">
          <Select value={vegetationId} onChange={(e) => setVegetationId(e.target.value as VegetationId)}>
            {config.vegetationTypes.map((v) => (
              <option key={v.id} value={v.id}>
                {v.label}
              </option>
            ))}
          </Select>
        </Field>
        <p className="text-xs text-slate-500">
          Velocidade de propagação cadastrada: <span className="text-slate-300">{selectedVeg.propagationSpeedClass}</span> (~
          {selectedVeg.avgMinutesPerKm} min/km).
        </p>
        <Field label="Ajuste manual do tempo de propagação (min/km)" help="Opcional — use se tiver informação de campo melhor que o parâmetro padrão.">
          <TextInput type="number" placeholder={String(selectedVeg.avgMinutesPerKm)} value={overrideMinutes} onChange={(e) => setOverrideMinutes(e.target.value)} />
        </Field>
      </Card>

      <Card>
        <SectionTitle>Localização em relação à área de risco</SectionTitle>
        <Field label="O foco já está dentro de uma área de risco da empresa?">
          <Select value={insideRiskArea ? 'sim' : 'nao'} onChange={(e) => setInsideRiskArea(e.target.value === 'sim')}>
            <option value="nao">Não — ainda se aproximando</option>
            <option value="sim">Sim — já está dentro</option>
          </Select>
        </Field>
        {insideRiskArea ? (
          <>
            <Field label="Qual área de risco?">
              <Select value={riskAreaId} onChange={(e) => setRiskAreaId(e.target.value)}>
                {config.riskAreas.map((a) => (
                  <option key={a.id} value={a.id}>
                    {a.name}
                  </option>
                ))}
              </Select>
            </Field>
            <div className="grid grid-cols-2 gap-3">
              <Field label="Extensão estimada (ha)">
                <TextInput type="number" step="0.1" value={extentHectares} onChange={(e) => setExtentHectares(e.target.value)} />
              </Field>
              <Field label="Múltiplos focos ativos?">
                <Select value={multipleFoci ? 'sim' : 'nao'} onChange={(e) => setMultipleFoci(e.target.value === 'sim')}>
                  <option value="nao">Não</option>
                  <option value="sim">Sim</option>
                </Select>
              </Field>
            </div>
          </>
        ) : (
          <Field label="Distância até a área de risco (km)">
            <TextInput type="number" step="0.1" value={distanceKm} onChange={(e) => setDistanceKm(e.target.value)} />
          </Field>
        )}
      </Card>

      <Button onClick={handleSubmit}>Calcular nível de risco</Button>
    </div>
  )
}
