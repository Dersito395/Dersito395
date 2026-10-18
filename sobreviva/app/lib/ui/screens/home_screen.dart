import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'category_screen.dart';
import 'emergency_screens.dart';
import 'search_screen.dart';
import 'settings_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Troca a aba da navegação inferior (1 = Explorar, 2 = Emergências, 3 = Salvos).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final lib = state.library;
    final categories = lib.categories();
    final emergencies = lib.emergencies();
    final recent = lib.summaries(state.user.history(limit: 5).map((h) => h.articleId).toList());
    final favorites = lib.summaries(state.user.favoriteIds().take(5).toList());
    final featured = lib.featured();
    final updates = state.availableUpdates;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset('assets/brand/logo.svg', width: 44, height: 44, semanticsLabel: 'Logo SOBREVIVA'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SOBREVIVA', style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900)),
                              Text(
                                'Biblioteca de Campo',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const OfflineIndicator(),
                    const SizedBox(height: 16),
                    _SearchLauncher(onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()))),
                    if (updates.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: theme.colorScheme.secondaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.system_update_outlined),
                          title: Text('${updates.length} pacote(s) com atualização'),
                          subtitle: const Text('Seus favoritos e anotações são preservados.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PackagesScreen())),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader('O que fazer agora?', icon: Icons.emergency_outlined, action: 'Ver todas', onAction: () => onOpenTab(2)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverToBoxAdapter(child: const EmergencyNumbersCard(compact: true)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: textScale > 1.05 ? 1 : 2,
                  mainAxisExtent: 24 + 40 * textScale,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: emergencies.length.clamp(0, 6),
                itemBuilder: (context, i) {
                  final e = emergencies[i];
                  return _EmergencyButton(
                    title: e.title,
                    icon: iconFor(e.icon),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EmergencyGuideScreen(guideId: e.id))),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader('Categorias', icon: Icons.grid_view, action: 'Biblioteca', onAction: () => onOpenTab(1)),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64 + 44 * textScale,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return SizedBox(
                      width: 72 + 36 * textScale,
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CategoryScreen(categoryId: c.id))),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(iconFor(c.icon), color: theme.colorScheme.primary, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  c.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (recent.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader('Acessados recentemente', icon: Icons.history)),
              SliverList.list(children: [for (final a in recent.take(3)) ArticleTile(a)]),
            ],
            if (favorites.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader('Favoritos', icon: Icons.bookmark_outline, action: 'Todos', onAction: () => onOpenTab(3)),
              ),
              SliverList.list(children: [for (final a in favorites.take(3)) ArticleTile(a)]),
            ],
            const SliverToBoxAdapter(child: SectionHeader('Guias práticos em destaque', icon: Icons.auto_stories_outlined)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 210,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final a = featured[i];
                    return SizedBox(
                      width: 230,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => openArticle(context, a.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 400 / 260,
                                child: LibraryImage(a.coverImage!, fit: BoxFit.cover),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  a.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () => onOpenTab(1),
                        icon: const Icon(Icons.local_library_outlined),
                        label: Text('Abrir biblioteca completa (${lib.articleCount} artigos)'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const DisclaimerBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchLauncher extends StatelessWidget {
  const _SearchLauncher({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Pesquisar: O que você precisa saber?',
      child: Material(
        color: dark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.search, color: theme.colorScheme.primary, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'O que você precisa saber?',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
