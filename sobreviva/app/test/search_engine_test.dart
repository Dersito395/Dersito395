import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sobreviva/core/text_normalizer.dart';
import 'package:sobreviva/data/library_db.dart';
import 'package:sobreviva/search/search_engine.dart';

void main() {
  late LibraryDatabase lib;
  late SearchEngine engine;

  setUpAll(() {
    lib = LibraryDatabase.inMemory();
    final pkg = jsonDecode(File('assets/content/essencial.json').readAsStringSync()) as Map<String, dynamic>;
    lib.importPackage(pkg, mediaInFiles: false);
    engine = SearchEngine(lib);
  });

  List<String> top(String q, [int n = 3]) => engine.search(q).results.take(n).map((r) => r.article.id).toList();

  group('normalização', () {
    test('remove acentos e pontuação', () {
      expect(normalize('Água potável? Não!'), 'agua potavel nao');
      expect(editDistance('bussula', 'bussola'), 1);
      expect(editDistance('aguaa', 'agua'), 1);
      expect(editDistance('ferver', 'fevrer'), 1); // transposição
    });
  });

  group('consultas comuns da especificação', () {
    test('Estou perdido na mata.', () => expect(top('Estou perdido na mata.'), contains('orient-perdido-na-mata')));
    test('Como montar um abrigo na chuva?', () => expect(top('Como montar um abrigo na chuva?').first, 'abrigo-lona-improvisado'));
    test('Não tenho água potável.', () => expect(top('Não tenho água potável.'), contains('agua-tornar-potavel')));
    test('Como utilizar uma bússola?', () => expect(top('Como utilizar uma bússola?').first, 'orient-bussola-mapa'));
    test('O que fazer após uma picada de cobra?', () => expect(top('O que fazer após uma picada de cobra?').first, 'ps-animais-peconhentos'));
  });

  group('crise prolongada', () {
    test('guerra', () => expect(top('o que fazer numa guerra'), contains('cen-conflito-armado')));
    test('pandemia', () => expect(top('pandemia').first, 'cen-pandemia-quarentena'));
    test('plantar meu alimento', () => expect(top('preciso plantar meu alimento'), contains('prod-horta-passo-a-passo')));
    test('roubo de mantimentos', () => expect(top('proteger meus mantimentos de roubo').first, 'seg-protecao-mantimentos'));
    test('arma leva ao artigo de defesa legal', () => expect(top('como fazer uma arma').first, 'seg-defesa-legal'));
    test('estocar comida por meses', () => expect(top('estocar comida por meses').first, 'alim-despensa-longo-prazo'));
    test('escassez de água', () => expect(top('escassez de água'), contains('agua-escassez-racionamento')));
  });

  group('sinônimos', () {
    test('purificar água encontra tratamento/desinfecção', () => expect(top('purificar água').first, 'agua-tornar-potavel'));
    test('blecaute encontra apagão', () => expect(top('blecaute'), contains('urb-apagao')));
    test('heimlich encontra engasgo', () => expect(top('heimlich').first, 'ps-engasgo'));
    test('massagem cardíaca encontra RCP', () => expect(top('massagem cardíaca').first, 'ps-rcp-adulto'));
    test('inundação encontra enchente', () => expect(top('inundação').first, 'urb-enchente'));
  });

  group('correção de digitação', () {
    test('bussula → bússola', () {
      final o = engine.search('bussula');
      expect(o.results.first.article.id, 'orient-bussola-mapa');
      expect(o.correctedQuery, isNotNull);
    });
    test('hipotermya', () => expect(top('hipotermya').first, 'ps-hipotermia'));
    test('queimadra', () => expect(top('queimadra').first, 'ps-queimaduras'));
    test('enchnte', () => expect(top('enchnte').first, 'urb-enchente'));
  });

  group('filtros e autocompletar', () {
    test('filtro por categoria', () {
      final r = engine.search('água', filters: const SearchFilters(category: 'agua'));
      expect(r.results, isNotEmpty);
      expect(r.results.every((x) => x.article.categoryId == 'agua'), isTrue);
    });
    test('filtro por dificuldade sem texto', () {
      final r = engine.search('', filters: const SearchFilters(difficulty: 'intermediaria'));
      expect(r.results.every((x) => x.article.difficulty == 'intermediaria'), isTrue);
    });
    test('filtro por ambiente', () {
      final r = engine.search('abrigo', filters: const SearchFilters(environment: 'mata'));
      expect(r.results.map((e) => e.article.id), contains('abrigo-lona-improvisado'));
    });
    test('autocompletar por título', () {
      final s = engine.suggest('bus');
      expect(s.any((x) => x.articleId == 'orient-bussola-mapa'), isTrue);
    });
    test('relacionados', () {
      final a = lib.article('abrigo-lona-improvisado')!;
      expect(engine.related(a).map((e) => e.id), contains('abrigo-terreno-isolamento'));
    });
  });
}
