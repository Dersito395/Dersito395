import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { AnimatePresence } from 'framer-motion'
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
      <div>
        <span className="text-xs font-semibold uppercase tracking-wide text-orange-400">{areaLabel}</span>
        <p className="text-xs text-slate-500 mt-0.5">
          Pergunta {index + 1} de {flatQuestions.length}
        </p>
      </div>

      <AnimatePresence mode="wait">
        <QuestionCard key={question.id} question={question} onAnswer={commitAndAdvance} />
      </AnimatePresence>
    </div>
  )
}
