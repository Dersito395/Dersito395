import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sobreviva/app.dart';
import 'package:sobreviva/state/app_state.dart';

import 'helpers.dart';

Future<AppState> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final state = testState();
  await tester.pumpWidget(ChangeNotifierProvider.value(value: state, child: const SobrevivaApp()));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('tela inicial mostra busca, indicador offline e navegação', (tester) async {
    await pumpApp(tester);
    expect(find.text('O que você precisa saber?'), findsOneWidget);
    expect(find.text('Offline • biblioteca disponível'), findsOneWidget);
    expect(find.text('Cenários de crise'), findsWidgets);
    expect(find.text('Escassez de alimentos'), findsOneWidget);
    for (final label in ['Início', 'Explorar', 'Emergências', 'Salvos', 'Ajustes']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('pesquisa e abre um artigo, salva como favorito', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.text('O que você precisa saber?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abrigo na chuva');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Como montar um abrigo improvisado com lona'), findsOneWidget);
    await tester.tap(find.text('Como montar um abrigo improvisado com lona'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('INSTRUÇÕES'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('INSTRUÇÕES'), findsOneWidget);
    await tester.tap(find.byTooltip('Salvar'));
    await tester.pump();
    expect(state.isFavorite('abrigo-lona-improvisado'), isTrue);
    expect(state.user.history().first.articleId, 'abrigo-lona-improvisado');
    expect(state.user.searchHistory(), contains('abrigo na chuva'));
  });

  testWidgets('central de emergências abre guia com 5 seções', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Emergências').last);
    await tester.pumpAndSettle();
    expect(find.text('192'), findsWidgets);
    await tester.tap(find.text('Engasgo').first);
    await tester.pumpAndSettle();
    for (final s in ['Como reconhecer', 'Segurança imediata', 'O que fazer', 'O que evitar', 'Quando e como pedir socorro']) {
      await tester.scrollUntilVisible(find.text(s), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text(s), findsOneWidget);
    }
    expect(find.text('Ligar 192 • SAMU'), findsOneWidget);
  });

  testWidgets('planejador gera checklist de mochila', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.text('Salvos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planejar mochila'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar lista'));
    await tester.pumpAndSettle();
    final lists = state.user.checklists();
    expect(lists.single.kind, 'mochila');
    expect(lists.single.total, greaterThan(15));
  });

  testWidgets('ajustes: modo externo e tamanho de fonte persistem', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo ambiente externo'));
    await tester.pumpAndSettle();
    expect(state.outdoorMode, isTrue);
    expect(state.user.pref('outdoor'), '1');
  });

  testWidgets('cenário abre roteiro por fases e gera plano', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.text('Escassez de alimentos'));
    await tester.pumpAndSettle();
    expect(find.text('Preparação'), findsOneWidget);
    await tester.tap(find.text('Criar meu plano'));
    await tester.pumpAndSettle();
    final plan = state.user.checklists().single;
    expect(plan.title, contains('Escassez de alimentos'));
    expect(plan.total, greaterThan(10));
  });
}
