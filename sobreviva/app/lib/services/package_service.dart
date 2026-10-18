import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../data/library_db.dart';

class RemotePackage {
  const RemotePackage({
    required this.id,
    required this.title,
    required this.description,
    required this.version,
    required this.releasedAt,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
    required this.articleCount,
    required this.mediaCount,
    required this.format,
    required this.bundled,
  });

  final String id;
  final String title;
  final String description;
  final int version;
  final String? releasedAt;
  final String url;
  final int sizeBytes;
  final String sha256;
  final int articleCount;
  final int mediaCount;
  final int format;
  final bool bundled;

  factory RemotePackage.fromJson(Map<String, dynamic> j) {
    final id = j['id'], version = j['version'], url = j['url'], size = j['size_bytes'], sha = j['sha256'];
    if (id is! String || version is! int || url is! String || size is! int || sha is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha)) {
      throw const FormatException('Manifesto com pacote inválido.');
    }
    return RemotePackage(
      id: id,
      title: (j['title'] as String?) ?? id,
      description: (j['description'] as String?) ?? '',
      version: version,
      releasedAt: j['released_at'] as String?,
      url: url,
      sizeBytes: size,
      sha256: sha,
      articleCount: (j['article_count'] as int?) ?? 0,
      mediaCount: (j['media_count'] as int?) ?? 0,
      format: (j['format'] as int?) ?? 1,
      bundled: j['bundled'] == true,
    );
  }
}

class Manifest {
  const Manifest({required this.libraryVersion, required this.generatedAt, required this.packages});
  final int libraryVersion;
  final String? generatedAt;
  final List<RemotePackage> packages;
}

class DownloadCancelled implements Exception {
  @override
  String toString() => 'Download cancelado.';
}

class PackageInstallException implements Exception {
  PackageInstallException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Permite cancelar um download em andamento.
class CancelToken {
  bool _cancelled = false;
  http.Client? _client;
  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _client?.close();
  }
}

typedef ProgressCallback = void Function(int received, int total, String stage);

/// Serviço de atualização de conteúdo.
///
/// Garantias:
///  - verificação de tamanho e SHA-256 do pacote e de cada imagem;
///  - verificação de formato e de correspondência com o manifesto;
///  - importação em transação única (falhas não alteram a biblioteca);
///  - imagens gravadas em área temporária e movidas só após o sucesso da importação;
///  - favoritos, notas e listas ficam em outro banco e nunca são tocados.
class PackageService {
  PackageService({required this.library, required this.mediaDir, required this.tempDir, http.Client Function()? clientFactory, this.freeSpace})
    : _clientFactory = clientFactory ?? http.Client.new;

  final LibraryDatabase library;
  final Directory mediaDir;
  final Directory tempDir;
  final http.Client Function() _clientFactory;

  /// Espaço livre em bytes (null = desconhecido).
  final Future<int?> Function()? freeSpace;

