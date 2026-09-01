import type { Question } from '../types/domain'

export const globalQuestions: Question[] = [
  {
    id: 'equip_atual',
    areaId: 'global',
    text: 'Quais equipamentos de segurança contra incêndio você já tem hoje?',
    helpText: 'Selecione todos que se aplicam',
    multiple: true,
    options: [
      { id: 'extintor', label: 'Extintor de incêndio', riskPoints: -6, isProtective: true },
      { id: 'detector', label: 'Detector de fumaça', riskPoints: -6, isProtective: true },
      { id: 'hidrante', label: 'Hidrante ou reservatório de água', riskPoints: -4, isProtective: true },
      { id: 'nenhum', label: 'Nenhum equipamento ainda', riskPoints: 8, productBoost: { extintor_abc: 2 } },
    ],
  },
]

export const questionsByArea: Record<string, Question[]> = {
  cozinha: [
    {
      id: 'cozinha_gas',
      areaId: 'cozinha',
      text: 'A cozinha usa botijão ou instalação de gás?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 6,
          fireClasses: ['B'],
          productBoost: { detector_fumaca: 2, detector_gas: 4, manta_incendio: 2 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'cozinha_eletrica',
      areaId: 'cozinha',
      text: 'A instalação elétrica da cozinha é antiga (+15 anos) ou já apresentou sobrecarga?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 7,
          fireClasses: ['C'],
          productBoost: { detector_fumaca: 3, extintor_abc: 2, iluminacao_emergencia: 1 },
        },
        { id: 'nao', label: 'Não / não sei', riskPoints: 2 },
      ],
    },
    {
      id: 'cozinha_historico',
      areaId: 'cozinha',
      text: 'Já houve princípio de incêndio ou superaquecimento na cozinha?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 8,
          productBoost: { detector_fumaca: 3, manta_incendio: 3, extintor_abc: 2 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
  ],
  sala: [
    {
      id: 'sala_tomadas',
      areaId: 'sala',
      text: 'Há muitos aparelhos ligados na mesma tomada ou uso de extensões sobrecarregadas?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 6,
          fireClasses: ['C'],
          productBoost: { detector_fumaca: 2, extintor_abc: 2, iluminacao_emergencia: 1 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'sala_aquecedor',
      areaId: 'sala',
      text: 'Possui lareira, lareira ecológica ou aquecedor a combustão?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 5,
          fireClasses: ['A'],
          productBoost: { detector_fumaca: 2, extintor_abc: 2 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
  ],
  quarto: [
    {
      id: 'quarto_carregador',
      areaId: 'quarto',
      text: 'Costuma carregar celular, notebook ou power bank sobre a cama ou perto de objetos inflamáveis?',
      options: [
        { id: 'sim', label: 'Sim', riskPoints: 6, fireClasses: ['C', 'LITIO'], productBoost: { detector_fumaca: 2, extintor_classe_l: 1 } },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'quarto_climatizacao',
      areaId: 'quarto',
      text: 'Possui ar-condicionado ou aquecedor elétrico antigo?',
      options: [
        { id: 'sim', label: 'Sim', riskPoints: 4, fireClasses: ['C'], productBoost: { detector_fumaca: 2, extintor_abc: 1 } },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
  ],
  garagem: [
    {
      id: 'garagem_ve',
      areaId: 'garagem',
      text: 'Possui veículo elétrico, moto elétrica, bicicleta ou patinete elétrico carregando na garagem?',
      options: [
        { id: 'sim', label: 'Sim', riskPoints: 9, fireClasses: ['LITIO'], productBoost: { extintor_classe_l: 5 } },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'garagem_quimicos',
      areaId: 'garagem',
      text: 'Armazena combustível, solventes ou produtos químicos inflamáveis?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 8,
          fireClasses: ['B'],
          productBoost: { detector_fumaca: 2, extintor_abc: 3 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'garagem_fiacao',
      areaId: 'garagem',
      text: 'O quadro elétrico ou a fiação da garagem ficam expostos?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 5,
          fireClasses: ['C'],
          productBoost: { detector_fumaca: 2, extintor_abc: 2, iluminacao_emergencia: 1 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
  ],
  area_servico: [
    {
      id: 'servico_maquinas',
      areaId: 'area_servico',
      text: 'As máquinas de lavar/secar estão em instalação elétrica sobrecarregada?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 5,
          fireClasses: ['C'],
          productBoost: { detector_fumaca: 2, extintor_abc: 2 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'servico_quimicos',
      areaId: 'area_servico',
      text: 'Armazena produtos de limpeza inflamáveis (álcool, solventes)?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 5,
          fireClasses: ['B'],
          productBoost: { detector_fumaca: 1, extintor_abc: 2 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
  ],
  deposito: [
    {
      id: 'deposito_classe_a',
      areaId: 'deposito',
      text: 'Armazena grande quantidade de papel, tecido, plástico ou madeira?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 6,
          fireClasses: ['A'],
          productBoost: { detector_fumaca: 3, extintor_abc: 3, iluminacao_emergencia: 1 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'deposito_classe_b',
      areaId: 'deposito',
      text: 'Armazena combustíveis, tintas ou solventes?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 7,
          fireClasses: ['B'],
          productBoost: { detector_fumaca: 2, extintor_abc: 3 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'deposito_eletronicos',
      areaId: 'deposito',
      text: 'Guarda muitos equipamentos eletrônicos ou baterias?',
      options: [
        { id: 'sim', label: 'Sim', riskPoints: 6, fireClasses: ['LITIO'], productBoost: { extintor_classe_l: 3, detector_fumaca: 2 } },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
  ],
  area_externa_vegetacao: [
    {
      id: 'vegetacao_proximidade',
      areaId: 'area_externa_vegetacao',
      text: 'A propriedade fica próxima a mata, vegetação seca ou área com histórico de queimadas?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 10,
          fireClasses: ['A'],
          productBoost: { kit_incendio_florestal: 6, kit_incendio_florestal_manual: 4, mangueira_incendio: 2 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'vegetacao_queimadas',
      areaId: 'area_externa_vegetacao',
      text: 'Costuma fazer queimadas, uso de fogo para limpeza de terreno, ou tem churrasqueira próxima à vegetação?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 8,
          fireClasses: ['A'],
          productBoost: { kit_incendio_florestal: 4, kit_incendio_florestal_manual: 3, mangueira_incendio: 1 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
    {
      id: 'vegetacao_agua',
      areaId: 'area_externa_vegetacao',
      text: 'Existe fonte de água ou reservatório próximo para combate a um princípio de incêndio florestal?',
      options: [
        {
          id: 'sim',
          label: 'Sim, tenho acesso fácil',
          riskPoints: -3,
          isProtective: true,
          productBoost: { mangueira_incendio: 3 },
        },
        {
          id: 'nao',
          label: 'Não, ou é distante',
          riskPoints: 5,
          productBoost: { kit_incendio_florestal: 3, mangueira_incendio: 4 },
        },
      ],
    },
  ],
  sala_baterias: [
    {
      id: 'baterias_quantidade',
      areaId: 'sala_baterias',
      text: 'Quantas baterias de lítio (power banks, VE, bikes/patinetes elétricos, painéis solares) existem no ambiente?',
      options: [
        { id: 'muitas', label: 'Muitas (mais de 5 unidades ou um veículo)', riskPoints: 10, fireClasses: ['LITIO'], productBoost: { extintor_classe_l: 6 } },
        { id: 'poucas', label: 'Poucas (1 a 5 unidades)', riskPoints: 5, fireClasses: ['LITIO'], productBoost: { extintor_classe_l: 3 } },
        { id: 'nenhuma', label: 'Nenhuma', riskPoints: 0 },
      ],
    },
    {
      id: 'baterias_supervisao',
      areaId: 'sala_baterias',
      text: 'As baterias ficam carregando sem supervisão por longos períodos (ex: durante a noite)?',
      options: [
        { id: 'sim', label: 'Sim', riskPoints: 7, fireClasses: ['LITIO'], productBoost: { extintor_classe_l: 3, detector_fumaca: 2 } },
        { id: 'nao', label: 'Não', riskPoints: 1 },
      ],
    },
    {
      id: 'baterias_ventilacao',
      areaId: 'sala_baterias',
      text: 'O ambiente tem ventilação adequada?',
      options: [
        { id: 'sim', label: 'Sim', riskPoints: -2, isProtective: true },
        { id: 'nao', label: 'Não / não sei', riskPoints: 4 },
      ],
    },
  ],
  quadro_eletrico: [
    {
      id: 'quadro_estado',
      areaId: 'quadro_eletrico',
      text: 'O quadro elétrico tem sinais de superaquecimento, fiação exposta, ou tem mais de 20 anos?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 9,
          fireClasses: ['C'],
          productBoost: { detector_fumaca: 4, extintor_abc: 3, iluminacao_emergencia: 2 },
        },
        { id: 'nao', label: 'Não', riskPoints: 1 },
      ],
    },
    {
      id: 'quadro_historico',
      areaId: 'quadro_eletrico',
      text: 'Já houve curto-circuito ou queda de energia por sobrecarga?',
      options: [
        {
          id: 'sim',
          label: 'Sim',
          riskPoints: 7,
          fireClasses: ['C'],
          productBoost: { detector_fumaca: 3, extintor_abc: 2, iluminacao_emergencia: 1 },
        },
        { id: 'nao', label: 'Não', riskPoints: 0 },
      ],
    },
  ],
}
