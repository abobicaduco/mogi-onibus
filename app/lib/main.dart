import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'models.dart';
import 'schedule_repository.dart';
import 'update_service.dart';
import 'line_detail.dart';

void main() => runApp(const MogiOnibusApp());

class MogiOnibusApp extends StatelessWidget {
  const MogiOnibusApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1B5E20); // verde Mogi
    return MaterialApp(
      title: 'Ônibus Mogi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = ScheduleRepository();
  final _updates = UpdateService();
  SchedulesData? _data;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final data = await _repo.loadLocal();
    setState(() {
      _data = data;
      _loading = false;
    });
    // verificações de atualização em segundo plano, após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduleUpdate();
      _checkAppUpdate();
    });
  }

  Future<void> _checkScheduleUpdate() async {
    final remote = await _repo.checkRemote();
    if (remote == null || !mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.update),
        title: const Text('Novos horários disponíveis'),
        content: Text(
            'Há uma atualização de horários (versão ${remote.dataVersao}).\n'
            'Deseja atualizar agora? É rápido e funciona offline depois.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Agora não')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Atualizar')),
        ],
      ),
    );
    if (accept == true) {
      await _repo.applyPending(remote);
      if (!mounted) return;
      setState(() => _data = remote);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horários atualizados!')),
      );
    }
  }

  Future<void> _checkAppUpdate() async {
    final rel = await _updates.checkAppUpdate();
    if (rel == null || !mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.system_update),
        title: Text('Nova versão do app (${rel.tag})'),
        content: SingleChildScrollView(
          child: Text(rel.body.isNotEmpty
              ? rel.body
              : 'Uma nova versão do aplicativo está disponível.'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Depois')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Baixar')),
        ],
      ),
    );
    if (go == true) {
      final url = rel.apkUrl ?? rel.htmlUrl;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines =
        _data?.linhas.where((l) => l.matches(_query)).toList() ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ônibus Mogi'),
        actions: [
          IconButton(
            tooltip: 'Sobre',
            icon: const Icon(Icons.info_outline),
            onPressed: _showAbout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar linha (nº, nome, bairro)...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (_data != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.event,
                            size: 14, color: Theme.of(context).hintColor),
                        const SizedBox(width: 4),
                        Text(
                            'Horários de ${_data!.dataVersao}  •  '
                            '${lines.length} linhas',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final l = lines[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(l.linha.length > 4
                              ? l.linha.substring(0, 4)
                              : l.linha),
                        ),
                        title: Text(l.nome.isNotEmpty ? l.nome : l.titulo),
                        subtitle: Text('Linha ${l.linha}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LineDetailPage(line: l)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Ônibus Mogi',
      applicationVersion: 'Horários: ${_data?.dataVersao ?? '—'}',
      children: [
        const SizedBox(height: 8),
        const Text(
            'App não oficial com os horários de ônibus de Mogi das Cruzes. '
            'Dados extraídos do portal da Secretaria de Mobilidade e Trânsito.'),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: const Icon(Icons.public),
          label: const Text('Fonte oficial'),
          onPressed: () => launchUrl(Uri.parse(AppConfig.fonteOficial),
              mode: LaunchMode.externalApplication),
        ),
        TextButton.icon(
          icon: const Icon(Icons.code),
          label: const Text('Código / atualizações (GitHub)'),
          onPressed: () => launchUrl(Uri.parse(AppConfig.sourceUrl),
              mode: LaunchMode.externalApplication),
        ),
      ],
    );
  }
}
