import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sobreviva/data/user_db.dart';
import 'package:sobreviva/services/package_service.dart';

import 'helpers.dart';

const base = 'https://atualizacoes.exemplo.org/api/v1/';
final distDir = Directory('../server/dist/updates');

http.Response _file(String rel) {
  final f = File('${distDir.path}/$rel');
  return f.existsSync() ? http.Response.bytes(f.readAsBytesSync(), 200) : http.Response('not found', 404);
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('sobreviva'));
  tearDown(() => tmp.deleteSync(recursive: true));

  PackageService service(MockClient client, {int? free}) {
    final lib = libraryWithBundle();
    return PackageService(library: lib, mediaDir: Directory('${tmp.path}/media'), tempDir: tmp, clientFactory: () => client, freeSpace: () async => free);
  }

  final okClient = MockClient((req) async => _file(req.url.path.replaceFirst('/api/v1/', '')));

  test('manifesto lista pacotes com tamanho, versão e hash', () async {
    final m = await service(okClient).fetchManifest(base);
    expect(m.packages.map((p) => p.id), containsAll(['essencial', 'biblioteca-completa', 'primeiros-socorros']));
    expect(m.packages.every((p) => p.sizeBytes > 0 && p.sha256.length == 64), isTrue);
  });

  test('instala a biblioteca completa e grava imagens verificadas', () async {
    final s = service(okClient);
    final user = UserDatabase.inMemory()..setFavorite('ps-rcp-adulto', true);
    final before = s.library.articleCount;
    final m = await s.fetchManifest(base);
    final full = m.packages.firstWhere((p) => p.id == 'biblioteca-completa');
    final stages = <String>{};
    final r = await s.install(base, full, onProgress: (_, _, stage) => stages.add(stage));
    expect(s.library.articleCount, greaterThan(before));
    expect(r.inserted, s.library.articleCount - before);
    expect(stages, containsAll(['baixando', 'verificando', 'instalando', 'concluido']));
    expect(File('${tmp.path}/media/abrigo-lona-a.svg').existsSync(), isTrue);
    expect(s.library.imageLocation('abrigo-lona-a.svg'), 'file');
    expect(user.isFavorite('ps-rcp-adulto'), isTrue);
    expect(tmp.listSync().whereType<Directory>().where((d) => d.path.contains('staging')), isEmpty);
  });

  test('pacote adulterado é rejeitado e a biblioteca permanece intacta', () async {
    final tampered = MockClient((req) async {
      final res = _file(req.url.path.replaceFirst('/api/v1/', ''));
      if (!req.url.path.endsWith('.json') || req.url.path.endsWith('manifest.json')) return res;
      final bytes = List<int>.from(res.bodyBytes);
      bytes[bytes.length ~/ 2] ^= 0x01; // altera 1 bit
      return http.Response.bytes(bytes, 200);
    });
    final s = service(tampered);
    final before = s.library.articleCount;
    final m = await s.fetchManifest(base);
    final full = m.packages.firstWhere((p) => p.id == 'biblioteca-completa');
    await expectLater(s.install(base, full), throwsA(isA<PackageInstallException>()));
    expect(s.library.articleCount, before);
    expect(s.library.packages().map((p) => p.id), ['essencial']);
  });

  test('download interrompido não altera a biblioteca', () async {
    final truncated = MockClient((req) async {
      final res = _file(req.url.path.replaceFirst('/api/v1/', ''));
      if (req.url.path.endsWith('manifest.json')) return res;
      return http.Response.bytes(res.bodyBytes.sublist(0, res.bodyBytes.length ~/ 2), 200);
    });
    final s = service(truncated);
    final m = await s.fetchManifest(base);
    await expectLater(s.install(base, m.packages.firstWhere((p) => p.id == 'navegacao')), throwsA(isA<PackageInstallException>()));
    expect(s.library.packages().length, 1);
  });

  test('cancelamento interrompe sem alterar nada', () async {
    final s = service(okClient);
    final m = await s.fetchManifest(base);
    final token = CancelToken()..cancel();
    await expectLater(s.install(base, m.packages.firstWhere((p) => p.id == 'navegacao'), cancel: token), throwsA(isA<DownloadCancelled>()));
    expect(s.library.packages().length, 1);
  });

  test('espaço insuficiente impede o download', () async {
    final s = service(okClient, free: 1000);
    final m = await s.fetchManifest(base);
    await expectLater(s.install(base, m.packages.first), throwsA(isA<PackageInstallException>()));
  });

  test('exige HTTPS fora da rede local', () async {
    await expectLater(service(okClient).fetchManifest('http://exemplo.org/'), throwsA(isA<PackageInstallException>()));
  });

  test('manifesto com formato futuro é recusado', () async {
    final future = MockClient((_) async => http.Response(jsonEncode({'format': 99, 'packages': []}), 200));
    await expectLater(service(future).fetchManifest(base), throwsA(isA<PackageInstallException>()));
  });
}
