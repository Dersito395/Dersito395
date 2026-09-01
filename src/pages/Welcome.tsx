import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Flame, ShieldCheck, Timer } from 'lucide-react'
import { Button } from '../components/Button'
import { track } from '../lib/analytics'
import { useSimulatorStore } from '../store/simulatorStore'

export function Welcome() {
  const navigate = useNavigate()
  const reset = useSimulatorStore((s) => s.reset)

  function start() {
    reset()
    track({ name: 'simulador_iniciado' })
    navigate('/tipo-imovel')
  }

  return (
    <div className="flex flex-col items-center text-center gap-6 pt-6">
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="w-24 h-24 rounded-full bg-orange-500/10 flex items-center justify-center"
      >
        <Flame size={48} className="text-orange-500" />
      </motion.div>

      <div>
        <h1 className="text-2xl font-extrabold leading-tight">
          Descubra em 2 minutos se sua casa está protegida contra incêndios
        </h1>
        <p className="mt-3 text-slate-400 text-sm leading-relaxed">
          Um simulador rápido e visual que avalia o risco de incêndio dos seus ambientes e recomenda
          exatamente o equipamento que você precisa — nada mais.
        </p>
      </div>

      <div className="w-full grid grid-cols-2 gap-3 text-left">
        <div className="bg-slate-900 rounded-xl p-3 flex flex-col gap-1 border border-slate-800">
          <Timer size={18} className="text-orange-400" />
          <span className="text-xs text-slate-400">Leva menos de 2 minutos</span>
        </div>
        <div className="bg-slate-900 rounded-xl p-3 flex flex-col gap-1 border border-slate-800">
          <ShieldCheck size={18} className="text-orange-400" />
          <span className="text-xs text-slate-400">Baseado nas normas do Corpo de Bombeiros de São Paulo</span>
        </div>
      </div>

      <Button onClick={start} className="mt-2">
        Começar simulação grátis
      </Button>

      <p className="text-[11px] text-slate-600 leading-relaxed">
        Ferramenta educativa e orientativa. Não substitui vistoria de bombeiros ou de um profissional
        habilitado, nem é um laudo técnico (AVCB).
      </p>
    </div>
  )
}
