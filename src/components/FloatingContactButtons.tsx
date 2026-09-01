import { useState } from 'react'
import { ClipboardList, MessageCircle, Search, X } from 'lucide-react'
import { whatsappLink } from '../lib/contact'
import { track } from '../lib/analytics'

export function FloatingContactButtons({ raised = false }: { raised?: boolean }) {
  const [open, setOpen] = useState(false)

  return (
    <div className={`fixed ${raised ? 'bottom-36' : 'bottom-5'} right-4 z-40 flex flex-col items-end gap-2`}>
      {open && (
        <>
          <a
            href={whatsappLink('Olá! Gostaria de solicitar uma vistoria no local.')}
            target="_blank"
            rel="noreferrer"
            onClick={() => track({ name: 'cta_contato_clicado', productId: 'vistoria', channel: 'whatsapp' })}
            className="flex items-center gap-2 pl-3 pr-4 py-2.5 rounded-full bg-green-600 text-white text-xs font-semibold shadow-lg shadow-green-900/30 hover:brightness-110"
          >
            <Search size={14} /> Solicite uma vistoria no local
          </a>
          <a
            href={whatsappLink('Olá! Gostaria de uma cotação de equipamentos de proteção contra incêndio.')}
            target="_blank"
            rel="noreferrer"
            onClick={() => track({ name: 'cta_contato_clicado', productId: 'cotacao', channel: 'whatsapp' })}
            className="flex items-center gap-2 pl-3 pr-4 py-2.5 rounded-full bg-green-600 text-white text-xs font-semibold shadow-lg shadow-green-900/30 hover:brightness-110"
          >
            <ClipboardList size={14} /> Cotação de equipamentos de proteção
          </a>
        </>
      )}
      <button
        onClick={() => setOpen((v) => !v)}
        aria-label={open ? 'Fechar opções de contato' : 'Abrir opções de contato via WhatsApp'}
        className="w-12 h-12 flex items-center justify-center rounded-full bg-green-600 text-white shadow-lg shadow-green-900/30 hover:brightness-110"
      >
        {open ? <X size={20} /> : <MessageCircle size={20} />}
      </button>
    </div>
  )
}
