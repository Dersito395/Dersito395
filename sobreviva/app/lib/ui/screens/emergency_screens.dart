import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

/// Central de emergências: números de socorro e guias objetivos, todos offline.
class EmergencyCenterScreen extends StatelessWidget {
  const EmergencyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final guides = state.library.emergencies();
    final numbers = state.library.numbers();

    return Scaffold(
      appBar: AppBar(title: const Text('Emergências')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: DisclaimerBanner()),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: EmergencyNumbersCard()),
          const SectionHeader('O que fazer agora?', icon: Icons.emergency_outlined),
          for (final g in guides)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    child: Icon(iconFor(g.icon)),
                  ),
                  title: Text(g.title, style: theme.textTheme.titleMedium),
                  subtitle: Text(g.recognize.first, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EmergencyGuideScreen(guideId: g.id))),
                ),
              ),
            ),
          const SectionHeader('Números úteis no Brasil', icon: Icons.phone_in_talk_outlined),
          for (final n in numbers)
            ListTile(
              leading: SizedBox(
                width: 72,
                child: Text(
                  n.number,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                ),
              ),
              title: Text(n.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(n.purpose),
              trailing: Icon(n.sms ? Icons.sms_outlined : Icons.call_outlined),
              onTap: () => callNumber(context, n.number, sms: n.sms),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Para receber alertas da Defesa Civil, envie seu CEP por SMS para 40199 (gratuito). Ligações para 190, 192 e 193 são gratuitas.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class EmergencyGuideScreen extends StatelessWidget {
  const EmergencyGuideScreen({super.key, required this.guideId});
  final String guideId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final guide = state.library.emergency(guideId);
    if (guide == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.error_outline, title: 'Guia não encontrado', message: 'Ligue 192, 193 ou 190.'),
      );
    }
    final theme = Theme.of(context);
    final field = context.field;
    final related = state.library.summaries(guide.relatedIds);
    final sources = state.library.sourcesByIds(guide.sourceIds);
    final numbers = {for (final n in state.library.numbers()) n.number: n};

    return Scaffold(
      appBar: AppBar(title: Text(guide.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              for (final number in guide.callNumbers.take(2))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: field.danger,
                        foregroundColor: field.onDanger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => callNumber(context, number),
                      icon: const Icon(Icons.call),
                      label: Text(
                        'Ligar $number${numbers[number] != null && number.length <= 3 ? ' • ${numbers[number]!.name}' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _GuideSection(number: 1, title: 'Como reconhecer', icon: Icons.visibility_outlined, items: guide.recognize),
          _GuideSection(
            number: 2,
            title: 'Segurança imediata',
            icon: Icons.shield_outlined,
            items: guide.safety,
            color: field.caution,
            onColor: field.onCaution,
          ),
          _GuideSection(number: 3, title: 'O que fazer', icon: Icons.check_circle_outline, items: guide.doList, numbered: true, iconColor: field.okColor),
          _GuideSection(number: 4, title: 'O que evitar', icon: Icons.block, items: guide.avoid, iconColor: theme.colorScheme.error),
          _GuideSection(
            number: 5,
            title: 'Quando e como pedir socorro',
            icon: Icons.phone_in_talk_outlined,
            items: [
              'Números: ${guide.callNumbers.map((n) => numbers[n] == null ? n : '$n (${numbers[n]!.name})').join(', ')}',
              'Quando: ${guide.callWhen}',
              ...guide.callHow,
            ],
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Para saber mais', style: theme.textTheme.titleMedium),
            for (final a in related) ArticleTile(a),
          ],
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Fontes', style: theme.textTheme.titleSmall),
            for (final s in sources)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• ${s.institution}: ${s.title} (${s.year})', style: theme.textTheme.bodySmall),
              ),
          ],
          const SizedBox(height: 16),
          const DisclaimerBanner(),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.number,
    required this.title,
    required this.icon,
    required this.items,
    this.numbered = false,
    this.color,
    this.onColor,
    this.iconColor,
  });
  final int number;
  final String title;
  final IconData icon;
  final List<String> items;
  final bool numbered;
  final Color? color;
  final Color? onColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = onColor ?? theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.field.cardBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.secondary,
                  child: Text(
                    '$number',
                    style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.onSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium?.copyWith(color: fg)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    numbered
                        ? SizedBox(
                            width: 24,
                            child: Text(
                              '${i + 1}.',
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900, color: fg),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 3, right: 6),
                            child: Icon(icon, size: 18, color: iconColor ?? fg),
                          ),
                    Expanded(
                      child: Text(
                        items[i],
                        style: theme.textTheme.bodyLarge?.copyWith(color: fg, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
