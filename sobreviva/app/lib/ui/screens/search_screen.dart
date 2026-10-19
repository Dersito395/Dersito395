import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../search/search_engine.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'reference_screens.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  SearchFilters _filters = const SearchFilters();
  SearchOutcome? _outcome;
  List<Suggestion> _suggestions = const [];
  bool _showSuggestions = true;

  static const _examples = [
    'Estou perdido na mata',
    'Como montar um abrigo na chuva?',
    'Não tenho água potável',
    'Como utilizar uma bússola?',
    'Picada de cobra',
    'Falta de energia',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit(widget.initialQuery!));
    } else {
      _refreshSuggestions();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  AppState get _state => context.read<AppState>();

  void _refreshSuggestions() {
    final history = _state.user.searchHistory();
    setState(() => _suggestions = _state.search.suggest(_controller.text, history: history));
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _showSuggestions = true;
      _refreshSuggestions();
      // Resultados ao vivo enquanto digita (pesquisa local é instantânea).
      setState(() => _outcome = text.trim().length >= 3 || !_filters.isEmpty ? _state.search.search(text, filters: _filters) : null);
    });
  }

  void _submit(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isNotEmpty) _state.user.addSearch(q);
    setState(() {
      _showSuggestions = false;
      _outcome = _state.search.search(q, filters: _filters);
    });
    _focus.unfocus();
  }

  void _useSuggestion(Suggestion s) {
    if (s.kind == SuggestionKind.article && s.articleId != null) {
      _state.user.addSearch(_controller.text.trim().isEmpty ? s.text : _controller.text);
      openArticle(context, s.articleId!);
      return;
    }
    _controller.text = s.text;
    _controller.selection = TextSelection.collapsed(offset: s.text.length);
    _submit(s.text);
  }

  void _setFilters(SearchFilters f) {
    setState(() {
      _filters = f;
      _outcome = _controller.text.trim().isEmpty && f.isEmpty ? null : _state.search.search(_controller.text, filters: f);
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: widget.initialQuery == null,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _submit,
          onTap: () => setState(() => _showSuggestions = true),
          decoration: InputDecoration(
            hintText: 'O que você precisa saber?',
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _outcome = _filters.isEmpty ? null : _state.search.search('', filters: _filters);
                        _showSuggestions = true;
                      });
                      _refreshSuggestions();
                      _focus.requestFocus();
                    },
                  ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filtros',
            icon: Badge(isLabelVisible: _filters.count > 0, label: Text('${_filters.count}'), child: const Icon(Icons.tune)),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final outcome = _outcome;
    final showSuggestions = _showSuggestions && _suggestions.isNotEmpty && _focus.hasFocus;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (!_filters.isEmpty) _ActiveFilters(filters: _filters, onChanged: _setFilters),
        if (showSuggestions) ...[
          for (final s in _suggestions)
            ListTile(
              dense: true,
              leading: Icon(switch (s.kind) {
                SuggestionKind.article => Icons.article_outlined,
                SuggestionKind.history => Icons.history,
                SuggestionKind.term => Icons.search,
              }),
              title: Text(s.text),
              trailing: s.kind == SuggestionKind.history
                  ? IconButton(
                      tooltip: 'Remover do histórico',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _state.user.removeSearch(s.text);
                        _refreshSuggestions();
                      },
                    )
                  : const Icon(Icons.north_west, size: 18),
              onTap: () => _useSuggestion(s),
            ),
          const Divider(),
        ],
        if (outcome == null && _controller.text.isEmpty) ...[
          const SectionHeader('Experimente perguntar', icon: Icons.lightbulb_outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _examples)
                  ActionChip(
                    label: Text(e),
                    onPressed: () {
                      _controller.text = e;
                      _submit(e);
                    },
                  ),
              ],
            ),
          ),
          if (_state.user.searchHistory().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  _state.user.clearSearchHistory();
                  _refreshSuggestions();
                },
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Limpar histórico de pesquisas'),
              ),
            ),
        ],
        if (outcome != null) ...[
          if (outcome.correctedQuery != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Mostrando resultados para '),
                    TextSpan(
                      text: outcome.correctedQuery,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              outcome.results.isEmpty ? 'Nenhum resultado' : '${outcome.results.length} resultado(s) na biblioteca local',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          if (outcome.expansions.isNotEmpty && outcome.results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Inclui termos relacionados: ${outcome.expansions.take(6).join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          if (outcome.results.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'Nada encontrado',
              message: 'Tente outras palavras, remova filtros ou baixe a biblioteca completa em Ajustes. Em uma emergência, ligue 192, 193 ou 190.',
            ),
          for (final r in outcome.results) ArticleTile(r.article),
          for (final d in _state.library.documentsFor(outcome.query, [for (final r in outcome.results.take(5)) r.article.id]))
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(d.title),
                subtitle: Text('Documento de consulta · ${d.pages} páginas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DocumentScreen(documentId: d.id))),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _openFilters() async {
    final cats = _state.library.categories();
    final result = await showModalBottomSheet<SearchFilters>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _FiltersSheet(initial: _filters, categories: cats),
    );
    if (result != null) _setFilters(result);
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filters, required this.onChanged});
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final cats = {for (final c in context.read<AppState>().library.categories()) c.id: c.name};
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 6,
        children: [
          if (filters.category != null)
            InputChip(label: Text(cats[filters.category] ?? filters.category!), onDeleted: () => onChanged(filters.copyWith(clearCategory: true))),
          if (filters.difficulty != null)
            InputChip(label: Text(difficultyLabels[filters.difficulty] ?? ''), onDeleted: () => onChanged(filters.copyWith(clearDifficulty: true))),
          if (filters.environment != null)
            InputChip(label: Text(environmentLabels[filters.environment] ?? ''), onDeleted: () => onChanged(filters.copyWith(clearEnvironment: true))),
        ],
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial, required this.categories});
  final SearchFilters initial;
  final List<Category> categories;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _cat = widget.initial.category;
  late String? _diff = widget.initial.difficulty;
  late String? _env = widget.initial.environment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget group(String title, Map<String, String> options, String? value, ValueChanged<String?> set) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(title, style: theme.textTheme.titleSmall),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final e in options.entries) ChoiceChip(label: Text(e.value), selected: value == e.key, onSelected: (s) => set(s ? e.key : null))],
        ),
      ],
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtrar resultados', style: theme.textTheme.titleLarge),
              group('Categoria', {for (final c in widget.categories) c.id: c.name}, _cat, (v) => setState(() => _cat = v)),
              group('Dificuldade', difficultyLabels, _diff, (v) => setState(() => _diff = v)),
              group('Tipo de ambiente', Map.fromEntries(environmentLabels.entries.where((e) => e.key != 'qualquer')), _env, (v) => setState(() => _env = v)),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(onPressed: () => Navigator.pop(context, const SearchFilters()), child: const Text('Limpar')),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, SearchFilters(category: _cat, difficulty: _diff, environment: _env)),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
