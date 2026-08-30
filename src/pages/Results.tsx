import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { AlertTriangle, CheckCircle2, Download, Mail } from 'lucide-react'
import { ScoreGauge } from '../components/ScoreGauge'
import { levelMeta } from '../lib/riskLevel'
import { Button } from '../components/Button'
import { track } from '../lib/analytics'
import { useSimulatorStore } from '../store/simulatorStore'
import { areas } from '../data/areas'

export function Results() {
  const navigate = useNavigate()
  const result = useSimulatorStore((s) => s.result)
  const [saved, setSaved] = useState<'email' | null>(null)

  useEffect(() => {
    if (!result) navigate('/tipo-imovel', { replace: true })
  }, [result, navigate])

  useEffect(() => {
    if (!result) return
    result.recommendedProducts.forEach((r) =>
      track({ name: 'produto_recomendado_visualizado', productId: r.product.id, relevance: r.relevance }),
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  if (!result) return null

  const overallMeta = levelMeta(result.overallLevel)

  function goToStorefront() {
    navigate('/produtos')
  }

  function saveResult() {
    track({ name: 'resultado_salvo', method: 'email' })
    setSaved('email')
  }

  return (
    <div className="flex flex-col gap-8 pb-6">
      <section className="flex flex-col items-center text-center gap-3">
        <span
          className={`text-xs font-semibold uppercase tracking-wide px-3 py-1 rounded-full ${overallMeta.bg} ${overallMeta.text}`}
        >
          {overallMeta.label}
        </span>
        <ScoreGauge score={result.overallSafetyScore} level={result.overallLevel} size={160} />
        <h1 className="text-lg font-bold">Score de segurança geral do imóvel</h1>
        <p className="text-sm text-slate-400 max-w-xs">
          Quanto mais alto o score, mais protegido está o seu imóvel contra incêndios hoje.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="font-bold text-base">Score por ambiente</h2>
        {result.areaResults.map((area) => {
          const meta = levelMeta(area.level)
          const areaData = areas.find((a) => a.id === area.areaId)
          return (
            <div key={area.areaId} className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-sm">{areaData?.label ?? area.label}</span>
                <span className={`text-sm font-bold ${meta.text}`}>{area.safetyScore}</span>
              </div>
              <div className="mt-2 h-1.5 rounded-full bg-slate-800 overflow-hidden">
                <div
                  className="h-full rounded-full"
                  style={{ width: `${area.safetyScore}%`, backgroundColor: meta.ring }}
                />
              </div>
              {area.identifiedRisks.length > 0 ? (
                <ul className="mt-3 flex flex-col gap-1.5">
                  {area.identifiedRisks.map((risk, i) => (
                    <li key={i} className="flex items-start gap-2 text-xs text-slate-400">
                      <AlertTriangle size={14} className="text-orange-400 shrink-0 mt-0.5" />
                      <span>{risk}</span>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="mt-3 flex items-center gap-2 text-xs text-green-400">
                  <CheckCircle2 size={14} /> Nenhum risco relevante identificado aqui
                </p>
              )}
            </div>
          )
        })}
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="font-bold text-base">Equipamentos recomendados para você</h2>
        <div className="flex flex-col gap-3">
          {result.recommendedProducts.slice(0, 3).map(({ product, reasons }) => (
            <div key={product.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-4 flex gap-3">
              <div className="text-3xl leading-none">{product.image}</div>
              <div className="flex-1">
                <p className="font-semibold text-sm">{product.name}</p>
                <p className="text-xs text-slate-500 mt-0.5">{product.tagline}</p>
                {reasons[0] && <p className="text-xs text-orange-400 mt-1.5">Por quê: {reasons[0]}</p>}
              </div>
            </div>
          ))}
        </div>
      </section>

      <div className="h-28" aria-hidden />
      <div className="fixed bottom-0 left-0 right-0 bg-slate-950/95 backdrop-blur border-t border-slate-800 px-4 pt-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))]">
        <div className="max-w-md mx-auto flex flex-col gap-2.5">
          <Button onClick={goToStorefront}>Ver equipamentos recomendados</Button>
          <div className="flex gap-2">
            <button
              onClick={saveResult}
              className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-300"
            >
              <Mail size={14} /> {saved === 'email' ? 'Enviado!' : 'Receber por e-mail'}
            </button>
            <button
              onClick={() => track({ name: 'resultado_salvo', method: 'pdf' })}
              className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-300"
            >
              <Download size={14} /> Baixar PDF
            </button>
          </div>
        </div>
      </div>

      <p className="text-[11px] text-slate-600 text-center leading-relaxed">
        Este resultado é uma ferramenta educativa e orientativa, com base nas classes de incêndio e
        diretrizes gerais do Corpo de Bombeiros. Não substitui vistoria técnica nem laudo (AVCB).
      </p>
    </div>
  )
}
