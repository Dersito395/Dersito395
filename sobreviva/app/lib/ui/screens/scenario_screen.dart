import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'checklist_screen.dart';

/// Cartão de cenário usado na tela inicial e em Explorar.
class ScenarioCard extends StatelessWidget {
  const ScenarioCard({super.key, required this.scenario});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ScenarioScreen(scenarioId: scenario.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconFor(scenario.icon), color: theme.colorScheme.secondary),
              const SizedBox(height: 6),
              Text(
                scenario.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  scenario.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Roteiro de um cenário de crise: ações por fase e artigos de apoio.
class ScenarioScreen extends StatelessWidget {
  const ScenarioScreen({super.key, required this.scenarioId});
  final String scenarioId;

  static const _phaseIcons = [Icons.inventory_2_outlined, Icons.timer_outlined, Icons.calendar_view_week_outlined, Icons.all_inclusive];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sc = state.library.scenario(scenarioId);
    if (sc == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.search_off, title: 'Cenário não encontrado', message: 'Atualize a biblioteca em Ajustes › Pacotes e atualizações.'),
      );
    }
    final theme = Theme.of(context);
    final related = state.library.summaries(sc.relatedIds);
    final sources = state.library.sourcesByIds(sc.sourceIds);

    return Scaffold(
      appBar: AppBar(title: Text(sc.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final id = state.user.createChecklist('Plano: ${sc.title}', 'personalizada', [
            for (final p in sc.phases)
              for (final item in p.items) (item, p.title),
          ]);
          state.touch();
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChecklistScreen(checklistId: id)));
        },
        icon: const Icon(Icons.playlist_add_check),
        label: const Text('Criar meu plano'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Text(sc.summary, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          for (var i = 0; i < sc.phases.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: i == 1 ? context.field.caution : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.field.cardBorder),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_phaseIcons[i % _phaseIcons.length], color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(sc.phases[i].title, style: theme.textTheme.titleMedium?.copyWith(color: i == 1 ? context.field.onCaution : null)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final item in sc.phases[i].items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3, right: 8),
                              child: Icon(Icons.check_circle_outline, size: 18, color: context.field.okColor),
                            ),
                            Expanded(
                              child: Text(item, style: theme.textTheme.bodyLarge?.copyWith(color: i == 1 ? context.field.onCaution : null)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Como fazer: artigos do manual', style: theme.textTheme.titleMedium),
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
          const DisclaimerBanner(
            text: 'Roteiro informativo. Em qualquer crise, siga as orientações oficiais da Defesa Civil e das autoridades de saúde. Em perigo imediato, ligue 190, 192 ou 193.',
          ),
        ],
      ),
    );
  }
}
