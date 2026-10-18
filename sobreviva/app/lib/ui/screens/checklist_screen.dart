import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/backpack_planner.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key, required this.checklistId});
  final int checklistId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.user.checklist(checklistId);
    if (list == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.checklist, title: 'Lista não encontrada', message: ''),
      );
    }
    final items = state.user.items(checklistId);
    final theme = Theme.of(context);
    final sections = <String?, List<int>>{};
    for (var i = 0; i < items.length; i++) {
      sections.putIfAbsent(items[i].section, () => []).add(i);
    }
    final done = items.where((i) => i.done).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(list.title, maxLines: 2),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'rename':
                  final name = await _ask(context, 'Renomear lista', list.title);
                  if (name != null && name.isNotEmpty) {
                    state.user.renameChecklist(checklistId, name);
                    state.touch();
                  }
                case 'reset':
                  state.user.resetChecklist(checklistId);
                  state.touch();
                case 'share':
                  final text = StringBuffer('${list.title}\n');
                  for (final e in sections.entries) {
                    if (e.key != null) text.writeln('\n${e.key}');
                    for (final i in e.value) {
                      text.writeln('${items[i].done ? '[x]' : '[ ]'} ${items[i].text}');
                    }
                  }
                  await SharePlus.instance.share(ShareParams(text: text.toString(), subject: list.title));
                case 'export':
                  final dir = await getTemporaryDirectory();
                  final file = File('${dir.path}/lista-$checklistId.json');
                  final data = state.user.exportData();
                  data['favorites'] = <String>[];
                  data['notes'] = <Object>[];
                  data['checklists'] = (data['checklists'] as List).where((c) => (c as Map)['title'] == list.title).toList();
                  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path, mimeType: 'application/json')],
                      subject: list.title,
                    ),
                  );
                case 'delete':
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Excluir lista?'),
                      content: Text('“${list.title}” será removida deste aparelho.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    state.user.deleteChecklist(checklistId);
                    state.touch();
                    Navigator.pop(context);
                  }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Renomear')),
              PopupMenuItem(value: 'reset', child: Text('Desmarcar todos')),
              PopupMenuItem(value: 'share', child: Text('Compartilhar como texto')),
              PopupMenuItem(value: 'export', child: Text('Exportar arquivo')),
              PopupMenuItem(value: 'delete', child: Text('Excluir lista')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final text = await _ask(context, 'Novo item', '');
          if (text != null && text.trim().isNotEmpty) {
            state.user.addItem(checklistId, text.trim(), section: items.isEmpty ? null : items.last.section);
            state.touch();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$done de ${items.length} concluído(s)', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: items.isEmpty ? 0 : done / items.length, minHeight: 8, borderRadius: BorderRadius.circular(8)),
              ],
            ),
          ),
          if (list.kind == 'mochila')
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DisclaimerBanner(
                text: 'Lista gerada como ponto de partida. Ajuste às necessidades da sua família e revise a cada 6 meses (validade de alimentos, água, remédios e pilhas).',
              ),
            ),
          for (final e in sections.entries) ...[
            if (e.key != null) SectionHeader(e.key!),
            for (final i in e.value)
              Dismissible(
                key: ValueKey(items[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: theme.colorScheme.error,
                  child: Icon(Icons.delete, color: theme.colorScheme.onError),
                ),
                onDismissed: (_) {
                  state.user.deleteItem(items[i].id);
                  state.touch();
                },
                child: CheckboxListTile(
                  value: items[i].done,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(items[i].text, style: items[i].done ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                  onChanged: (v) {
                    state.user.setItemDone(items[i].id, v ?? false);
                    state.touch();
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

Future<String?> _ask(BuildContext context, String title, String initial) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.sentences, onSubmitted: (v) => Navigator.pop(ctx, v)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('OK')),
      ],
    ),
  );
}

Future<void> createCustomChecklist(BuildContext context, {String kind = 'personalizada'}) async {
  final state = context.read<AppState>();
  final title = await _ask(context, kind == 'equipamento' ? 'Nome da lista de equipamentos' : 'Nome da lista', '');
  if (title == null || title.trim().isEmpty || !context.mounted) return;
  final id = state.user.createChecklist(title.trim(), kind, const []);
  state.touch();
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChecklistScreen(checklistId: id)));
}

