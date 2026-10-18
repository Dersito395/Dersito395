import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/library_db.dart';

/// Instala a biblioteca essencial embarcada no aplicativo.
///
/// Executado a cada abertura: só importa quando o pacote embarcado é mais novo
/// do que o instalado, o que garante funcionamento em modo avião desde o primeiro acesso.
class BundledContent {
  static const String assetPath = 'assets/content/essencial.json';

  static Future<ImportResult?> ensureInstalled(LibraryDatabase library, {AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final meta = (data['package'] as Map).cast<String, dynamic>();
    final installed = library.packages().where((p) => p.id == meta['id']).toList();
    if (installed.isNotEmpty && installed.first.version >= (meta['version'] as int)) return null;
    return library.importPackage(data, mediaInFiles: false, sizeBytes: raw.length);
  }
}
