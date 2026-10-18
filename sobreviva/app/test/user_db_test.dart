import 'package:flutter_test/flutter_test.dart';
import 'package:sobreviva/data/user_db.dart';
import 'package:sobreviva/services/backpack_planner.dart';

void main() {
  test('favoritos, notas, histórico e preferências', () {
    final u = UserDatabase.inMemory();
    u.setFavorite('a', true);
    u.setFavorite('a', true);
    expect(u.favoriteIds(), ['a']);
    u.saveNote('a', 'texto');
    expect(u.note('a'), 'texto');
    u.saveNote('a', '   ');
    expect(u.note('a'), isNull);
    u.recordView('a');
    u.recordView('a');
    expect(u.history().single.count, 2);
    u.addSearch('bússola');
    u.addSearch('bússola');
    expect(u.searchHistory(), ['bússola']);
    expect(u.searchHistory(prefix: 'bú'), ['bússola']);
    u.setPref('theme', 'dark');
    expect(u.pref('theme'), 'dark');
  });

  test('exportar e importar sem perder dados existentes', () {
    final a = UserDatabase.inMemory();
    a.setFavorite('ps-rcp-adulto', true);
    a.saveNote('ps-rcp-adulto', 'DEA na portaria');
    final id = a.createChecklist('Kit carro', 'equipamento', [('Lanterna', null), ('Água', 'Básico')]);
    a.setItemDone(a.items(id).first.id, true);
    final exported = a.exportData();

    final b = UserDatabase.inMemory();
    b.saveNote('ps-rcp-adulto', 'Nota local');
    final r = b.importData(exported);
    expect(r.checklists, 1);
    expect(b.isFavorite('ps-rcp-adulto'), isTrue);
    expect(b.note('ps-rcp-adulto'), allOf(contains('Nota local'), contains('DEA na portaria')));
    final items = b.items(b.checklists().single.id);
    expect(items.map((i) => i.text), ['Lanterna', 'Água']);
    expect(items.first.done, isTrue);
    expect(() => b.importData({'app': 'outro'}), throwsFormatException);
  });

  test('planejador usa referência de água com fonte e adapta itens', () {
    final plan = buildKitPlan(
      const KitPlanInput(duration: KitDuration.h72, adults: 2, children: 1, pets: 1, environments: {KitEnvironment.urbano, KitEnvironment.frio}),
    );
    final texts = plan.map((e) => e.text).join('\n');
    expect(texts, contains('35 L')); // 3,8 × 3 pessoas × 3 dias = 34,2 → 35
    expect(texts, contains('FEMA/Ready.gov'));
    expect(texts, contains('gorro'));
    expect(texts, contains('ração'));
    final evac = buildKitPlan(const KitPlanInput(duration: KitDuration.h24));
    expect(evac.map((e) => e.text).join(), isNot(contains(' L (')));
  });
}
