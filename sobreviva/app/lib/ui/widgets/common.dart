import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../screens/article_screen.dart';

/// Imagem da biblioteca: usa o arquivo baixado quando existir, senão o asset embarcado.
class LibraryImage extends StatelessWidget {
  const LibraryImage(this.file, {super.key, this.semanticLabel, this.fit = BoxFit.contain, this.height});
  final String file;
  final String? semanticLabel;
  final BoxFit fit;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final downloaded = context.read<AppState>().downloadedMedia(file);
    final isSvg = file.endsWith('.svg');
    final fallback = Container(
      height: height ?? 120,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: const Icon(Icons.image_not_supported_outlined),
    );
    Widget img;
    if (isSvg) {
      img = downloaded != null
          ? SvgPicture.file(downloaded, fit: fit, height: height, semanticsLabel: semanticLabel)
          : SvgPicture.asset('assets/media/$file', fit: fit, height: height, semanticsLabel: semanticLabel, errorBuilder: (_, _, _) => fallback);
    } else {
      img = downloaded != null
          ? Image.file(downloaded, fit: fit, height: height, semanticLabel: semanticLabel, errorBuilder: (_, _, _) => fallback)
          : Image.asset('assets/media/$file', fit: fit, height: height, semanticLabel: semanticLabel, errorBuilder: (_, _, _) => fallback);
    }
    return img;
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.icon});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary), const SizedBox(width: 8)],
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class DifficultyChip extends StatelessWidget {
  const DifficultyChip(this.difficulty, {super.key});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Text(
        difficultyLabels[difficulty] ?? difficulty,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
      ),
    );
  }
}

void openArticle(BuildContext context, String id) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ArticleScreen(articleId: id)));
}

class ArticleTile extends StatelessWidget {
  const ArticleTile(this.article, {super.key, this.trailing, this.subtitle, this.onTap});
  final ArticleSummary article;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap ?? () => openArticle(context, article.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
              child: Icon(iconFor(context.read<AppState>().categoryIcon(article.categoryId)), color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DifficultyChip(article.difficulty),
                      Text(article.categoryName, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      if (article.coverImage != null) Icon(Icons.image_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Indicador de funcionamento offline: a biblioteca local está sempre disponível.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final updates = state.availableUpdates.length;
    final label = state.online
        ? (updates > 0 ? '$updates atualização(ões) disponível(is)' : 'Online • biblioteca local ativa')
        : 'Offline • biblioteca disponível';
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: updates > 0 ? scheme.secondaryContainer : scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.online ? (updates > 0 ? Icons.system_update_outlined : Icons.cloud_done_outlined) : Icons.offline_pin_outlined,
              size: 16,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> callNumber(BuildContext context, String number, {bool sms = false}) async {
  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = Uri(scheme: sms ? 'sms' : 'tel', path: digits);
  final ok = await canLaunchUrl(uri) && await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível abrir o discador. Ligue manualmente para $number.')));
  }
}

/// Botões grandes para 192, 193 e 190, com a finalidade de cada um.
class EmergencyNumbersCard extends StatelessWidget {
  const EmergencyNumbersCard({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final numbers = context.read<AppState>().library.numbers().where((n) => n.priority == 1).toList();
    final field = context.field;
    return Row(
      children: [
        for (final n in numbers)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: field.danger,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => callNumber(context, n.number),
                  child: Semantics(
                    button: true,
                    label: 'Ligar ${n.number}, ${n.name}',
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14, horizontal: 6),
                      child: Column(
                        children: [
                          Text(
                            n.number,
                            style: TextStyle(fontSize: compact ? 22 : 28, fontWeight: FontWeight.w900, color: field.onDanger),
                          ),
                          Text(
                            n.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: field.onDanger),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Aviso de que o conteúdo não substitui atendimento profissional.
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    final field = context.field;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: field.caution, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: field.onCaution, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text ??
                  'Este aplicativo é informativo e não substitui os serviços de emergência nem o atendimento profissional. Em perigo, ligue 192, 193 ou 190.',
              style: TextStyle(color: field.onCaution, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
}

String formatDate(String? iso) {
  if (iso == null) return '—';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}
