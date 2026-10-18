import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme.dart';
import 'data/library_db.dart';
import 'data/user_db.dart';
import 'services/bundled_content.dart';
import 'services/package_service.dart';
import 'services/storage_info.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

/// Abre os bancos locais e instala a biblioteca essencial embarcada (sem rede).
Future<AppState> bootstrap() async {
  final support = await getApplicationSupportDirectory();
  final temp = await getTemporaryDirectory();
  final dataDir = Directory(p.join(support.path, 'sobreviva'));
  await dataDir.create(recursive: true);
  final mediaDir = Directory(p.join(dataDir.path, 'media'));

  final library = LibraryDatabase.open(p.join(dataDir.path, 'library.db'));
  final user = UserDatabase.open(p.join(dataDir.path, 'user.db'));
  await BundledContent.ensureInstalled(library);

  final connectivity = Connectivity();
  final state = AppState(
    library: library,
    user: user,
    mediaDir: mediaDir,
    packages: PackageService(library: library, mediaDir: mediaDir, tempDir: temp, freeSpace: StorageInfo.freeBytes),
    connectivity: connectivity.onConnectivityChanged,
  );
  connectivity.checkConnectivity().then(state.updateConnectivity).ignore();
  return state;
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<AppState> _future = bootstrap();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) {
          return ChangeNotifierProvider<AppState>.value(value: snap.data!, child: const SobrevivaApp());
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(ThemeVariant.light),
          home: Scaffold(
            backgroundColor: Palette.darkGreen,
            body: Center(
              child: snap.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Não foi possível abrir a biblioteca local.',
                            style: TextStyle(color: Palette.white, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snap.error}',
                            style: const TextStyle(color: Palette.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: () => setState(() => _future = bootstrap()), child: const Text('Tentar novamente')),
                        ],
                      ),
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SOBREVIVA',
                          style: TextStyle(color: Palette.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4),
                        ),
                        SizedBox(height: 4),
                        Text('Biblioteca de Campo', style: TextStyle(color: Palette.white, letterSpacing: 1.5)),
                        SizedBox(height: 24),
                        CircularProgressIndicator(color: Palette.safetyOrange),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
