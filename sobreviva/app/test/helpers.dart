import 'dart:convert';
import 'dart:io';

import 'package:sobreviva/data/library_db.dart';
import 'package:sobreviva/data/user_db.dart';
import 'package:sobreviva/services/package_service.dart';
import 'package:sobreviva/state/app_state.dart';

Map<String, dynamic> loadBundle() => jsonDecode(File('assets/content/essencial.json').readAsStringSync()) as Map<String, dynamic>;

LibraryDatabase libraryWithBundle() {
  final lib = LibraryDatabase.inMemory();
  lib.importPackage(loadBundle(), mediaInFiles: false);
  return lib;
}

/// Cópia profunda de um pacote para alterar em testes.
Map<String, dynamic> clone(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

AppState testState({bool withServer = false}) {
  final lib = libraryWithBundle();
  final tmp = Directory.systemTemp.createTempSync('sobreviva-ui');
  return AppState(
    library: lib,
    user: UserDatabase.inMemory(),
    mediaDir: Directory('${tmp.path}/media'),
    packages: PackageService(library: lib, mediaDir: Directory('${tmp.path}/media'), tempDir: tmp),
  );
}
