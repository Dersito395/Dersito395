import { useEffect } from 'react'
import type { ReactNode } from 'react'
import { Flame, RefreshCw } from 'lucide-react'
import { useOccurrenceStore } from '../store/occurrenceStore'

/**
 * Garante que o app só renderiza depois de tentar carregar dados do backend
 * (Supabase). Mostra uma tela de configuração se as variáveis de ambiente
 * não estiverem definidas, e uma tela de erro com "tentar novamente" se a
 * conexão falhar — nunca renderiza o app com dados parciais/desatualizados.
 */
export function ConnectionGate({ children }: { children: ReactNode }) {
  const status = useOccurrenceStore((s) => s.connectionStatus)
  const error = useOccurrenceStore((s) => s.connectionError)
  const init = useOccurrenceStore((s) => s.init)

  useEffect(() => {
    init()
  }, [init])

  if (status === 'ready') return <>{children}</>

  return (
    <div className="min-h-dvh bg-slate-950 text-slate-100 flex flex-col items-center justify-center px-6 text-center">
      <Flame className="text-orange-500 mb-4" size={32} />
      {(status === 'idle' || status === 'loading') && (
        <p className="text-slate-400 text-sm">Carregando ocorrências...</p>
      )}

      {status === 'not_configured' && (
        <div className="max-w-sm space-y-3">
          <h1 className="text-lg font-bold">Backend não configurado</h1>
          <p className="text-sm text-slate-400">
            Defina <code className="text-orange-400">VITE_SUPABASE_URL</code> e{' '}
            <code className="text-orange-400">VITE_SUPABASE_ANON_KEY</code> nas variáveis de ambiente e rode{' '}
            <code className="text-orange-400">supabase/schema.sql</code> no seu projeto Supabase. Veja o README.
          </p>
        </div>
      )}

      {status === 'error' && (
        <div className="max-w-sm space-y-3">
          <h1 className="text-lg font-bold">Não foi possível conectar ao backend</h1>
          <p className="text-sm text-slate-400">{error}</p>
          <button
            onClick={() => init()}
            className="inline-flex items-center gap-2 text-sm font-semibold text-orange-400 hover:text-orange-300"
          >
            <RefreshCw size={14} /> Tentar novamente
          </button>
        </div>
      )}
    </div>
  )
}
