import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/text_normalizer.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'checklist_screen.dart';

/// Aba "Salvos": favoritos, anotações, listas e histórico de leitura.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Salvos'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Favoritos'),
              Tab(text: 'Listas'),
              Tab(text: 'Anotações'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: const TabBarView(children: [_Favorites(), _Checklists(), _Notes(), _History()]),
      ),
    );
  }
}

class _Favorites extends StatelessWidget {
  const _Favorites();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final favs = state.library.summaries(state.user.favoriteIds());
    if (favs.isEmpty) {
      return const EmptyState(
        icon: Icons.bookmark_border,
        title: 'Nenhum favorito ainda',
        message: 'Toque no marcador dentro de um artigo para salvá-lo aqui.',
      );
    }
    return ListView(
      children: [
        for (final a in favs)
          ArticleTile(
            a,
            trailing: IconButton(tooltip: 'Remover', icon: const Icon(Icons.bookmark_remove_outlined), onPressed: () => state.toggleFavorite(a.id)),
          ),
      ],
    );
  }
}

class _Checklists extends StatelessWidget {
  const _Checklists();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lists = state.user.checklists();
    final theme = Theme.of(context);
    const kindLabels = {'artigo': 'Materiais de artigo', 'equipamento': 'Equipamentos', 'mochila': 'Mochila de emergência', 'personalizada': 'Personalizada'};
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BackpackPlannerScreen())),
                icon: const Icon(Icons.backpack_outlined),
                label: const Text('Planejar mochila'),
              ),
              OutlinedButton.icon(
                onPressed: () => createCustomChecklist(context, kind: 'equipamento'),
                icon: const Icon(Icons.handyman_outlined),
                label: const Text('Lista de equipamentos'),
              ),
              OutlinedButton.icon(onPressed: () => createCustomChecklist(context), icon: const Icon(Icons.playlist_add), label: const Text('Lista livre')),
            ],
          ),
        ),
        if (lists.isEmpty)
          const EmptyState(
            icon: Icons.checklist,
            title: 'Nenhuma lista',
            message: 'Gere uma mochila de emergência, crie listas de equipamentos ou transforme os materiais de um artigo em checklist.',
          ),
        for (final l in lists)
          ListTile(
            leading: CircularProgressIndicator(value: l.total == 0 ? 0 : l.done / l.total, backgroundColor: theme.colorScheme.surfaceContainerHighest),
            title: Text(l.title),
            subtitle: Text('${kindLabels[l.kind] ?? l.kind} • ${l.done}/${l.total} • ${formatDate(l.updatedAt)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChecklistScreen(checklistId: l.id))),
          ),
      ],
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notes = state.user.notes();
    if (notes.isEmpty) {
      return const EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'Nenhuma anotação',
        message: 'Abra um artigo e toque no ícone de anotação para registrar observações privadas.',
      );
    }
    final titles = {for (final s in state.library.summaries(notes.map((n) => n.articleId).toList())) s.id: s.title};
    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => ListTile(
        leading: const Icon(Icons.sticky_note_2_outlined),
        title: Text(titles[notes[i].articleId] ?? 'Artigo não instalado (${notes[i].articleId})'),
        subtitle: Text(notes[i].text, maxLines: 3, overflow: TextOverflow.ellipsis),
        onTap: titles.containsKey(notes[i].articleId) ? () => openArticle(context, notes[i].articleId) : null,
      ),
    );
  }
}

class _History extends StatefulWidget {
  const _History();

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.user.history();
    final summaries = {for (final s in state.library.summaries(entries.map((e) => e.articleId).toList())) s.id: s};
    final f = normalize(_filter);
    final visible = entries.where((e) => summaries[e.articleId] != null && (f.isEmpty || normalize(summaries[e.articleId]!.title).contains(f))).toList();
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.manage_search), hintText: 'Pesquisar no histórico', isDense: true),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        if (entries.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                state.user.clearHistory();
                state.touch();
              },
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Limpar histórico'),
            ),
          ),
        if (visible.isEmpty) const EmptyState(icon: Icons.history, title: 'Histórico vazio', message: 'Os artigos que você abrir aparecerão aqui.'),
        for (final e in visible) ArticleTile(summaries[e.articleId]!, subtitle: 'Aberto em ${formatDate(e.viewedAt)} • ${e.count} vez(es)'),
      ],
    );
  }
}
