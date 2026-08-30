import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ScanLine } from 'lucide-react'
import { track } from '../lib/analytics'
import { useSimulatorStore } from '../store/simulatorStore'

const messages = [
  'Analisando materiais inflamáveis...',
  'Verificando instalações elétricas...',
  'Cruzando com classes de incêndio (A, B, C, D, K)...',
  'Calculando score de segurança...',
]

export function Processing() {
  const navigate = useNavigate()
  const propertyTypeId = useSimulatorStore((s) => s.propertyTypeId)
  const runSimulation = useSimulatorStore((s) => s.runSimulation)
  const [messageIndex, setMessageIndex] = useState(0)

  useEffect(() => {
    if (!propertyTypeId) {
      navigate('/tipo-imovel', { replace: true })
      return
    }

    const interval = setInterval(() => {
      setMessageIndex((i) => Math.min(i + 1, messages.length - 1))
    }, 500)

    const timeout = setTimeout(() => {
      const result = runSimulation()
      track({
        name: 'simulacao_concluida',
        overallSafetyScore: result.overallSafetyScore,
        overallLevel: result.overallLevel,
      })
      navigate('/resultado', { replace: true })
    }, 2200)

    return () => {
      clearInterval(interval)
      clearTimeout(timeout)
    }
  }, [propertyTypeId, runSimulation, navigate])

  return (
    <div className="flex flex-col items-center justify-center gap-8 pt-16 text-center">
      <div className="relative w-40 h-40 rounded-3xl border-2 border-slate-800 bg-slate-900 overflow-hidden">
        <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 gap-px opacity-30">
          {Array.from({ length: 9 }).map((_, i) => (
            <div key={i} className="bg-slate-700" />
          ))}
        </div>
        <motion.div
          className="absolute left-0 right-0 h-10 bg-gradient-to-b from-orange-500/0 via-orange-500/40 to-orange-500/0"
          animate={{ top: ['0%', '85%', '0%'] }}
          transition={{ duration: 2.2, repeat: Infinity, ease: 'easeInOut' }}
        />
        <div className="absolute inset-0 flex items-center justify-center">
          <ScanLine className="text-orange-400" size={36} />
        </div>
      </div>

      <div>
        <h2 className="font-bold text-lg">Escaneando seu imóvel</h2>
        <p className="text-sm text-slate-400 mt-2 min-h-[20px]">{messages[messageIndex]}</p>
      </div>
    </div>
  )
}
