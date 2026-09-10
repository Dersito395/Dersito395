import { useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Button } from '../components/Button'
import { Card, SectionTitle } from '../components/Card'
import { Field, Select, TextArea, TextInput } from '../components/Field'
import { Icon } from '../components/Icon'
import { RESOURCE_CATALOG } from '../data/resourcesConfig'
import { useOccurrenceStore } from '../store/occurrenceStore'
import type { OperatorAction, ResourceItem, ResourceUnit } from '../types/domain'

export function Recommendation() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const occurrence = useOccurrenceStore((s) => s.occurrences[id!])
  const config = useOccurrenceStore((s) => s.config)
  const setRecommendation = useOccurrenceStore((s) => s.setRecommendation)

  const level = occurrence?.riskCalculation?.level
  const suggested = level ? config.resourcePackages[level] : []

  const [action, setAction] = useState<OperatorAction>('aceito')
  const [quantities, setQuantities] = useState<Record<ResourceUnit, number>>(() => {
    const map: Record<string, number> = {}
    for (const r of RESOURCE_CATALOG) map[r.id] = 0
    for (const s of suggested) map[s.resourceId] = s.quantity
    return map as Record<ResourceUnit, number>
  })
  const [justification, setJustification] = useState('')

  const finalResources: ResourceItem[] = useMemo(
    () =>
      RESOURCE_CATALOG.filter((r) => quantities[r.id] > 0).map((r) => ({ resourceId: r.id, quantity: quantities[r.id] })),
    [quantities],
  )

  if (!occurrence?.riskCalculation || !level) return <p className="text-slate-400">Calcule o nível de risco antes de ver a recomendação.</p>

  function updateQuantity(resourceId: ResourceUnit, value: number) {
    setQuantities((prev) => ({ ...prev, [resourceId]: Math.max(0, value) }))
  }

  function handleActionChange(next: OperatorAction) {
    setAction(next)
    if (next === 'aceito') {
      const map: Record<string, number> = {}
      for (const r of RESOURCE_CATALOG) map[r.id] = 0
      for (const s of suggested) map[s.resourceId] = s.quantity
      setQuantities(map as Record<ResourceUnit, number>)
    } else if (next === 'substituido') {
      const map: Record<string, number> = {}
      for (const r of RESOURCE_CATALOG) map[r.id] = 0
      setQuantities(map as Record<ResourceUnit, number>)
    }
  }

  function handleSubmit() {
    setRecommendation(id!, {
      riskLevel: level!,
      suggestedResources: suggested,
      operatorAction: action,
      finalResources,
      justification: justification || undefined,
      decidedAt: new Date().toISOString(),
    })
    navigate(`/ocorrencias/${id}`)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Recomendação de recursos</h1>
        <p className="text-slate-400 text-sm mt-1">Etapa 5 de 6 — aceite, ajuste ou substitua. Toda decisão fica registrada.</p>
      </div>

      <Card>
        <SectionTitle>Pacote sugerido pela matriz de risco</SectionTitle>
        <ul className="space-y-2">
          {suggested.map((r) => {
            const resource = RESOURCE_CATALOG.find((c) => c.id === r.resourceId)!
            return (
              <li key={r.resourceId} className="flex items-center gap-2 text-sm text-slate-200">
                <Icon name={resource.icon} size={16} className="text-orange-400" />
                {r.quantity}x {resource.label}
              </li>
            )
          })}
        </ul>
      </Card>

      <Card>
        <SectionTitle>Decisão do operador</SectionTitle>
        <Field label="O que você quer fazer com a recomendação?">
          <Select value={action} onChange={(e) => handleActionChange(e.target.value as OperatorAction)}>
            <option value="aceito">Aceitar como está</option>
            <option value="ajustado">Ajustar quantidades</option>
            <option value="substituido">Substituir por outro pacote</option>
          </Select>
        </Field>

        {action !== 'aceito' && (
          <div className="space-y-3">
            {RESOURCE_CATALOG.map((r) => (
              <div key={r.id} className="flex items-center justify-between gap-3">
                <span className="text-sm text-slate-300 flex items-center gap-2">
                  <Icon name={r.icon} size={16} className="text-slate-500" /> {r.label}
                </span>
                <TextInput
                  type="number"
                  min={0}
                  className="w-20 text-center"
                  value={quantities[r.id]}
                  onChange={(e) => updateQuantity(r.id, Number(e.target.value))}
                />
              </div>
            ))}
            <Field label="Justificativa" help="Obrigatória ao ajustar ou substituir — alimenta o loop de aprendizado.">
              <TextArea value={justification} onChange={(e) => setJustification(e.target.value)} placeholder="Por que este pacote é mais adequado..." />
            </Field>
          </div>
        )}
      </Card>

      <Button onClick={handleSubmit} disabled={action !== 'aceito' && !justification}>
        Confirmar e registrar acionamento
      </Button>
    </div>
  )
}
