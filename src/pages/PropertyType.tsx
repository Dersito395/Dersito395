import { useNavigate } from 'react-router-dom'
import { propertyTypes } from '../data/propertyTypes'
import { Icon } from '../components/Icon'
import { track } from '../lib/analytics'
import { useSimulatorStore } from '../store/simulatorStore'
import type { PropertyTypeId } from '../types/domain'

export function PropertyType() {
  const navigate = useNavigate()
  const setPropertyType = useSimulatorStore((s) => s.setPropertyType)
  const setAreas = useSimulatorStore((s) => s.setAreas)

  function choose(id: PropertyTypeId) {
    setPropertyType(id)
    const suggested = propertyTypes.find((p) => p.id === id)?.suggestedAreas ?? []
    setAreas(suggested)
    track({ name: 'tipo_imovel_selecionado', propertyTypeId: id })
    navigate('/areas')
  }

  return (
    <div className="flex flex-col gap-5">
      <div>
        <h2 className="text-xl font-bold">Qual o tipo do seu imóvel?</h2>
        <p className="text-sm text-slate-400 mt-1">Isso ajusta as perguntas para o seu contexto.</p>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {propertyTypes.map((pt) => (
          <button
            key={pt.id}
            onClick={() => choose(pt.id)}
            className="flex flex-col items-start gap-2 p-4 rounded-2xl bg-slate-900 border border-slate-800 hover:border-orange-500/60 hover:bg-slate-800/80 transition-colors text-left"
          >
            <div className="w-10 h-10 rounded-xl bg-orange-500/10 flex items-center justify-center">
              <Icon name={pt.icon} size={20} className="text-orange-400" />
            </div>
            <span className="font-semibold text-sm leading-tight">{pt.label}</span>
            <span className="text-xs text-slate-500 leading-snug">{pt.description}</span>
          </button>
        ))}
      </div>
    </div>
  )
}
