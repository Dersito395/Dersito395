import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'state/app_state.dart';
import 'ui/screens/category_screen.dart';
import 'ui/screens/emergency_screens.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/saved_screen.dart';
import 'ui/screens/settings_screens.dart';

class SobrevivaApp extends StatelessWidget {
  const SobrevivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ThemeData light;
    final ThemeData dark;
    if (state.batterySaver) {
      light = dark = buildTheme(ThemeVariant.batterySaver);
    } else if (state.outdoorMode) {
      light = dark = buildTheme(ThemeVariant.outdoor);
    } else {
      light = buildTheme(ThemeVariant.light);
      dark = buildTheme(ThemeVariant.dark);
    }
    final scale = state.fontScale * (state.outdoorMode ? 1.12 : 1.0);
    return MaterialApp(
      title: 'SOBREVIVA',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: state.batterySaver ? ThemeMode.dark : (state.outdoorMode ? ThemeMode.light : state.themeMode),
      themeAnimationDuration: state.batterySaver ? Duration.zero : const Duration(milliseconds: 200),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear((mq.textScaler.scale(1) * scale).clamp(0.8, 2.2)),
            disableAnimations: state.batterySaver || mq.disableAnimations,
          ),
          child: child!,
        );
      },
      home: const HomeShell(),
    );
  }
}

/// Navegação inferior: Início | Explorar | Emergências | Salvos | Ajustes.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _open(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenTab: _open),
          const ExploreScreen(),
          const EmergencyCenterScreen(),
          const SavedScreen(),
          const SettingsScreen(),
        ],
      ),
      // Rótulos da navegação com escala limitada para não quebrar em telas pequenas.
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.0,
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _open,
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
            const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorar'),
            NavigationDestination(
              icon: Icon(Icons.emergency_outlined, color: theme.colorScheme.error),
              selectedIcon: Icon(Icons.emergency, color: theme.colorScheme.error),
              label: 'Emergências',
            ),
            const NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Salvos'),
            const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
          ],
        ),
      ),
    );
  }
}
