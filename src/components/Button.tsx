import type { ButtonHTMLAttributes, ReactNode } from 'react'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost'
  children: ReactNode
}

const variants: Record<string, string> = {
  primary:
    'bg-gradient-to-r from-orange-500 to-red-600 text-white shadow-lg shadow-orange-900/30 hover:brightness-110 disabled:opacity-40 disabled:cursor-not-allowed',
  secondary: 'bg-slate-800 text-slate-100 hover:bg-slate-700 disabled:opacity-40',
  ghost: 'bg-transparent text-slate-300 hover:bg-slate-800',
}

export function Button({ variant = 'primary', className = '', children, ...props }: ButtonProps) {
  return (
    <button
      className={`w-full py-3.5 px-5 rounded-2xl font-semibold text-base transition-all active:scale-[0.98] ${variants[variant]} ${className}`}
      {...props}
    >
      {children}
    </button>
  )
}
