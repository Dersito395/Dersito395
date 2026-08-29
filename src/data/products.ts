import type { Product } from '../types/domain'

export const products: Product[] = [
  {
    id: 'detector_fumaca',
    name: 'Detector Inteligente de Fumaça, Temperatura e Umidade',
    tagline: 'Monitoramento em tempo real, direto no seu celular',
    description:
      'Sensor com tecnologia Tuya que identifica fumaça, calor excessivo e umidade anormal, enviando alertas instantâneos para o app. Ideal para o primeiro sinal de um princípio de incêndio, quando ainda dá tempo de agir.',
    image: '🔥📡',
    price: 'A partir de R$ 249',
    specs: [
      'Conectividade Wi-Fi via app Tuya / Smart Life',
      'Sensor de fumaça óptico + temperatura + umidade',
      'Alertas push em tempo real, 24h por dia',
      'Sirene local de 85dB integrada',
      'Bateria com autonomia de longa duração + aviso de bateria fraca',
    ],
    appliesTo: ['Quartos', 'Cozinhas', 'Salas', 'Quadros elétricos', 'Salas de servidores/elétrica'],
    fireClasses: ['A', 'C'],
    standardsNote: 'Referência: detecção precoce recomendada pelas Instruções Técnicas do CB-PMESP para ocupações residenciais e comerciais.',
    idealFor: ['Instalação elétrica antiga ou sobrecarregada', 'Cozinhas com gás', 'Ambientes sem monitoramento atual'],
  },
  {
    id: 'extintor_classe_l',
    name: 'Extintor Classe L — Baterias de Lítio',
    tagline: 'O agente certo para o risco que mais cresce hoje',
    description:
      'Extintor desenvolvido especificamente para incêndios envolvendo baterias de lítio, que reagem de forma diferente do fogo comum e não são controladas por extintores convencionais. Essencial onde há veículos elétricos, bikes/patinetes ou muitos dispositivos eletrônicos.',
    image: '🧯⚡',
    price: 'A partir de R$ 690',
    specs: [
      'Agente extintor específico para incêndio Classe L (lítio)',
      'Resfria e isola células em thermal runaway',
      'Indicado para VEs, bicicletas e patinetes elétricos, power banks',
      'Fácil operação, sem necessidade de treinamento avançado',
    ],
    appliesTo: ['Garagens', 'Salas de baterias', 'Depósitos com eletrônicos', 'Frotas de veículos elétricos'],
    fireClasses: ['LITIO'],
    standardsNote: 'Classe de incêndio específica para lítio, complementar às classes A, B, C, D e K das Instruções Técnicas do CB-PMESP.',
    idealFor: ['Veículo elétrico ou moto elétrica em casa', 'Muitos power banks/eletrônicos', 'Baterias carregando sem supervisão'],
  },
  {
    id: 'kit_incendio_florestal',
    name: 'Kit de Combate a Incêndio Florestal para Pickup',
    tagline: 'Proteção robusta para propriedades rurais',
    description:
      'Sistema completo adaptado para pickup, com reservatório de 300L, motor a diesel e mangueira de 50m a 40 bar de pressão — autonomia e alcance para conter focos de incêndio em vegetação antes que se espalhem.',
    image: '🚙🌲',
    price: 'Sob consulta',
    specs: [
      'Reservatório de 300 litros',
      'Motor a diesel de alta pressão',
      'Mangueira de 50 metros',
      'Pressão de operação de 40 bar',
      'Estrutura adaptada para caçamba de pickup',
    ],
    appliesTo: ['Sítios e chácaras', 'Áreas rurais', 'Propriedades próximas a mata/vegetação'],
    fireClasses: ['A'],
    standardsNote: 'Apoio complementar ao combate a incêndio florestal; não substitui o acionamento do Corpo de Bombeiros.',
    idealFor: ['Vegetação seca próxima', 'Histórico de queimadas na região', 'Ausência de reservatório de água acessível'],
  },
]
