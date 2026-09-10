import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Button } from '../components/Button'
import { Card, SectionTitle } from '../components/Card'
import { Field, Select, TextArea, TextInput } from '../components/Field'
import { RESOURCE_CATALOG } from '../data/resourcesConfig'
import { useOccurrenceStore } from '../store/occurrenceStore'
import type { ResourceAdequacy, ResourceUnit, VegetationId } from '../types/domain'

export function FeedbackForm() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const occurrence = useOccurrenceStore((s) => s.occurrences[id!])
  const config = useOccurrenceStore((s) => s.config)
  const setFeedback = useOccurrenceStore((s) => s.setFeedback)

  const [confirmedVegetationId, setConfirmedVegetationId] = useState<VegetationId>(
    occurrence?.confirmation?.confirmedVegetationId ?? config.vegetationTypes[0].id,
  )
  const [areaBurned, setAreaBurned] = useState('0')
  const [controlTime, setControlTime] = useState('60')
  const [adequacy, setAdequacy] = useState<ResourceAdequacy>('adequado')
  const [notes, setNotes] = useState('')
  const [usedQuantities, setUsedQuantities] = useState<Record<ResourceUnit, number>>(() => {
    const map: Record<string, number> = {}
    for (const r of RESOURCE_CATALOG) map[r.id] = 0
    for (const item of occurrence?.recommendation?.finalResources ?? []) map[item.resourceId] = item.quantity
    return map as Record<ResourceUnit, number>
  })

  if (!occurrence) return <p className="text-slate-400">Ocorrência não encontrada.</p>

  function handleSubmit() {
    setFeedback(id!, {
      confirmedVegetationId,
      areaBurnedHectares: Number(areaBurned),
      resourcesActuallyUsed: RESOURCE_CATALOG.filter((r) => usedQuantities[r.id] > 0).map((r) => ({
        resourceId: r.id,
        quantity: usedQuantities[r.id],
      })),
      adequacy,
      controlTimeMinutes: Number(controlTime),
      notes: notes || undefined,
      registeredAt: new Date().toISOString(),
    })
    navigate(`/ocorrencias/${id}`)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Feedback pós-incêndio</h1>
        <p className="text-slate-400 text-sm mt-1">
          Etapa 6 — o que realmente aconteceu. Esses dados recalibram o classificador de fumaça e a matriz de risco.
        </p>
      </div>

      <Card>
        <SectionTitle>O que foi confirmado no local</SectionTitle>
        <Field label="Vegetação/material real (confirmado após o incêndio)">
          <Select value={confirmedVegetationId} onChange={(e) => setConfirmedVegetationId(e.target.value as VegetationId)}>
            {config.vegetationTypes.map((v) => (
              <option key={v.id} value={v.id}>
                {v.label}
              </option>
            ))}
          </Select>
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Área queimada (ha)">
            <TextInput type="number" step="0.1" value={areaBurned} onChange={(e) => setAreaBurned(e.target.value)} />
          </Field>
          <Field label="Tempo de controle (min)">
            <TextInput type="number" value={controlTime} onChange={(e) => setControlTime(e.target.value)} />
          </Field>
        </div>
      </Card>

      <Card>
        <SectionTitle>Recursos efetivamente usados</SectionTitle>
        <div className="space-y-3">
          {RESOURCE_CATALOG.map((r) => (
            <div key={r.id} className="flex items-center justify-between gap-3">
              <span className="text-sm text-slate-300">{r.label}</span>
              <TextInput
                type="number"
                min={0}
                className="w-20 text-center"
                value={usedQuantities[r.id]}
                onChange={(e) => setUsedQuantities((prev) => ({ ...prev, [r.id]: Math.max(0, Number(e.target.value)) }))}
              />
            </div>
          ))}
        </div>
        <Field label="Os recursos recomendados foram suficientes?">
          <Select value={adequacy} onChange={(e) => setAdequacy(e.target.value as ResourceAdequacy)}>
            <option value="insuficiente">Insuficientes — precisou de mais</option>
            <option value="adequado">Adequados</option>
            <option value="excessivo">Excessivos — ficaram ociosos</option>
          </Select>
        </Field>
        <Field label="Observações">
          <TextArea value={notes} onChange={(e) => setNotes(e.target.value)} />
        </Field>
      </Card>

      <Button onClick={handleSubmit}>Concluir ocorrência</Button>
    </div>
  )
}
