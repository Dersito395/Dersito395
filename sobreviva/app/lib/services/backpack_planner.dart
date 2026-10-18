/// Planejador de mochila/kit de emergência.
///
/// Gera uma lista de itens conforme duração, pessoas e ambiente. Não inventa
/// quantidades universais: a única quantidade calculada é a referência de água
/// publicada pela FEMA/Ready.gov (≈3,8 L por pessoa por dia), sempre exibida
/// com a fonte e a recomendação de ajuste.
library;

enum KitDuration { h24, h72, d7 }

enum KitEnvironment { urbano, mata, frio, calor, enchente }

const Map<KitDuration, String> kitDurationLabels = {
  KitDuration.h24: '24 horas (mochila de evacuação)',
  KitDuration.h72: '72 horas',
  KitDuration.d7: '7 dias (permanência em casa)',
};

const Map<KitEnvironment, String> kitEnvironmentLabels = {
  KitEnvironment.urbano: 'Cidade / casa',
  KitEnvironment.mata: 'Mata / trilha',
  KitEnvironment.frio: 'Frio / serra',
  KitEnvironment.calor: 'Calor intenso / semiárido',
  KitEnvironment.enchente: 'Área sujeita a enchentes',
};

class KitPlanInput {
  const KitPlanInput({
    this.duration = KitDuration.h72,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.elderly = 0,
    this.pets = 0,
    this.environments = const {KitEnvironment.urbano},
    this.continuousMedication = false,
    this.mobilityNeeds = false,
  });

  final KitDuration duration;
  final int adults;
  final int children;
  final int infants;
  final int elderly;
  final int pets;
  final Set<KitEnvironment> environments;
  final bool continuousMedication;
  final bool mobilityNeeds;

  int get people => adults + children + infants + elderly;

  int get days => switch (duration) {
    KitDuration.h24 => 1,
    KitDuration.h72 => 3,
    KitDuration.d7 => 7,
  };

  Map<String, Object?> toJson() => {
    'duration': duration.name,
    'adults': adults,
    'children': children,
    'infants': infants,
    'elderly': elderly,
    'pets': pets,
    'environments': environments.map((e) => e.name).toList(),
    'medication': continuousMedication,
    'mobility': mobilityNeeds,
  };
}

class KitItem {
  const KitItem(this.section, this.text);
  final String section;
  final String text;
}

/// Referência de água por pessoa/dia (FEMA/Ready.gov: 1 galão ≈ 3,8 L).
const double waterReferenceLitersPerPersonDay = 3.8;

List<KitItem> buildKitPlan(KitPlanInput input) {
  final items = <KitItem>[];
  void add(String section, String text) => items.add(KitItem(section, text));
  final d = input.days;
  final evacuation = input.duration == KitDuration.h24;
  final envs = input.environments;

  // Água e alimentação
  const water = 'Água e alimentação';
  if (evacuation) {
    add(water, 'Garrafas de água para cada pessoa, no volume que cada uma consegue carregar');
  } else {
    final liters = (waterReferenceLitersPerPersonDay * input.people * d).ceil();
    add(
      water,
      'Água: referência mínima de $liters L (3,8 L × ${input.people} pessoa(s) × $d dia(s), segundo FEMA/Ready.gov). Aumente em calor, esforço físico, gestação, amamentação e doença',
    );
  }
  add(water, 'Meio de tratar água (hipoclorito 2,5% ou pastilhas) e recipiente limpo');
  add(water, 'Alimentos prontos para consumo para $d dia(s), que a família já costuma comer, sem necessidade de refrigeração');
  add(water, 'Abridor de latas manual, talheres e copo');
  if (input.infants > 0) add(water, 'Fórmula infantil ou alimentação do bebê, mamadeira e água adequada para preparo');
  if (input.pets > 0) add(water, 'Água e ração para ${input.pets} animal(is) por $d dia(s), com tigelas');

  // Saúde e higiene
  const health = 'Saúde e higiene';
  add(health, 'Kit de primeiros socorros (gaze, atadura, luvas, esparadrapo, tesoura)');
  if (input.continuousMedication || input.elderly > 0) {
    add(health, 'Medicamentos de uso contínuo para $d dia(s) ou mais, com cópia das receitas');
    add(health, 'Lista de condições de saúde, alergias e contatos médicos');
  }
  add(health, 'Sabão, álcool em gel, papel higiênico e itens de higiene íntima');
  add(health, 'Sacos de lixo e lenços umedecidos');
  add(health, 'Máscaras (preferencialmente PFF2/N95)');
  if (input.infants > 0) add(health, 'Fraldas, pomada e lenços para o bebê');
  if (envs.contains(KitEnvironment.mata)) add(health, 'Repelente de insetos');
  if (envs.contains(KitEnvironment.calor) || envs.contains(KitEnvironment.mata)) {
    add(health, 'Protetor solar, chapéu e óculos de sol');
    add(health, 'Sais de reidratação oral (SRO)');
  }

  // Abrigo e roupas
  const shelter = 'Abrigo e roupas';
  add(shelter, 'Muda de roupa e calçado fechado para cada pessoa');
  add(shelter, 'Manta térmica aluminizada ou cobertor leve para cada pessoa');
  if (envs.contains(KitEnvironment.frio)) {
    add(shelter, 'Roupas em camadas, gorro, luvas e meias de lã extras');
    add(shelter, 'Saco de dormir adequado ao frio e isolante para o chão');
  }
  if (envs.contains(KitEnvironment.mata)) {
    add(shelter, 'Lona leve e cordas para abrigo improvisado');
    add(shelter, 'Isolante para o chão');
  }
  if (envs.contains(KitEnvironment.enchente)) {
    add(shelter, 'Botas e luvas de borracha');
    add(shelter, 'Sacos estanques para roupas e documentos');
  }
  add(shelter, 'Capa de chuva');

  // Iluminação e comunicação
  const comm = 'Iluminação e comunicação';
  add(comm, 'Lanterna (de preferência de cabeça) e pilhas extras');
  add(comm, 'Rádio AM/FM a pilha ou à manivela');
  add(comm, 'Bateria externa carregada e cabo do celular');
  add(comm, 'Apito para pedir socorro');
  add(comm, 'Lista de contatos de emergência impressa e ponto de encontro combinado');
  if (envs.contains(KitEnvironment.mata)) {
    add(comm, 'Mapa da região, bússola e mapas offline baixados no celular');
    add(comm, 'Espelho de sinalização');
  }

  // Ferramentas
  const tools = 'Ferramentas';
  add(tools, 'Canivete ou multiferramenta');
  add(tools, 'Fita adesiva larga e lona plástica');
  add(tools, 'Fósforos à prova d’água ou isqueiro em saco plástico');
  if (!evacuation) add(tools, 'Ferramenta para fechar registros de gás e água');

  // Documentos e dinheiro
  const docs = 'Documentos e dinheiro';
  add(docs, 'Cópias de documentos pessoais em saco impermeável');
  add(docs, 'Dinheiro em espécie (notas pequenas)');
  if (input.pets > 0) add(docs, 'Carteira de vacinação, coleira, guia e foto dos animais');

  // Necessidades específicas
  const special = 'Necessidades específicas';
  if (input.children > 0) {
    add(special, 'Para crianças: nome e telefone do responsável anotados, brinquedo ou atividade, roupas extras');
  }
  if (input.elderly > 0 || input.mobilityNeeds) {
    add(special, 'Óculos, aparelhos auditivos e pilhas, bengala ou andador');
    add(special, 'Plano de evacuação que considere a mobilidade (quem ajuda e como)');
  }

  return items;
}
