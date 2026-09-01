import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { ArrowLeft, Flame } from 'lucide-react'
import { stepProgress, SIMULATOR_STEPS } from '../lib/steps'
import { FloatingContactButtons } from './FloatingContactButtons'
import { COMPANY } from '../lib/contact'

export function Layout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { index, percent } = stepProgress(location.pathname)
  const showProgress = SIMULATOR_STEPS.some((s) => location.pathname.startsWith(s.path))
  const isHome = location.pathname === '/'
  const hasBottomBar = location.pathname === '/resultado' || /^\/produtos\/.+/.test(location.pathname)

  return (
    <div className="min-h-dvh bg-slate-950 text-slate-100 flex flex-col">
      <header className="sticky top-0 z-10 bg-slate-950/90 backdrop-blur border-b border-slate-800">
        <div className="max-w-md mx-auto w-full px-4 py-3 flex items-center gap-3">
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
            <span>
              Check - <span className="text-orange-500">Incêndios</span>
            </span>
          </Link>
          <div className="w-7" />
        </div>
        {showProgress && (
          <div className="max-w-md mx-auto w-full px-4 pb-3">
            <div className="h-2 rounded-full bg-slate-800 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-orange-500 to-red-500 transition-all duration-500 ease-out"
                style={{ width: `${percent}%` }}
              />
            </div>
            <div className="mt-1 flex justify-between text-[11px] text-slate-500">
              {SIMULATOR_STEPS.map((s, i) => (
                <span key={s.path} className={i <= index ? 'text-orange-400' : ''}>
                  {s.label}
                </span>
              ))}
            </div>
          </div>
        )}
      </header>
      <main className="flex-1 max-w-md mx-auto w-full px-4 py-6">
        <Outlet />
      </main>
      {!isHome && <FloatingContactButtons raised={hasBottomBar} />}
      <footer className="max-w-md mx-auto w-full px-4 py-5 text-center text-[10px] text-slate-600 leading-relaxed border-t border-slate-900">
        <p className="font-semibold text-slate-500">{COMPANY.name}</p>
        <p>CNPJ: {COMPANY.cnpj}</p>
        <p>Contato: {COMPANY.contact}</p>
        <p>{COMPANY.address}</p>
      </footer>
    </div>
  )
}
