import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../data/library_db.dart';
import '../data/models.dart';
import '../data/user_db.dart';
import '../search/search_engine.dart';
import '../services/package_service.dart';

/// Servidor de atualizações padrão (pode ser definido na compilação com
/// --dart-define=UPDATE_SERVER=https://...). Vazio = verificação desativada até o usuário configurar.
const String defaultUpdateServer = String.fromEnvironment('UPDATE_SERVER');

/// Estado global do aplicativo. As consultas ao SQLite são síncronas e rápidas;
/// as telas leem os dados diretamente e se reconstroem quando [notifyListeners] é chamado.
class AppState extends ChangeNotifier {
  AppState({required this.library, required this.user, required this.mediaDir, required this.packages, Stream<List<ConnectivityResult>>? connectivity})
    : search = SearchEngine(library) {
    _load();
    if (connectivity != null) {
      _connSub = connectivity.listen(_onConnectivity);
    }
  }

  final LibraryDatabase library;
  final UserDatabase user;
  final SearchEngine search;
  final Directory mediaDir;
  final PackageService packages;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // Preferências ---------------------------------------------------------------
  ThemeMode themeMode = ThemeMode.system;
  double fontScale = 1.0;
  bool outdoorMode = false;
  bool batterySaver = false;
  bool autoCheckUpdates = true;
  String updateServer = defaultUpdateServer;

  // Conectividade e atualizações -----------------------------------------------
  bool online = false;
  Manifest? manifest;
  DateTime? lastCheck;
  String? lastCheckError;

  void _load() {
    themeMode = switch (user.pref('theme')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    fontScale = double.tryParse(user.pref('font_scale') ?? '') ?? 1.0;
    outdoorMode = user.pref('outdoor') == '1';
    batterySaver = user.pref('battery_saver') == '1';
    autoCheckUpdates = user.pref('auto_check') != '0';
    updateServer = user.pref('update_server') ?? defaultUpdateServer;
    final lc = user.pref('last_check');
    lastCheck = lc == null ? null : DateTime.tryParse(lc);
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    user.setPref('theme', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
    notifyListeners();
  }

  void setFontScale(double v) {
    fontScale = v.clamp(0.85, 1.6);
    user.setPref('font_scale', fontScale.toStringAsFixed(2));
    notifyListeners();
  }

  void setOutdoorMode(bool v) {
    outdoorMode = v;
    user.setPref('outdoor', v ? '1' : '0');
    notifyListeners();
  }

  void setBatterySaver(bool v) {
    batterySaver = v;
    user.setPref('battery_saver', v ? '1' : '0');
    notifyListeners();
  }

  void setAutoCheck(bool v) {
    autoCheckUpdates = v;
    user.setPref('auto_check', v ? '1' : '0');
    notifyListeners();
  }

  void setUpdateServer(String v) {
    updateServer = v.trim();
    user.setPref('update_server', updateServer);
    manifest = null;
    notifyListeners();
  }

  // Dados pessoais ---------------------------------------------------------------

  bool isFavorite(String id) => user.isFavorite(id);

  void toggleFavorite(String id) {
    user.setFavorite(id, !user.isFavorite(id));
    notifyListeners();
  }

  void recordView(String id) {
    user.recordView(id);
    // Sem notifyListeners: evita reconstruções durante a navegação; a tela inicial
    // é atualizada ao voltar (ver HomeScreen).
  }

  void saveNote(String id, String text) {
    user.saveNote(id, text);
    notifyListeners();
  }

  /// Notifica as telas após mudanças feitas diretamente no banco do usuário.
  void touch() => notifyListeners();

  Map<String, String>? _categoryIcons;

  /// Nome do ícone de uma categoria (com cache; invalidado ao instalar pacotes).
  String categoryIcon(String categoryId) {
    _categoryIcons ??= {for (final c in library.categories()) c.id: c.icon};
    return _categoryIcons![categoryId] ?? 'menu_book';
  }

  // Imagens -------------------------------------------------------------------------

  /// Arquivo local de uma imagem baixada, ou null quando ela está embarcada no app.
  File? downloadedMedia(String file) {
    if (library.imageLocation(file) != 'file') return null;
    final f = File(p.join(mediaDir.path, file));
    return f.existsSync() ? f : null;
  }

  // Atualizações ------------------------------------------------------------------

  /// Atualiza o estado de conexão (também usado na verificação inicial).
  void updateConnectivity(List<ConnectivityResult> results) => _onConnectivity(results);

  void _onConnectivity(List<ConnectivityResult> results) {
    final wasOnline = online;
    online = results.any((r) => r != ConnectivityResult.none);
    notifyListeners();
    // Ao recuperar a conexão, verifica atualizações (no máximo a cada 6 horas).
    if (online && !wasOnline && autoCheckUpdates && !batterySaver && updateServer.isNotEmpty) {
      final recent = lastCheck != null && DateTime.now().difference(lastCheck!) < const Duration(hours: 6);
      if (!recent) unawaited(checkForUpdates().catchError((_) => null));
    }
  }

  Future<Manifest?> checkForUpdates() async {
    if (updateServer.isEmpty) {
      lastCheckError = 'Servidor de atualizações não configurado.';
      notifyListeners();
      return null;
    }
    try {
      manifest = await packages.fetchManifest(updateServer);
      lastCheckError = null;
      lastCheck = DateTime.now();
      user.setPref('last_check', lastCheck!.toIso8601String());
    } on PackageInstallException catch (e) {
      lastCheckError = e.message;
    } finally {
      notifyListeners();
    }
    return manifest;
  }

  /// Pacotes instalados com versão mais nova disponível no servidor.
  List<RemotePackage> get availableUpdates {
    final m = manifest;
    if (m == null) return const [];
    final installed = {for (final p in library.packages()) p.id: p.version};
    return [
      for (final r in m.packages)
        if (installed.containsKey(r.id) && installed[r.id]! < r.version) r,
    ];
  }

  Future<ImportResult> installPackage(RemotePackage pkg, {ProgressCallback? onProgress, CancelToken? cancel}) async {
    final result = await packages.install(updateServer, pkg, onProgress: onProgress, cancel: cancel);
    search.reload();
    _categoryIcons = null;
    notifyListeners();
    return result;
  }

  List<InstalledPackage> get installedPackages => library.packages();

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}
