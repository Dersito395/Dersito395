import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { AnimatePresence } from 'framer-motion'
import { ArrowLeft } from 'lucide-react'
import { globalQuestions, questionsByArea } from '../data/questions'
import { areas } from '../data/areas'
import { QuestionCard } from '../components/QuestionCard'
import { track } from '../lib/analytics'
import { useSimulatorStore } from '../store/simulatorStore'
import type { Question } from '../types/domain'

export function Questions() {
  const navigate = useNavigate()
  const propertyTypeId = useSimulatorStore((s) => s.propertyTypeId)
  const selectedAreas = useSimulatorStore((s) => s.selectedAreas)
  const answers = useSimulatorStore((s) => s.answers)
  const answerQuestion = useSimulatorStore((s) => s.answerQuestion)

  useEffect(() => {
    if (!propertyTypeId) navigate('/tipo-imovel', { replace: true })
    else if (selectedAreas.length === 0) navigate('/areas', { replace: true })
  }, [propertyTypeId, selectedAreas, navigate])

  const flatQuestions: Question[] = useMemo(() => {
    const areaQs = selectedAreas.flatMap((areaId) => questionsByArea[areaId] ?? [])
    return [...globalQuestions, ...areaQs]
  }, [selectedAreas])

  const [index, setIndex] = useState(0)

  const question = flatQuestions[index]
  const areaLabel =
    question && question.areaId !== 'global'
      ? areas.find((a) => a.id === question.areaId)?.label
      : 'Geral'

  if (!question) return null

  function commitAndAdvance(optionIds: string[]) {
    answerQuestion(question.id, optionIds)
    track({
      name: 'pergunta_respondida',
      questionId: question.id,
      areaId: question.areaId,
      optionIds,
    })
    if (index + 1 < flatQuestions.length) {
      setIndex(index + 1)
    } else {
      navigate('/processando')
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center gap-3">
        {index > 0 && (
          <button
            onClick={() => setIndex(index - 1)}
            aria-label="Voltar para a pergunta anterior"
            className="flex items-center gap-1 text-xs font-medium text-slate-400 hover:text-slate-200 -ml-1 py-1 pr-2"
          >
            <ArrowLeft size={14} /> Voltar
          </button>
        )}
        <div>
          <span className="text-xs font-semibold uppercase tracking-wide text-orange-400">{areaLabel}</span>
          <p className="text-xs text-slate-500 mt-0.5">
            Pergunta {index + 1} de {flatQuestions.length}
          </p>
        </div>
      </div>

      <AnimatePresence mode="wait">
        <QuestionCard
          key={question.id}
          question={question}
          initialSelected={answers[question.id]}
          onAnswer={commitAndAdvance}
        />
      </AnimatePresence>
    </div>
  )
}
