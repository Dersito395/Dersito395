import 'package:flutter_test/flutter_test.dart';
import 'package:sobreviva/data/library_db.dart';
import 'package:sobreviva/data/user_db.dart';

import 'helpers.dart';

void main() {
  test('pacote essencial instala artigos, emergências, números e fontes', () {
    final lib = libraryWithBundle();
    expect(lib.articleCount, greaterThanOrEqualTo(30));
    expect(lib.categories().length, 12);
    expect(lib.emergencies().length, 11);
    expect(lib.numbers().map((n) => n.number), containsAll(['190', '192', '193']));
    final a = lib.article('abrigo-lona-improvisado')!;
    expect(a.steps, isNotEmpty);
    expect(a.sources, isNotEmpty);
    expect(a.sources.every((s) => s.url.startsWith('http')), isTrue);
    expect(a.images.first.license, 'CC BY 4.0');
    expect(lib.packages().single.bundled, isTrue);
  });

  test('todo artigo tem fonte, cuidados e etapas', () {
    final lib = libraryWithBundle();
    for (final s in lib.articles()) {
      final a = lib.article(s.id)!;
      expect(a.sources, isNotEmpty, reason: s.id);
      expect(a.cautions, isNotEmpty, reason: s.id);
      expect(a.steps, isNotEmpty, reason: s.id);
    }
  });

  test('reimportar a mesma versão não altera nada', () {
    final lib = libraryWithBundle();
    final r = lib.importPackage(loadBundle(), mediaInFiles: false);
    expect(r.inserted + r.updated, 0);
    expect(r.skipped, lib.articleCount);
  });

  test('atualização substitui conteúdo sem tocar dados do usuário', () {
    final lib = libraryWithBundle();
    final user = UserDatabase.inMemory();
    user.setFavorite('ps-engasgo', true);
    user.saveNote('ps-engasgo', 'Curso de primeiros socorros em março');
    user.createChecklist('Minha lista', 'personalizada', [('Lanterna', null)]);

    final pkg = clone(loadBundle());
    pkg['package']['version'] = 2;
    final articles = pkg['articles'] as List;
    final eng = articles.firstWhere((a) => a['id'] == 'ps-engasgo') as Map<String, dynamic>;
    eng['version'] = 2;
    eng['title'] = 'Engasgo: desobstrução das vias aéreas (rev. 2)';
    final r = lib.importPackage(pkg, mediaInFiles: true);

    expect(r.updated, 1);
    expect(lib.article('ps-engasgo')!.title, contains('rev. 2'));
    expect(lib.libraryVersion, 2);
    expect(user.isFavorite('ps-engasgo'), isTrue);
    expect(user.note('ps-engasgo'), contains('março'));
    expect(user.checklists().single.title, 'Minha lista');
  });

  test('versão mais antiga não sobrescreve versão mais nova', () {
    final lib = libraryWithBundle();
    final newer = clone(loadBundle());
    (newer['articles'] as List).first['version'] = 5;
    (newer['articles'] as List).first['title'] = 'Novo';
    lib.importPackage(newer, mediaInFiles: true);
    final id = (newer['articles'] as List).first['id'] as String;
    final older = clone(loadBundle());
    (older['articles'] as List).first['version'] = 3;
    lib.importPackage(older, mediaInFiles: true);
    expect(lib.article(id)!.title, 'Novo');
  });

  test('falha no meio da importação desfaz tudo (transação)', () {
    final lib = libraryWithBundle();
    final before = lib.article('urb-enchente')!.title;
    final pkg = clone(loadBundle());
    pkg['package']['version'] = 9;
    final articles = pkg['articles'] as List;
    final i = articles.indexWhere((a) => a['id'] == 'urb-enchente');
    articles[i]['version'] = 9;
    articles[i]['title'] = 'Título que não deve ficar';
    articles.add({'id': 'quebrado', 'version': 9}); // sem título: inválido
    expect(() => lib.importPackage(pkg, mediaInFiles: true), throwsA(isA<PackageFormatException>()));
    expect(lib.article('urb-enchente')!.title, before);
    expect(lib.libraryVersion, 1);
    expect(lib.packages().single.version, 1);
  });

  test('formato futuro é recusado', () {
    final lib = libraryWithBundle();
    final pkg = clone(loadBundle());
    pkg['format'] = 99;
    expect(() => lib.importPackage(pkg, mediaInFiles: true), throwsA(isA<PackageFormatException>()));
  });
}
