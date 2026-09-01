import { Link } from 'react-router-dom'
import { ChevronRight, MessageCircle, Sparkles } from 'lucide-react'
import { products } from '../data/products'
import { useSimulatorStore } from '../store/simulatorStore'
import { track } from '../lib/analytics'
import { whatsappLink } from '../lib/contact'

export function Storefront() {
  const result = useSimulatorStore((s) => s.result)

  const recommendedIds = result?.recommendedProducts.map((r) => r.product.id) ?? []
  const ordered = recommendedIds.length
    ? [...products].sort((a, b) => recommendedIds.indexOf(a.id) - recommendedIds.indexOf(b.id))
    : products

  function handleClick(productId: string) {
    track({ name: 'produto_clicado', productId, origin: 'vitrine' })
  }

  return (
    <div className="flex flex-col gap-5">
      <div>
        <h1 className="text-xl font-bold">Equipamentos de proteção</h1>
        <p className="text-sm text-slate-400 mt-1">
          {result
            ? 'Ordenados de acordo com o risco identificado no seu simulado.'
            : 'Conheça nossa linha de proteção contra incêndio.'}
        </p>
      </div>

      <div className="flex flex-col gap-4">
        {ordered.map((product, i) => {
          const recommendation = result?.recommendedProducts.find((r) => r.product.id === product.id)
          return (
            <div
              key={product.id}
              className="bg-slate-900 border border-slate-800 rounded-2xl p-4 flex gap-3 hover:border-orange-500/60 transition-colors"
            >
              <Link to={`/produtos/${product.id}`} onClick={() => handleClick(product.id)} className="flex gap-3 flex-1 min-w-0">
                <div className="text-4xl leading-none">{product.image}</div>
                <div className="flex-1 min-w-0">
                  {i === 0 && recommendation && recommendation.relevance > 0 && (
                    <span className="inline-flex items-center gap-1 text-[10px] font-semibold text-orange-400 bg-orange-500/10 px-2 py-0.5 rounded-full mb-1.5">
                      <Sparkles size={10} /> Top recomendação
                    </span>
                  )}
                  <p className="font-semibold text-sm">{product.name}</p>
                  <p className="text-xs text-slate-500 mt-0.5">{product.tagline}</p>
                  {recommendation && (
                    <p className="text-[11px] text-slate-500 mt-1.5 leading-snug">{recommendation.quantityNote}</p>
                  )}
                  <p className="text-sm font-bold text-orange-400 mt-2">{product.price}</p>
                </div>
              </Link>
              <div className="flex flex-col items-center justify-between shrink-0">
                <ChevronRight size={18} className="text-slate-600" />
                <a
                  href={whatsappLink(`Olá! Tenho interesse no produto: ${product.name}`)}
                  target="_blank"
                  rel="noreferrer"
                  aria-label={`Falar no WhatsApp sobre ${product.name}`}
                  onClick={() => track({ name: 'cta_contato_clicado', productId: product.id, channel: 'whatsapp' })}
                  className="p-2 rounded-full bg-green-600/15 text-green-400 hover:bg-green-600/25"
                >
                  <MessageCircle size={16} />
                </a>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