  static Uri resolve(String baseUrl, String path) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(base).resolve(path);
  }

  static void _checkScheme(Uri uri) {
    final local = uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '10.0.2.2' || uri.host.startsWith('192.168.');
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && local)) {
      throw PackageInstallException('Use um endereço HTTPS para o servidor de atualizações.');
    }
  }

  Future<Manifest> fetchManifest(String baseUrl, {Duration timeout = const Duration(seconds: 15)}) async {
    final uri = resolve(baseUrl, 'manifest.json');
    _checkScheme(uri);
    final client = _clientFactory();
    try {
      final res = await client.get(uri).timeout(timeout);
      if (res.statusCode != 200) throw PackageInstallException('Servidor respondeu ${res.statusCode}.');
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (j['format'] is! int || (j['format'] as int) > supportedPackageFormat) {
        throw PackageInstallException('O servidor usa um formato mais novo. Atualize o aplicativo.');
      }
      return Manifest(
        libraryVersion: (j['library_version'] as int?) ?? 0,
        generatedAt: j['generated_at'] as String?,
        packages: [for (final p in (j['packages'] as List)) RemotePackage.fromJson((p as Map).cast<String, dynamic>())],
      );
    } on SocketException {
      throw PackageInstallException('Sem conexão com o servidor de atualizações.');
    } on TimeoutException {
      throw PackageInstallException('O servidor demorou para responder.');
    } on FormatException {
      throw PackageInstallException('Manifesto de atualização inválido.');
    } finally {
      client.close();
    }
  }

  Future<ImportResult> install(String baseUrl, RemotePackage pkg, {ProgressCallback? onProgress, CancelToken? cancel}) async {
    if (pkg.format > supportedPackageFormat) throw PackageInstallException('Pacote requer uma versão mais nova do aplicativo.');
    final free = await freeSpace?.call();
    // Espaço para o download, as imagens decodificadas e o crescimento do banco.
    if (free != null && free < pkg.sizeBytes * 3) {
      throw PackageInstallException('Espaço insuficiente: são necessários cerca de ${(pkg.sizeBytes * 3 / 1048576).toStringAsFixed(1)} MB livres.');
    }
    final uri = resolve(baseUrl, pkg.url);
    _checkScheme(uri);

    final bytes = await _download(uri, pkg.sizeBytes, onProgress, cancel);
    onProgress?.call(bytes.length, pkg.sizeBytes, 'verificando');
    if (bytes.length != pkg.sizeBytes) throw PackageInstallException('Download incompleto (${bytes.length} de ${pkg.sizeBytes} bytes).');
    final digest = sha256.convert(bytes).toString();
    if (digest != pkg.sha256) throw PackageInstallException('Falha na verificação de integridade (SHA-256). O pacote foi descartado.');
    if (cancel?.isCancelled ?? false) throw DownloadCancelled();

    final Map<String, dynamic> data;
    try {
      data = await Isolate.run(() => jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
    } on FormatException {
      throw PackageInstallException('Pacote corrompido (JSON inválido).');
    }
    final meta = (data['package'] as Map?)?.cast<String, dynamic>();
    if (meta == null || meta['id'] != pkg.id || meta['version'] != pkg.version) {
      throw PackageInstallException('O conteúdo do pacote não corresponde ao manifesto.');
    }

    onProgress?.call(bytes.length, pkg.sizeBytes, 'instalando');
    final staging = Directory(p.join(tempDir.path, 'staging-${pkg.id}-${DateTime.now().microsecondsSinceEpoch}'));
    await staging.create(recursive: true);
    try {
      final staged = <String>[];
      for (final raw in (data['media'] as List? ?? const [])) {
        final m = (raw as Map).cast<String, dynamic>();
        final file = m['file'];
        final b64 = m['data'];
        if (file is! String || !RegExp(r'^[a-z0-9][a-z0-9-]*\.(svg|webp|avif|png|jpe?g)$').hasMatch(file)) {
          throw PackageInstallException('Nome de imagem inválido no pacote.');
        }
        if (b64 is! String) continue;
        final content = base64Decode(b64);
        if (sha256.convert(content).toString() != m['sha256']) throw PackageInstallException('Imagem $file falhou na verificação de integridade.');
        await File(p.join(staging.path, file)).writeAsBytes(content, flush: true);
        staged.add(file);
      }
      data['media'] = [
        for (final raw in (data['media'] as List? ?? const [])) {...(raw as Map).cast<String, dynamic>()..remove('data')},
      ];
      if (cancel?.isCancelled ?? false) throw DownloadCancelled();

      // A partir daqui a operação não é mais cancelável: a transação garante atomicidade.
      final result = library.importPackage(data, mediaInFiles: true, sizeBytes: pkg.sizeBytes);
      await mediaDir.create(recursive: true);
      for (final file in staged) {
        await File(p.join(staging.path, file)).rename(p.join(mediaDir.path, file));
      }
      onProgress?.call(bytes.length, pkg.sizeBytes, 'concluido');
      return result;
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  Future<List<int>> _download(Uri uri, int expected, ProgressCallback? onProgress, CancelToken? cancel) async {
    final client = _clientFactory();
    cancel?._client = client;
    final buffer = BytesBuilder(copy: false);
    try {
      final res = await client.send(http.Request('GET', uri)).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw PackageInstallException('Servidor respondeu ${res.statusCode}.');
      await for (final chunk in res.stream) {
        if (cancel?.isCancelled ?? false) throw DownloadCancelled();
        buffer.add(chunk);
        if (buffer.length > expected) throw PackageInstallException('Pacote maior que o informado no manifesto.');
        onProgress?.call(buffer.length, expected, 'baixando');
      }
      return buffer.takeBytes();
    } on http.ClientException {
      if (cancel?.isCancelled ?? false) throw DownloadCancelled();
      throw PackageInstallException('Conexão interrompida durante o download.');
    } on SocketException {
      if (cancel?.isCancelled ?? false) throw DownloadCancelled();
      throw PackageInstallException('Conexão interrompida durante o download.');
    } on TimeoutException {
      throw PackageInstallException('O servidor demorou para responder.');
    } finally {
      client.close();
    }
  }
}
