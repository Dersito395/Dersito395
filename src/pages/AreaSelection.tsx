import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { areas } from '../data/areas'
import { Icon } from '../components/Icon'
import { Button } from '../components/Button'
import { track } from '../lib/analytics'
import { useSimulatorStore } from '../store/simulatorStore'
import type { AreaId } from '../types/domain'

export function AreaSelection() {
  const navigate = useNavigate()
  const propertyTypeId = useSimulatorStore((s) => s.propertyTypeId)
  const selectedAreas = useSimulatorStore((s) => s.selectedAreas)
  const toggleArea = useSimulatorStore((s) => s.toggleArea)

  useEffect(() => {
    if (!propertyTypeId) navigate('/tipo-imovel', { replace: true })
  }, [propertyTypeId, navigate])

  function continueToQuestions() {
    track({ name: 'areas_selecionadas', areaIds: selectedAreas })
    navigate('/perguntas')
  }

  function toggle(id: AreaId) {
    toggleArea(id)
  }

  return (
    <div className="flex flex-col gap-5">
      <div>
        <h2 className="text-xl font-bold">Quais áreas você quer avaliar?</h2>
        <p className="text-sm text-slate-400 mt-1">
          Já sugerimos os ambientes mais comuns para o seu tipo de imóvel. Ajuste como quiser.
        </p>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {areas.map((area) => {
          const active = selectedAreas.includes(area.id)
          return (
            <button
              key={area.id}
              onClick={() => toggle(area.id)}
              className={`flex flex-col items-center gap-1.5 p-3 rounded-2xl border text-center transition-colors ${
                active
                  ? 'bg-orange-500/15 border-orange-500 text-orange-300'
                  : 'bg-slate-900 border-slate-800 text-slate-300 hover:border-slate-600'
              }`}
            >
              <Icon name={area.icon} size={22} />
              <span className="text-[11px] font-medium leading-tight">{area.label}</span>
            </button>
          )
        })}
      </div>

      <Button onClick={continueToQuestions} disabled={selectedAreas.length === 0}>
        Continuar ({selectedAreas.length} {selectedAreas.length === 1 ? 'área' : 'áreas'})
      </Button>
    </div>
  )
}
