import type { Area } from '../types/domain'

export const areas: Area[] = [
  { id: 'cozinha', label: 'Cozinha', description: 'Gás, fogão, instalações elétricas', icon: 'ChefHat' },
  { id: 'sala', label: 'Sala', description: 'Eletrônicos, tomadas, aquecedores', icon: 'Sofa' },
  { id: 'quarto', label: 'Quarto', description: 'Carregadores, ar-condicionado', icon: 'BedDouble' },
  { id: 'garagem', label: 'Garagem', description: 'Veículos, combustíveis, produtos químicos', icon: 'Car' },
  { id: 'area_servico', label: 'Área de serviço', description: 'Máquinas e produtos de limpeza', icon: 'WashingMachine' },
  { id: 'deposito', label: 'Depósito / Estoque', description: 'Materiais e produtos armazenados', icon: 'Warehouse' },
  {
    id: 'area_externa_vegetacao',
    label: 'Área externa com vegetação',
    description: 'Mata, capim seco, proximidade rural',
    icon: 'Trees',
  },
  {
    id: 'sala_baterias',
    label: 'Baterias / Veículos elétricos',
    description: 'Power banks, bikes/patinetes elétricos, painéis solares',
    icon: 'BatteryCharging',
  },
  { id: 'quadro_eletrico', label: 'Quadro elétrico', description: 'Disjuntores, fiação, instalação', icon: 'Zap' },
]
