import { useState } from 'react'
import { Button } from '../components/Button'
import { Card, SectionTitle } from '../components/Card'
import { Field, TextInput } from '../components/Field'
import { RESOURCE_CATALOG, RISK_LEVEL_LABELS } from '../data/resourcesConfig'
import { useOccurrenceStore, type AppConfig } from '../store/occurrenceStore'
import type { ResourceUnit, RiskLevel, VegetationId } from '../types/domain'

export function Settings() {
  const config = useOccurrenceStore((s) => s.config)
  const updateConfig = useOccurrenceStore((s) => s.updateConfig)
  const resetConfig = useOccurrenceStore((s) => s.resetConfig)

  const [draft, setDraft] = useState<AppConfig>(config)
  const [saved, setSaved] = useState(false)

  function updateMinutesPerKm(id: VegetationId, minutes: number) {
    setDraft((prev) => ({
      ...prev,
      vegetationTypes: prev.vegetationTypes.map((v) => (v.id === id ? { ...v, avgMinutesPerKm: minutes } : v)),
    }))
    setSaved(false)
  }

  function updatePackageQuantity(level: RiskLevel, resourceId: ResourceUnit, quantity: number) {
    setDraft((prev) => {
      const current = prev.resourcePackages[level]
      const withoutResource = current.filter((r) => r.resourceId !== resourceId)
      const next = quantity > 0 ? [...withoutResource, { resourceId, quantity }] : withoutResource
      return { ...prev, resourcePackages: { ...prev.resourcePackages, [level]: next } }
    })
    setSaved(false)
  }

  function updateMatrixField(field: keyof AppConfig['riskMatrix'], value: number) {
    setDraft((prev) => ({ ...prev, riskMatrix: { ...prev.riskMatrix, [field]: value } }))
    setSaved(false)
  }

  function handleSave() {
    updateConfig(draft)
    setSaved(true)
  }

  function handleReset() {
    resetConfig()
    setDraft(useOccurrenceStore.getState().config)
    setSaved(true)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Configurações</h1>
        <p className="text-slate-400 text-sm mt-1">
          Matriz de risco e recursos, parametrizável por região, época do ano e disponibilidade de frota.
        </p>
      </div>

      <Card>
        <SectionTitle>Tempo de propagação por vegetação (min/km)</SectionTitle>
        <div className="space-y-3">
          {draft.vegetationTypes.map((v) => (
            <div key={v.id} className="flex items-center justify-between gap-3">
              <span className="text-sm text-slate-300">{v.label}</span>
              <TextInput
                type="number"
                className="w-24 text-center"
                value={v.avgMinutesPerKm}
                onChange={(e) => updateMinutesPerKm(v.id, Number(e.target.value))}
              />
            </div>
          ))}
        </div>
      </Card>

      <Card>
        <SectionTitle>Limiares da matriz de risco</SectionTitle>
        <Field label="Janela de aproximação (min)" help="Tempo estimado até atingir a área de risco a partir do qual o foco já é classificado como Médio I.">
          <TextInput type="number" value={draft.riskMatrix.approachWindowMinutes} onChange={(e) => updateMatrixField('approachWindowMinutes', Number(e.target.value))} />
        </Field>
        <Field label="Extensão para Alto II (ha)">
          <TextInput type="number" value={draft.riskMatrix.alto2ExtentHectares} onChange={(e) => updateMatrixField('alto2ExtentHectares', Number(e.target.value))} />
        </Field>
        <Field label="Extensão para Altíssimo (ha)">
          <TextInput type="number" value={draft.riskMatrix.altissimoExtentHectares} onChange={(e) => updateMatrixField('altissimoExtentHectares', Number(e.target.value))} />
        </Field>
      </Card>

      <Card>
        <SectionTitle>Pacotes de recursos por nível de risco</SectionTitle>
        <div className="space-y-5">
          {(Object.keys(draft.resourcePackages) as RiskLevel[]).map((level) => (
            <div key={level}>
              <p className="text-sm font-medium text-slate-200 mb-2">{RISK_LEVEL_LABELS[level]}</p>
              <div className="grid grid-cols-2 gap-2">
                {RESOURCE_CATALOG.map((r) => {
                  const item = draft.resourcePackages[level].find((i) => i.resourceId === r.id)
                  return (
                    <div key={r.id} className="flex items-center justify-between gap-2 text-xs">
                      <span className="text-slate-400">{r.label}</span>
                      <TextInput
                        type="number"
                        min={0}
                        className="w-16 text-center py-1"
                        value={item?.quantity ?? 0}
                        onChange={(e) => updatePackageQuantity(level, r.id, Number(e.target.value))}
                      />
                    </div>
                  )
                })}
              </div>
            </div>
          ))}
        </div>
      </Card>

      <div className="flex gap-3">
        <Button onClick={handleSave}>{saved ? 'Salvo ✓' : 'Salvar configurações'}</Button>
        <Button variant="secondary" onClick={handleReset}>
          Restaurar padrão
        </Button>
      </div>
    </div>
  )
}
