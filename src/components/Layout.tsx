import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { AlertTriangle, ArrowLeft, BarChart3, Flame, Settings } from 'lucide-react'
import { OCCURRENCE_STEPS, stepProgress } from '../lib/steps'
import { useOccurrenceStore } from '../store/occurrenceStore'

export function Layout() {
  const location = useLocation()
  const navigate = useNavigate()
  const progress = stepProgress(location.pathname)
  const isHome = location.pathname === '/'
  const syncError = useOccurrenceStore((s) => s.syncError)

  return (
    <div className="min-h-dvh bg-slate-950 text-slate-100 flex flex-col">
      <header className="sticky top-0 z-10 bg-slate-950/90 backdrop-blur border-b border-slate-800">
        <div className="max-w-2xl mx-auto w-full px-4 py-3 flex items-center gap-3">
          {!isHome ? (
            <button
              onClick={() => navigate(-1)}
              aria-label="Voltar"
              className="p-1.5 rounded-full hover:bg-slate-800 text-slate-300"
            >
              <ArrowLeft size={20} />
            </button>
          ) : (
            <div className="w-7" />
          )}
          <Link to="/" className="flex items-center gap-2 font-bold tracking-tight text-lg mx-auto">
            <Flame className="text-orange-500" size={22} />
            <span>Aceiro</span>
          </Link>
          <div className="flex items-center gap-1">
            <Link to="/modelo" aria-label="Painel do modelo" className="p-1.5 rounded-full hover:bg-slate-800 text-slate-300">
              <BarChart3 size={19} />
            </Link>
            <Link to="/configuracoes" aria-label="Configurações" className="p-1.5 rounded-full hover:bg-slate-800 text-slate-300">
              <Settings size={19} />
            </Link>
          </div>
        </div>
        {progress && (
          <div className="max-w-2xl mx-auto w-full px-4 pb-3">
            <div className="h-2 rounded-full bg-slate-800 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-orange-500 to-red-500 transition-all duration-500 ease-out"
                style={{ width: `${progress.percent}%` }}
              />
            </div>
            <div className="mt-1 flex justify-between text-[11px] text-slate-500">
              {OCCURRENCE_STEPS.map((s, i) => (
                <span key={s.suffix} className={i <= progress.index ? 'text-orange-400' : ''}>
                  {s.label}
                </span>
              ))}
            </div>
          </div>
        )}
      </header>
      {syncError && (
        <div className="max-w-2xl mx-auto w-full px-4 pt-3">
          <div className="flex items-center gap-2 rounded-xl bg-red-950/40 border border-red-900/50 px-3 py-2 text-xs text-red-300">
            <AlertTriangle size={14} className="shrink-0" />
            <span>Falha ao sincronizar com o servidor — dados podem não ter sido salvos. {syncError}</span>
          </div>
        </div>
      )}
      <main className="flex-1 max-w-2xl mx-auto w-full px-4 py-6">
        <Outlet />
      </main>
      <footer className="max-w-2xl mx-auto w-full px-4 py-4 text-center text-[11px] text-slate-600">
        Copiloto de apoio à decisão — toda recomendação é uma sugestão. A decisão final é sempre humana.
      </footer>
    </div>
  )
}