/// Planejamento de mochila de emergência.
class BackpackPlannerScreen extends StatefulWidget {
  const BackpackPlannerScreen({super.key});

  @override
  State<BackpackPlannerScreen> createState() => _BackpackPlannerScreenState();
}

class _BackpackPlannerScreenState extends State<BackpackPlannerScreen> {
  KitDuration _duration = KitDuration.h72;
  int _adults = 1, _children = 0, _infants = 0, _elderly = 0, _pets = 0;
  final Set<KitEnvironment> _envs = {KitEnvironment.urbano};
  bool _meds = false, _mobility = false;

  KitPlanInput get _input => KitPlanInput(
    duration: _duration,
    adults: _adults,
    children: _children,
    infants: _infants,
    elderly: _elderly,
    pets: _pets,
    environments: _envs,
    continuousMedication: _meds,
    mobilityNeeds: _mobility,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = buildKitPlan(_input);
    Widget counter(String label, int value, ValueChanged<int> set, {int min = 0}) => ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuir $label',
            onPressed: value > min ? () => setState(() => set(value - 1)) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text('$value', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          ),
          IconButton(
            tooltip: 'Aumentar $label',
            onPressed: value < 20 ? () => setState(() => set(value + 1)) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Planejar mochila')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const SectionHeader('Duração'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kitDurationLabels.entries)
                  ChoiceChip(label: Text(e.value), selected: _duration == e.key, onSelected: (_) => setState(() => _duration = e.key)),
              ],
            ),
          ),
          const SectionHeader('Pessoas'),
          counter('Adultos', _adults, (v) => _adults = v, min: 1),
          counter('Crianças', _children, (v) => _children = v),
          counter('Bebês', _infants, (v) => _infants = v),
          counter('Idosos', _elderly, (v) => _elderly = v),
          counter('Animais de estimação', _pets, (v) => _pets = v),
          const SectionHeader('Ambiente e condições previstas'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kitEnvironmentLabels.entries)
                  FilterChip(
                    label: Text(e.value),
                    selected: _envs.contains(e.key),
                    onSelected: (v) => setState(() {
                      v ? _envs.add(e.key) : _envs.remove(e.key);
                      if (_envs.isEmpty) _envs.add(KitEnvironment.urbano);
                    }),
                  ),
              ],
            ),
          ),
          SwitchListTile(title: const Text('Alguém usa medicamento contínuo'), value: _meds, onChanged: (v) => setState(() => _meds = v)),
          SwitchListTile(title: const Text('Alguém tem mobilidade reduzida'), value: _mobility, onChanged: (v) => setState(() => _mobility = v)),
          SectionHeader('Prévia: ${plan.length} itens'),
          for (final item in plan.take(6))
            ListTile(dense: true, leading: const Icon(Icons.check_box_outline_blank, size: 20), title: Text(item.text), subtitle: Text(item.section)),
          if (plan.length > 6)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('… e mais ${plan.length - 6} itens na lista completa.')),
          const Padding(
            padding: EdgeInsets.all(16),
            child: DisclaimerBanner(
              text: 'Não existe lista universal. A referência de água é da FEMA/Ready.gov; as demais quantidades dependem dos hábitos, da saúde e do clima — ajuste antes de usar.',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final state = context.read<AppState>();
          final title = 'Mochila ${kitDurationLabels[_duration]!.split(' (').first} • ${_input.people} pessoa(s)';
          final id = state.user.createChecklist(title, 'mochila', [for (final i in plan) (i.text, i.section)], params: _input.toJson());
          state.touch();
          Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => ChecklistScreen(checklistId: id)));
        },
        icon: const Icon(Icons.save_alt),
        label: const Text('Gerar lista'),
      ),
    );
  }
}
