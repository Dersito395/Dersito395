import { useNavigate, useParams } from 'react-router-dom'
import { CheckCircle2, MessageCircle, ShieldCheck, FileText, Package } from 'lucide-react'
import { products } from '../data/products'
import { Button } from '../components/Button'
import { track } from '../lib/analytics'
import { whatsappLink } from '../lib/contact'

export function ProductDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const product = products.find((p) => p.id === id)

  if (!product) {
    return (
      <div className="text-center py-16">
        <p className="text-slate-400">Produto não encontrado.</p>
        <button onClick={() => navigate('/produtos')} className="text-orange-400 mt-2 text-sm">
          Voltar para a vitrine
        </button>
      </div>
    )
  }

  function contact(channel: 'whatsapp' | 'orcamento') {
    if (!product) return
    track({ name: 'cta_contato_clicado', productId: product.id, channel })
  }

  return (
    <div className="flex flex-col gap-6 pb-6">
      <div className="flex flex-col items-center text-center gap-3 bg-slate-900 border border-slate-800 rounded-3xl py-10">
        <div className="text-6xl">{product.image}</div>
        <h1 className="text-lg font-bold px-4">{product.name}</h1>
        <p className="text-sm text-slate-400 px-6">{product.tagline}</p>
        <p className="text-xl font-extrabold text-orange-400">{product.price}</p>
      </div>

      <section>
        <h2 className="font-bold text-sm mb-2">Sobre o produto</h2>
        <p className="text-sm text-slate-400 leading-relaxed">{product.description}</p>
      </section>

      <section>
        <h2 className="font-bold text-sm mb-2">Especificações</h2>
        <ul className="flex flex-col gap-2">
          {product.specs.map((spec, i) => (
            <li key={i} className="flex items-start gap-2 text-sm text-slate-300">
              <CheckCircle2 size={16} className="text-green-400 shrink-0 mt-0.5" />
              <span>{spec}</span>
            </li>
          ))}
        </ul>
      </section>

      <section className="bg-slate-900 border border-slate-800 rounded-2xl p-4 flex items-start gap-2.5">
        <Package size={16} className="text-orange-400 shrink-0 mt-0.5" />
        <p className="text-sm text-slate-300">
          {product.quantityModel === 'fixed'
            ? 'Recomendação: 1 unidade para toda a propriedade.'
            : 'Recomendação: 1 unidade para cada cômodo/área onde o risco foi identificado.'}
        </p>
      </section>

      <section>
        <h2 className="font-bold text-sm mb-2">Ideal quando você identificou</h2>
        <ul className="flex flex-col gap-2">
          {product.idealFor.map((item, i) => (
            <li key={i} className="text-sm text-slate-400 bg-slate-900 border border-slate-800 rounded-xl px-3 py-2">
              {item}
            </li>
          ))}
        </ul>
      </section>

      <section className="bg-slate-900 border border-slate-800 rounded-2xl p-4 flex flex-col gap-2">
        <div className="flex items-center gap-2 text-sm font-semibold text-slate-200">
          <ShieldCheck size={16} className="text-orange-400" /> Classes de incêndio aplicáveis
        </div>
        <div className="flex gap-2 flex-wrap">
          {product.fireClasses.map((fc) => (
            <span key={fc} className="text-xs font-bold bg-slate-800 px-2.5 py-1 rounded-full text-slate-200">
              Classe {fc}
            </span>
          ))}
        </div>
        <p className="text-xs text-slate-500 mt-1">{product.standardsNote}</p>
      </section>

      <div className="h-32" aria-hidden />
      <div className="fixed bottom-0 left-0 right-0 bg-slate-950/95 backdrop-blur border-t border-slate-800 px-4 pt-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))]">
        <div className="max-w-md mx-auto flex flex-col gap-2.5">
          <a
            href={whatsappLink(`Olá! Tenho interesse no produto: ${product.name}`)}
            target="_blank"
            rel="noreferrer"
            onClick={() => contact('whatsapp')}
          >
            <Button className="flex items-center justify-center gap-2">
              <MessageCircle size={18} /> Falar no WhatsApp
            </Button>
          </a>
          <a
            href={whatsappLink(`Olá! Gostaria de um orçamento para: ${product.name}`)}
            target="_blank"
            rel="noreferrer"
            onClick={() => contact('orcamento')}
            className="w-full flex items-center justify-center gap-2 py-3 rounded-2xl bg-slate-900 border border-slate-800 text-sm font-semibold text-slate-200"
          >
            <FileText size={16} /> Solicitar orçamento
          </a>
        </div>
      </div>
    </div>
  )
}
