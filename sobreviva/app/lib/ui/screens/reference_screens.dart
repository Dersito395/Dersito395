import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

/// Aba "Consultas": documentos de referência (PDF offline) e links externos.
class ReferencesView extends StatelessWidget {
  const ReferencesView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final docs = state.library.documents();
    final links = state.library.links();
    final official = links.where((l) => !l.community).toList();
    final community = links.where((l) => l.community).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Documentos originais usados como referência, para consultar sem internet, e endereços úteis para quando houver conexão.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text('Documentos (offline)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (docs.isEmpty) const Text('Nenhum documento instalado. Baixe a biblioteca completa em Ajustes › Pacotes e atualizações.'),
        for (final d in docs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.onSecondary),
                ),
                title: Text(d.title, style: theme.textTheme.titleMedium),
                subtitle: Text('${d.subtitle}\n${_langLabel(d.lang)} · ${d.pages} páginas', maxLines: 3),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DocumentScreen(documentId: d.id))),
              ),
            ),
          ),
        if (official.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Fontes oficiais (exigem internet)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final l in official) _LinkCard(link: l),
        ],
        if (community.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Comunidade e opiniões (exigem internet)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final l in community) _LinkCard(link: l),
        ],
        if (!state.online)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: DisclaimerBanner(text: 'Sem conexão agora. Os documentos acima funcionam offline; os links abrem quando houver internet.'),
          ),
      ],
    );
  }
}

String _langLabel(String lang) => lang.startsWith('en') ? 'Em inglês' : 'Em português';

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link});
  final RefLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => openExternalLink(context, link.url),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(link.community ? Icons.forum_outlined : Icons.verified_outlined, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(link.description, style: theme.textTheme.bodyMedium),
                      if (link.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            link.note,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        link.url,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ficha de um documento: resumo em português, destaques por página e licença.
class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key, required this.documentId});
  final String documentId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final doc = state.library.document(documentId);
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Documento não encontrado',
          message: 'Atualize a biblioteca em Ajustes › Pacotes e atualizações.',
        ),
      );
    }
    final theme = Theme.of(context);
    final related = state.library.summaries(doc.relatedIds);
    final source = state.library.sourcesByIds([doc.sourceId]);
    void open(int page) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfReaderScreen(document: doc, initialPage: page),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => open(1),
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('Abrir documento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Text(doc.subtitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('${_langLabel(doc.lang)} · ${doc.pages} páginas · disponível offline', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(doc.summary, style: theme.textTheme.bodyLarge),
          if (doc.statusNote.isNotEmpty) ...[const SizedBox(height: 12), DisclaimerBanner(text: doc.statusNote)],
          if (doc.topics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final t in doc.topics) Chip(label: Text(t))]),
          ],
          if (doc.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Onde está cada assunto', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final h in doc.highlights)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${h.page}', style: const TextStyle(fontSize: 13))),
                  title: Text(h.title),
                  subtitle: h.note.isEmpty ? null : Text(h.note),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(h.page),
                ),
              ),
          ],
          if (related.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Artigos do manual baseados neste documento', style: theme.textTheme.titleMedium),
            for (final a in related) ArticleTile(a),
          ],
          const SizedBox(height: 16),
          Text('Licença', style: theme.textTheme.titleSmall),
          Text(doc.license, style: theme.textTheme.bodySmall),
          for (final s in source)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Fonte: ${s.institution}, ${s.title} (${s.year}). ${s.url}', style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Leitor de PDF offline (pdfrx), aberto na página indicada.
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.document, this.initialPage = 1});
  final RefDocument document;
  final int initialPage;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _controller = PdfViewerController();
  int? _page;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final doc = widget.document;
    final downloaded = state.downloadedMedia(doc.file);
    final params = PdfViewerParams(
      onPageChanged: (n) => setState(() => _page = n),
      errorBannerBuilder: (context, error, stackTrace, documentRef) => const EmptyState(
        icon: Icons.error_outline,
        title: 'Não foi possível abrir o PDF',
        message: 'Reinstale a biblioteca em Ajustes › Pacotes e atualizações.',
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (doc.highlights.isNotEmpty)
            PopupMenuButton<int>(
              tooltip: 'Ir para um assunto',
              icon: const Icon(Icons.toc),
              onSelected: (page) => _controller.goToPage(pageNumber: page),
              itemBuilder: (_) => [for (final h in doc.highlights) PopupMenuItem(value: h.page, child: Text('p. ${h.page} · ${h.title}'))],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Página ${_page ?? widget.initialPage} de ${doc.pages}', style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
      body: downloaded != null
          ? PdfViewer.file(downloaded.path, controller: _controller, initialPageNumber: widget.initialPage, params: params)
          : PdfViewer.asset('assets/media/${doc.file}', controller: _controller, initialPageNumber: widget.initialPage, params: params),
    );
  }
}
