import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'checklist_screen.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.articleId});
  final String articleId;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  Article? _article;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _article = state.library.article(widget.articleId);
    if (_article != null) state.recordView(widget.articleId);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final a = _article;
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Artigo não encontrado',
          message: 'Este artigo não está instalado. Baixe o pacote correspondente em Ajustes › Pacotes e atualizações.',
        ),
      );
    }
    final theme = Theme.of(context);
    final fav = state.isFavorite(a.id);
    final note = state.user.note(a.id);
    final related = state.search.related(a);

    return Scaffold(
      appBar: AppBar(
        title: Text(a.categoryName, style: theme.textTheme.titleMedium),
        actions: [
          IconButton(
            tooltip: fav ? 'Remover dos salvos' : 'Salvar',
            icon: Icon(fav ? Icons.bookmark : Icons.bookmark_add_outlined),
            onPressed: () {
              state.toggleFavorite(a.id);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(fav ? 'Removido dos salvos' : 'Salvo para acesso rápido'), duration: const Duration(seconds: 1)));
            },
          ),
          IconButton(tooltip: 'Anotações', icon: Icon(note == null ? Icons.edit_note : Icons.sticky_note_2), onPressed: () => _editNote(context, a)),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'share' => _share(a),
              'export' => _export(a),
              'font+' => state.setFontScale(state.fontScale + 0.1),
              'font-' => state.setFontScale(state.fontScale - 0.1),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'share',
                child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Compartilhar texto')),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(leading: Icon(Icons.file_download_outlined), title: Text('Exportar arquivo (.txt)')),
              ),
              PopupMenuItem(
                value: 'font+',
                child: ListTile(leading: Icon(Icons.text_increase), title: Text('Aumentar texto')),
              ),
              PopupMenuItem(
                value: 'font-',
                child: ListTile(leading: Icon(Icons.text_decrease), title: Text('Diminuir texto')),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(a.summary, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                _MetaGrid(article: a),
                if (a.technicalReviewPending) ...[
                  const SizedBox(height: 12),
                  const DisclaimerBanner(
                    text: 'Conteúdo de saúde aguardando revisão técnica por profissional habilitado. Baseado nas fontes listadas abaixo. Não substitui o atendimento do SAMU (192) ou dos Bombeiros (193).',
                  ),
                ],
                if (note != null) ...[const SizedBox(height: 12), _NoteCard(text: note, onTap: () => _editNote(context, a))],
              ],
            ),
          ),
          _Section(
            title: 'Objetivo',
            icon: Icons.flag_outlined,
            child: Text(a.objective, style: theme.textTheme.bodyLarge),
          ),
          if (a.materials.isNotEmpty)
            _Section(
              title: 'Materiais necessários',
              icon: Icons.inventory_2_outlined,
              trailing: TextButton.icon(
                onPressed: () => _materialsChecklist(context, a),
                icon: const Icon(Icons.checklist, size: 18),
                label: const Text('Checklist'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final m in a.materials) _Bullet(text: m, icon: Icons.check_box_outline_blank)],
              ),
            ),
          _Section(
            title: 'Instruções',
            icon: Icons.format_list_numbered,
            child: Column(
              children: [
                for (var i = 0; i < a.steps.length; i++)
                  _StepTile(index: i + 1, step: a.steps[i], image: a.steps[i].image == null ? null : a.imageFor(a.steps[i].image!)),
              ],
            ),
          ),
          _Section(
            title: 'Cuidados',
            icon: Icons.warning_amber_rounded,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.field.caution, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final c in a.cautions) _Bullet(text: c, icon: Icons.error_outline, color: context.field.onCaution)],
              ),
            ),
          ),
          if (a.alternatives.isNotEmpty)
            _Section(
              title: 'Alternativas',
              icon: Icons.alt_route,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final c in a.alternatives) _Bullet(text: c, icon: Icons.arrow_right)],
              ),
            ),
          _Section(
            title: 'Fontes',
            icon: Icons.menu_book_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in a.sources) _SourceTile(source: s),
                const SizedBox(height: 8),
                Text(
                  'Versão ${a.version} • revisado em ${formatDate(a.updatedAt)}${a.technicalReviewPending ? ' • revisão técnica pendente' : ''} • texto original do SOBREVIVA',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (related.isNotEmpty) ...[const SectionHeader('Artigos relacionados', icon: Icons.link), for (final r in related) ArticleTile(r)],
          const SizedBox(height: 16),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: DisclaimerBanner()),
        ],
      ),
    );
  }

  Future<void> _share(Article a) async {
    await SharePlus.instance.share(ShareParams(text: a.toPlainText(), subject: a.title));
  }

  Future<void> _export(Article a) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${a.id}.txt');
    await file.writeAsString(a.toPlainText());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/plain')],
        subject: a.title,
      ),
    );
  }

  void _materialsChecklist(BuildContext context, Article a) {
    final state = context.read<AppState>();
    var id = state.user.checklistForArticle(a.id);
    id ??= state.user.createChecklist('Materiais: ${a.title}', 'artigo', [for (final m in a.materials) (m, null)], articleId: a.id);
    state.touch();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChecklistScreen(checklistId: id!)));
  }

  Future<void> _editNote(BuildContext context, Article a) async {
    final state = context.read<AppState>();
    final controller = TextEditingController(text: state.user.note(a.id) ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Anotação privada', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Fica apenas neste aparelho. Pode ser exportada em Ajustes.', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(hintText: 'Ex.: onde guardo minha lona, telefone do posto de saúde…'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (controller.text.isNotEmpty) TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Apagar')),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Salvar')),
              ],
            ),
          ],
        ),
      ),
    );
    if (result != null) state.saveNote(a.id, result);
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Text('$label: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            item(Icons.category_outlined, 'Categoria', [article.categoryName, ?article.subcategoryName].join(' › ')),
            item(Icons.signal_cellular_alt, 'Dificuldade', difficultyLabels[article.difficulty] ?? article.difficulty),
            item(Icons.schedule, 'Tempo estimado', article.timeEstimate),
            item(Icons.terrain_outlined, 'Ambiente', article.environments.map((e) => environmentLabels[e] ?? e).join(', ')),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child, this.trailing});
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title.toUpperCase(), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.icon, this.color});
  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, size: 18, color: color ?? Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step, this.image});
  final int index;
  final ArticleStep step;
  final ArticleImage? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                child: Text(
                  '$index',
                  style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.onSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(step.text, style: theme.textTheme.bodyLarge),
                ),
              ),
            ],
          ),
          if (step.image != null) ...[const SizedBox(height: 10), _Figure(file: step.image!, image: image)],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.file, this.image});
  final String file;
  final ArticleImage? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(image?.caption ?? '')),
                body: InteractiveViewer(
                  maxScale: 5,
                  child: Center(child: LibraryImage(file, semanticLabel: image?.alt)),
                ),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 400 / 260,
              child: LibraryImage(file, semanticLabel: image?.alt ?? image?.caption),
            ),
          ),
        ),
        if (image != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${image!.caption}${image!.credit != null ? '  •  ${image!.credit} (${image!.license})' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source});
  final SourceRef source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: source.citation));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referência copiada')));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(source.institution, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
            Text('${source.title}. ${source.publisher}, ${source.year}.', style: theme.textTheme.bodyMedium),
            SelectableText(source.url, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
            if (source.note != null) Text('Usado para: ${source.note}', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            Text('Licença: ${source.license}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sticky_note_2_outlined, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
