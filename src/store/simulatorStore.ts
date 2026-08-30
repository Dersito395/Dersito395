import { create } from 'zustand'
import { calculateSimulation, type SimulationResult } from '../engine/riskEngine'
import type { AnswersMap, AreaId, PropertyTypeId } from '../types/domain'

interface SimulatorState {
  propertyTypeId: PropertyTypeId | null
  selectedAreas: AreaId[]
  answers: AnswersMap
  result: SimulationResult | null

  setPropertyType: (id: PropertyTypeId) => void
  toggleArea: (id: AreaId) => void
  setAreas: (ids: AreaId[]) => void
  answerQuestion: (questionId: string, optionIds: string[]) => void
  runSimulation: () => SimulationResult
  reset: () => void
}

export const useSimulatorStore = create<SimulatorState>((set, get) => ({
  propertyTypeId: null,
  selectedAreas: [],
  answers: {},
  result: null,

  setPropertyType: (id) => set({ propertyTypeId: id }),

  toggleArea: (id) =>
    set((state) => ({
      selectedAreas: state.selectedAreas.includes(id)
        ? state.selectedAreas.filter((a) => a !== id)
        : [...state.selectedAreas, id],
    })),

  setAreas: (ids) => set({ selectedAreas: ids }),

  answerQuestion: (questionId, optionIds) =>
    set((state) => ({ answers: { ...state.answers, [questionId]: optionIds } })),

  runSimulation: () => {
    const { propertyTypeId, selectedAreas, answers } = get()
    if (!propertyTypeId) throw new Error('Tipo de imóvel não selecionado')
    const result = calculateSimulation(propertyTypeId, selectedAreas, answers)
    set({ result })
    return result
  },

  reset: () => set({ propertyTypeId: null, selectedAreas: [], answers: {}, result: null }),
}))
