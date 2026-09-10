import { useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Button } from '../components/Button'
import { Card, SectionTitle } from '../components/Card'
import { Field, Select } from '../components/Field'
import { ProbabilityBar } from '../components/ProbabilityBar'
import { classifySmoke } from '../engine/smokeClassifier'
import { useOccurrenceStore } from '../store/occurrenceStore'
import type { SmokeColor, SmokeDensity } from '../types/domain'

const COLOR_OPTIONS: { value: SmokeColor; label: string }[] = [
  { value: 'branca_clara', label: 'Branca / clara' },
  { value: 'cinza_clara', label: 'Cinza clara' },
  { value: 'cinza_escura', label: 'Cinza escura' },
  { value: 'preta', label: 'Preta' },
]

const DENSITY_OPTIONS: { value: SmokeDensity; label: string }[] = [
  { value: 'baixa', label: 'Baixa' },
  { value: 'media', label: 'Média' },
  { value: 'alta', label: 'Alta' },
]

export function Classification() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const occurrence = useOccurrenceStore((s) => s.occurrences[id!])
  const vegetationTypes = useOccurrenceStore((s) => s.config.vegetationTypes)
  const setClassification = useOccurrenceStore((s) => s.setClassification)

  const [color, setColor] = useState<SmokeColor>('cinza_escura')
  const [density, setDensity] = useState<SmokeDensity>('media')

  const result = useMemo(
    () => classifySmoke({ color, density, soilHumidityPercent: occurrence?.focus.soilHumidityPercent ?? 0 }, vegetationTypes),
    [color, density, occurrence, vegetationTypes],
  )

  if (!occurrence) return <p className="text-slate-400">Ocorrência não encontrada.</p>

  function labelFor(vegId: string) {
    return vegetationTypes.find((v) => v.id === vegId)?.label ?? vegId
  }

  function handleSubmit() {
    setClassification(id!, result)
    navigate(`/ocorrencias/${id}/confirmacao`)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Classificação da fumaça</h1>
        <p className="text-slate-400 text-sm mt-1">
          Etapa 2 de 6 — análise heurística da imagem cruzada com a umidade do solo ({occurrence.focus.soilHumidityPercent}%).
        </p>
      </div>

      <Card>
        <SectionTitle>Padrão visual da fumaça</SectionTitle>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Cor predominante">
            <Select value={color} onChange={(e) => setColor(e.target.value as SmokeColor)}>
              {COLOR_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Densidade">
            <Select value={density} onChange={(e) => setDensity(e.target.value as SmokeDensity)}>
              {DENSITY_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </Select>
          </Field>
        </div>
      </Card>

      <Card>
        <SectionTitle>Hipóteses de vegetação/material (não é uma afirmação categórica)</SectionTitle>
        {result.hypotheses.map((h, i) => (
          <ProbabilityBar key={h.vegetationId} label={labelFor(h.vegetationId)} percent={h.probabilityPercent} rank={i} />
        ))}
        <p className="text-xs text-slate-500 mt-2">
          Modelo heurístico do MVP. O operador confirma ou corrige na próxima etapa — essa correção retroalimenta o loop de aprendizado.
        </p>
      </Card>

      <Button onClick={handleSubmit}>Avançar para confirmação do operador</Button>
    </div>
  )
}
