import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'search_screen.dart';

/// Aba "Explorar": todas as categorias da biblioteca.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final categories = state.library.categories();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          IconButton(
            tooltip: 'Pesquisar',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('${state.library.articleCount} artigos em ${categories.length} categorias, disponíveis sem internet.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                    child: Icon(iconFor(c.icon), color: theme.colorScheme.onPrimary),
                  ),
                  title: Text(c.name, style: theme.textTheme.titleMedium),
                  subtitle: Text('${c.description}\n${c.articleCount} artigo(s)', maxLines: 3),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CategoryScreen(categoryId: c.id))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});
  final String categoryId;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String? _sub;
  String? _difficulty;
  String? _environment;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final cat = state.library.categories().firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => const Category(id: '', name: 'Categoria', icon: '', description: '', subcategories: []),
    );
    final articles = state.library.articles(category: widget.categoryId, subcategory: _sub, difficulty: _difficulty, environment: _environment);
    final usedSubs = state.library.articles(category: widget.categoryId).length;

    return Scaffold(
      appBar: AppBar(title: Text(cat.name)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(cat.description, style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(label: Text('Todos ($usedSubs)'), selected: _sub == null, onSelected: (_) => setState(() => _sub = null)),
                ),
                for (final s in cat.subcategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(label: Text(s.name), selected: _sub == s.id, onSelected: (v) => setState(() => _sub = v ? s.id : null)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                _FilterMenu(label: 'Dificuldade', value: _difficulty, options: difficultyLabels, onChanged: (v) => setState(() => _difficulty = v)),
                _FilterMenu(
                  label: 'Ambiente',
                  value: _environment,
                  options: Map.fromEntries(environmentLabels.entries.where((e) => e.key != 'qualquer')),
                  onChanged: (v) => setState(() => _environment = v),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          if (articles.isEmpty)
            const EmptyState(
              icon: Icons.filter_alt_off_outlined,
              title: 'Nenhum artigo com esses filtros',
              message: 'Remova filtros ou baixe a biblioteca completa em Ajustes › Pacotes e atualizações.',
            ),
          for (final a in articles) ArticleTile(a),
        ],
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({required this.label, required this.value, required this.options, required this.onChanged});
  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: (v) => onChanged(v == '' ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: '', child: Text('Qualquer ${label.toLowerCase()}')),
        for (final e in options.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Chip(
        avatar: Icon(value == null ? Icons.filter_list : Icons.filter_alt, size: 18),
        label: Text(value == null ? label : '$label: ${options[value]}'),
      ),
    );
  }
}
