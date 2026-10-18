import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/package_service.dart';
import '../../services/storage_info.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SectionHeader('Leitura e aparência', icon: Icons.palette_outlined),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Escuro'), icon: Icon(Icons.dark_mode_outlined)),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (s) => state.setThemeMode(s.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Tamanho do texto'),
            subtitle: Slider(
              value: state.fontScale,
              min: 0.85,
              max: 1.6,
              divisions: 15,
              label: '${(state.fontScale * 100).round()}%',
              onChanged: state.setFontScale,
            ),
            trailing: Text('${(state.fontScale * 100).round()}%'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Modo ambiente externo'),
            subtitle: const Text('Alto contraste, texto mais forte e maior para leitura sob sol.'),
            value: state.outdoorMode,
            onChanged: state.setOutdoorMode,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.battery_saver_outlined),
            title: const Text('Economia de bateria'),
            subtitle: const Text('Fundo preto, sem animações e sem verificação automática de atualizações.'),
            value: state.batterySaver,
            onChanged: state.setBatterySaver,
          ),
          const SectionHeader('Biblioteca', icon: Icons.local_library_outlined),
          ListTile(
            leading: Badge(isLabelVisible: state.availableUpdates.isNotEmpty, child: const Icon(Icons.inventory_2_outlined)),
            title: const Text('Pacotes e atualizações'),
            subtitle: Text(
              'Versão da biblioteca: ${state.library.libraryVersion} • ${state.library.articleCount} artigos • atualizada em ${formatDate(state.library.lastUpdate)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PackagesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Fontes bibliográficas'),
            subtitle: const Text('Todas as referências usadas nos artigos.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SourcesScreen())),
          ),
          const SectionHeader('Seus dados', icon: Icons.lock_outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Favoritos, anotações, listas e histórico ficam somente neste aparelho. Não é necessário criar conta.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          ListTile(leading: const Icon(Icons.upload_file), title: const Text('Exportar anotações e listas'), onTap: () => _export(context)),
          ListTile(leading: const Icon(Icons.download_outlined), title: const Text('Importar anotações e listas'), onTap: () => _import(context)),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Limpar histórico de leitura e pesquisas'),
            onTap: () {
              state.user.clearHistory();
              state.user.clearSearchHistory();
              state.touch();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Histórico apagado')));
            },
          ),
          const SectionHeader('Sobre', icon: Icons.info_outline),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Sobre o SOBREVIVA'),
            subtitle: const Text('Aviso importante, licenças e créditos'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final state = context.read<AppState>();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/sobreviva-dados-$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(state.user.exportData()));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'SOBREVIVA – anotações e listas',
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
      if (picked == null) return;
      final text = await picked.xFile.readAsString();
      final r = state.user.importData(jsonDecode(text) as Map<String, dynamic>);
      state.touch();
      messenger.showSnackBar(SnackBar(content: Text('Importado: ${r.notes} anotação(ões), ${r.checklists} lista(s), ${r.favorites} favorito(s).')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Não foi possível importar: ${e is FormatException ? e.message : 'arquivo inválido'}')));
    }
  }
}

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  int? _free;
  bool _checking = false;
  String? _busyId;
  double? _progress;
  String _stage = '';
  CancelToken? _cancel;

  @override
  void initState() {
    super.initState();
    StorageInfo.freeBytes().then((v) {
      if (mounted) setState(() => _free = v);
    });
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    await context.read<AppState>().checkForUpdates();
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _install(RemotePackage pkg) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final cancel = CancelToken();
    setState(() {
      _busyId = pkg.id;
      _progress = 0;
      _stage = 'baixando';
      _cancel = cancel;
    });
    try {
      final r = await state.installPackage(
        pkg,
        cancel: cancel,
        onProgress: (received, total, stage) {
          if (!mounted) return;
          setState(() {
            _progress = total == 0 ? null : received / total;
            _stage = stage;
          });
        },
      );
      messenger.showSnackBar(SnackBar(content: Text('${pkg.title} v${pkg.version} instalado: ${r.inserted} novo(s), ${r.updated} atualizado(s).')));
    } on DownloadCancelled {
      messenger.showSnackBar(const SnackBar(content: Text('Download cancelado. Nada foi alterado.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Falha: $e. Sua biblioteca atual foi preservada.')));
    } finally {
      if (mounted) {
        setState(() {
          _busyId = null;
          _progress = null;
          _cancel = null;
        });
      }
      StorageInfo.freeBytes().then((v) {
        if (mounted) setState(() => _free = v);
      });
    }
  }

  Future<void> _editServer() async {
    final state = context.read<AppState>();
    final c = TextEditingController(text: state.updateServer);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor de atualizações'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(hintText: 'https://exemplo.org/api/v1/'),
            ),
            const SizedBox(height: 8),
            const Text('Endereço do serviço de atualização publicado pelo painel administrativo.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Salvar')),
        ],
      ),
    );
    if (v != null) state.setUpdateServer(v);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final installed = {for (final p in state.installedPackages) p.id: p};
    final remote = state.manifest?.packages ?? const <RemotePackage>[];
    final remoteIds = remote.map((r) => r.id).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Pacotes e atualizações')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(state.online ? Icons.wifi : Icons.wifi_off, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(state.online ? 'Conectado' : 'Sem conexão', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Biblioteca instalada: versão ${state.library.libraryVersion}, ${state.library.articleCount} artigos.'),
                  Text('Última atualização: ${formatDate(state.library.lastUpdate)}'),
                  Text('Espaço livre no aparelho: ${_free == null ? 'indisponível' : formatBytes(_free!)}'),
                  Text('Última verificação: ${state.lastCheck == null ? 'nunca' : formatDate(state.lastCheck!.toIso8601String())}'),
                  if (state.lastCheckError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(state.lastCheckError!, style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _checking || _busyId != null ? null : _check,
                        icon: _checking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
                        label: const Text('Verificar atualizações'),
                      ),
                      OutlinedButton.icon(onPressed: _editServer, icon: const Icon(Icons.dns_outlined), label: const Text('Servidor')),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Verificar automaticamente ao conectar'),
                    value: state.autoCheckUpdates,
                    onChanged: state.setAutoCheck,
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DisclaimerBanner(
              text: 'Atualizações são verificadas (SHA-256) e instaladas de forma atômica. Se algo falhar, o conteúdo atual é mantido. Favoritos, anotações e listas nunca são apagados.',
            ),
          ),
          const SectionHeader('Instalados', icon: Icons.offline_pin_outlined),
          for (final p in installed.values)
            _PackageTile(
              title: p.title,
              description: p.description,
              details:
                  'v${p.version} • ${p.articleCount} artigos • ${p.bundled ? 'incluído no app' : formatBytes(p.sizeBytes)} • instalado em ${formatDate(p.installedAt)}',
              remote: remote.where((r) => r.id == p.id).firstOrNull,
              installedVersion: p.version,
              busy: _busyId == p.id,
              progress: _progress,
              stage: _stage,
              onInstall: _busyId == null ? _install : null,
              onCancel: () => _cancel?.cancel(),
            ),
          if (remote.isNotEmpty) ...[
            const SectionHeader('Disponíveis para baixar', icon: Icons.cloud_download_outlined),
            for (final r in remote.where((r) => !installed.containsKey(r.id)))
              _PackageTile(
                title: r.title,
                description: r.description,
                details:
                    'v${r.version} • ${r.articleCount} artigos • ${r.mediaCount} imagens • ${formatBytes(r.sizeBytes)} • publicado em ${formatDate(r.releasedAt)}',
                remote: r,
                installedVersion: null,
                busy: _busyId == r.id,
                progress: _progress,
                stage: _stage,
                onInstall: _busyId == null ? _install : null,
                onCancel: () => _cancel?.cancel(),
              ),
            if (remoteIds.every(installed.containsKey))
              const Padding(padding: EdgeInsets.all(16), child: Text('Todos os pacotes disponíveis já estão instalados.')),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                state.updateServer.isEmpty
                    ? 'Configure o servidor de atualizações para ver pacotes adicionais (biblioteca completa, primeiros socorros, mata, emergências urbanas, navegação e guias ilustrados).'
                    : 'Toque em “Verificar atualizações” quando houver conexão para listar pacotes adicionais.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.title,
    required this.description,
    required this.details,
    required this.remote,
    required this.installedVersion,
    required this.busy,
    required this.progress,
    required this.stage,
    required this.onInstall,
    required this.onCancel,
  });
  final String title;
  final String description;
  final String details;
  final RemotePackage? remote;
  final int? installedVersion;
  final bool busy;
  final double? progress;
  final String stage;
  final void Function(RemotePackage)? onInstall;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = remote;
    final canUpdate = r != null && (installedVersion == null || r.version > installedVersion!);
    const stageLabels = {'baixando': 'Baixando…', 'verificando': 'Verificando integridade…', 'instalando': 'Instalando…', 'concluido': 'Concluído'};
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (description.isNotEmpty) Text(description, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(details, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (busy) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: stage == 'baixando' ? progress : null),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: Text('${stageLabels[stage] ?? stage} ${stage == 'baixando' && progress != null ? '${(progress! * 100).round()}%' : ''}')),
                    if (stage == 'baixando' || stage == 'verificando') TextButton(onPressed: onCancel, child: const Text('Cancelar')),
                  ],
                ),
              ] else if (canUpdate)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: onInstall == null ? null : () => onInstall!(r),
                    icon: Icon(installedVersion == null ? Icons.download : Icons.system_update),
                    label: Text(
                      installedVersion == null ? 'Baixar (${formatBytes(r.sizeBytes)})' : 'Atualizar para v${r.version} (${formatBytes(r.sizeBytes)})',
                    ),
                  ),
                )
              else if (installedVersion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      const Text('Atualizado'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sources = context.read<AppState>().library.allSources();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Fontes bibliográficas')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sources.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Os textos do SOBREVIVA são originais, escritos a partir destas referências. Nenhum conteúdo protegido foi copiado ou traduzido integralmente.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          final s = sources[i - 1];
          return ListTile(
            title: Text(s.institution, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.author}. ${s.title}. ${s.publisher}, ${s.year}.'),
                SelectableText(s.url, style: TextStyle(color: theme.colorScheme.primary)),
                Text('Licença: ${s.license} • Idioma: ${s.language}', style: theme.textTheme.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget p(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t, style: theme.textTheme.bodyLarge),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('SOBREVIVA | Biblioteca de Campo', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          const DisclaimerBanner(),
          const SizedBox(height: 16),
          p(
            'Biblioteca offline de preparação para emergências, técnicas de campo, primeiros socorros e autossuficiência. Toda a biblioteca essencial funciona sem internet e sem cadastro.',
          ),
          p(
            'Os conteúdos de saúde marcados como “revisão técnica pendente” ainda não foram validados por profissional habilitado. Procure cursos práticos de primeiros socorros em instituições reconhecidas.',
          ),
          p('Ilustrações: desenhos originais do projeto SOBREVIVA, licenciados sob CC BY 4.0. Textos: originais, baseados nas fontes listadas em cada artigo.'),
          p(
            'Privacidade: o aplicativo não coleta dados pessoais. Favoritos, notas, listas e histórico ficam apenas no aparelho. A única comunicação de rede é a verificação e o download de pacotes de conteúdo, quando você permite.',
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => showLicensePage(context: context, applicationName: 'SOBREVIVA'),
            child: const Text('Licenças de software'),
          ),
        ],
      ),
    );
  }
}
