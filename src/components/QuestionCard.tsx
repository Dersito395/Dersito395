import { useState } from 'react'
import { motion } from 'framer-motion'
import { Button } from './Button'
import type { Question } from '../types/domain'

interface QuestionCardProps {
  question: Question
  initialSelected?: string[]
  onAnswer: (optionIds: string[]) => void
}

export function QuestionCard({ question, initialSelected, onAnswer }: QuestionCardProps) {
  const [selected, setSelected] = useState<string[]>(initialSelected ?? [])

  function toggleMulti(optionId: string) {
    setSelected((prev) => (prev.includes(optionId) ? prev.filter((o) => o !== optionId) : [...prev, optionId]))
  }

  return (
    <motion.div
      initial={{ opacity: 0, x: 16 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -16 }}
      transition={{ duration: 0.2 }}
      className="flex flex-col gap-4"
    >
      <h2 className="text-lg font-bold leading-snug">{question.text}</h2>
      {question.helpText && <p className="text-sm text-slate-500 -mt-2">{question.helpText}</p>}

      <div className="flex flex-col gap-2.5">
        {question.options.map((opt) => {
          const isActive = selected.includes(opt.id)
          return (
            <button
              key={opt.id}
              onClick={() => (question.multiple ? toggleMulti(opt.id) : onAnswer([opt.id]))}
              className={`text-left px-4 py-3.5 rounded-2xl border transition-colors font-medium text-sm ${
                isActive
                  ? 'bg-orange-500/15 border-orange-500 text-orange-300'
                  : 'bg-slate-900 border-slate-800 hover:border-slate-600 text-slate-200'
              }`}
            >
              {opt.label}
            </button>
          )
        })}
      </div>

      {question.multiple && (
        <Button onClick={() => onAnswer(selected)} disabled={selected.length === 0}>
          Continuar
        </Button>
      )}
    </motion.div>
  )
}
