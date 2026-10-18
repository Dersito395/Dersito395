// Gera capturas de tela das telas principais com fontes reais.
// Uso: SCREENSHOTS=1 flutter test test/screenshots/  (saída em build/screenshots/)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sobreviva/app.dart';
import 'package:sobreviva/state/app_state.dart';

import '../helpers.dart';

final _enabled = Platform.environment['SCREENSHOTS'] == '1';

Future<void> _loadFonts() async {
  final fontsDir = '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black', 'Light']) {
    final f = File('$fontsDir/Roboto-$w.ttf');
    if (f.existsSync()) roboto.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('$fontsDir/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/screenshots/$name.png')..createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<AppState> _pump(WidgetTester tester, {void Function(AppState)? configure}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final state = testState();
  configure?.call(state);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('shot'),
      child: ChangeNotifierProvider.value(value: state, child: const SobrevivaApp()),
    ),
  );
  // Pré-carrega as imagens SVG antes da captura.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  testWidgets('capturas', (tester) async {
    final state = await _pump(
      tester,
      configure: (s) {
        s.user.recordView('ps-engasgo');
        s.user.setFavorite('abrigo-lona-improvisado', true);
      },
    );
    await _shot(tester, '01-inicio');

    await tester.tap(find.text('O que você precisa saber?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nao tenho agua potavel');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _shot(tester, '02-pesquisa');
    await tester.enterText(find.byType(TextField), 'bussula');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _shot(tester, '03-pesquisa-correcao');

    await tester.tap(find.text('Como utilizar uma bússola com mapa'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await _shot(tester, '04-artigo-topo');
    await tester.scrollUntilVisible(find.text('INSTRUÇÕES'), 300, scrollable: find.byType(Scrollable).last);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await _shot(tester, '05-artigo-instrucoes');
    await tester.scrollUntilVisible(find.text('FONTES'), 400, scrollable: find.byType(Scrollable).last);
    await _shot(tester, '06-artigo-fontes');
    Navigator.of(tester.element(find.text('FONTES'))).popUntil((r) => r.isFirst);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Emergências').last);
    await _shot(tester, '07-emergencias');
    await tester.scrollUntilVisible(find.text('Animais peçonhentos'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Animais peçonhentos'));
    await _shot(tester, '08-guia-emergencia');
    Navigator.of(tester.element(find.text('Como reconhecer'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explorar').last);
    await _shot(tester, '09-explorar');
    await tester.tap(find.text('Primeiros socorros'));
    await _shot(tester, '10-categoria');
    Navigator.of(tester.element(find.text('Todos (8)'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planejar mochila'));
    await _shot(tester, '11-planejador');
    await tester.tap(find.text('Gerar lista'));
    await _shot(tester, '12-checklist');
    Navigator.of(tester.element(find.byType(LinearProgressIndicator))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajustes').last);
    await _shot(tester, '13-ajustes');
    await tester.tap(find.text('Pacotes e atualizações'));
    await _shot(tester, '14-pacotes');
    Navigator.of(tester.element(find.text('Instalados'))).pop();
    await tester.pumpAndSettle();

    state.setThemeMode(ThemeMode.dark);
    await tester.tap(find.text('Início').last);
    await _shot(tester, '15-inicio-escuro');
    state.setThemeMode(ThemeMode.light);
    state.setOutdoorMode(true);
    await tester.pumpAndSettle();
    await _shot(tester, '16-inicio-externo');
  }, skip: !_enabled);
}
