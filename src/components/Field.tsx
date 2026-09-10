import type { InputHTMLAttributes, ReactNode, SelectHTMLAttributes, TextareaHTMLAttributes } from 'react'

export function Field({ label, help, children }: { label: string; help?: string; children: ReactNode }) {
  return (
    <label className="block mb-4">
      <span className="block text-sm font-medium text-slate-300 mb-1.5">{label}</span>
      {children}
      {help && <span className="block text-xs text-slate-500 mt-1">{help}</span>}
    </label>
  )
}

const inputClass =
  'w-full rounded-xl bg-slate-800 border border-slate-700 px-3.5 py-2.5 text-sm text-slate-100 outline-none focus:border-orange-500 transition-colors'

export function TextInput(props: InputHTMLAttributes<HTMLInputElement>) {
  return <input className={inputClass} {...props} />
}

export function Select(props: SelectHTMLAttributes<HTMLSelectElement>) {
  return <select className={inputClass} {...props} />
}

export function TextArea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea className={`${inputClass} min-h-20`} {...props} />
}
