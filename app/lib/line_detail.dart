import 'package:flutter/material.dart';

import 'models.dart';

/// Ordem e rótulos dos tipos de dia.
const _dayOrder = ['util', 'sabado', 'domingo'];
const _dayLabels = {
  'util': 'Dia Útil',
  'sabado': 'Sábado',
  'domingo': 'Dom./Feriado',
};

class LineDetailPage extends StatefulWidget {
  final BusLine line;
  const LineDetailPage({super.key, required this.line});

  @override
  State<LineDetailPage> createState() => _LineDetailPageState();
}

class _LineDetailPageState extends State<LineDetailPage> {
  late final List<String> _days;

  @override
  void initState() {
    super.initState();
    _days = _dayOrder
        .where((d) => widget.line.horarios.containsKey(d))
        .toList();
  }

  /// Tipo de dia correspondente à data de hoje.
  String _todayKey() {
    final wd = DateTime.now().weekday; // 1=Seg ... 7=Dom
    if (wd == 7) return 'domingo';
    if (wd == 6) return 'sabado';
    return 'util';
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.line;
    final initial = _days.indexOf(_todayKey());
    return DefaultTabController(
      length: _days.length,
      initialIndex: initial >= 0 ? initial : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.nome.isNotEmpty ? l.nome : 'Linha ${l.linha}'),
          bottom: TabBar(
            tabs: [for (final d in _days) Tab(text: _dayLabels[d] ?? d)],
          ),
        ),
        body: Column(
          children: [
            _InfoHeader(line: l),
            Expanded(
              child: TabBarView(
                children: [
                  for (final d in _days)
                    _DaySchedule(line: l, day: d, isToday: d == _todayKey()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  final BusLine line;
  const _InfoHeader({required this.line});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Linha ${line.linha}',
              style: Theme.of(context).textTheme.labelLarge),
          if (line.pontoA.isNotEmpty || line.pontoB.isNotEmpty)
            Text('${line.pontoA}  ⇄  ${line.pontoB}', style: style),
          if (line.empresa.isNotEmpty) Text('Empresa: ${line.empresa}', style: style),
          if (line.obs.isNotEmpty) Text(line.obs, style: style),
        ],
      ),
    );
  }
}

class _DaySchedule extends StatelessWidget {
  final BusLine line;
  final String day;
  final bool isToday;
  const _DaySchedule(
      {required this.line, required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final dirs = line.horarios[day] ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DirectionBlock(
          title: 'Ida — ${line.pontoA.isNotEmpty ? line.pontoA : "Ponto A"}',
          times: dirs['ida'] ?? const [],
          highlightNext: isToday,
        ),
        const SizedBox(height: 20),
        _DirectionBlock(
          title: 'Volta — ${line.pontoB.isNotEmpty ? line.pontoB : "Ponto B"}',
          times: dirs['volta'] ?? const [],
          highlightNext: isToday,
        ),
      ],
    );
  }
}

class _DirectionBlock extends StatelessWidget {
  final String title;
  final List<String> times;
  final bool highlightNext;
  const _DirectionBlock(
      {required this.title, required this.times, required this.highlightNext});

  /// Índice do próximo horário a partir de agora (-1 se nenhum).
  int _nextIndex() {
    if (!highlightNext) return -1;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    for (var i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      if (parts.length < 2) continue;
      final m = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      if (m >= nowMin) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final next = _nextIndex();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (times.isEmpty)
          const Text('Sem horários neste dia.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < times.length; i++)
                _TimeChip(
                  time: times[i],
                  isNext: i == next,
                  isPast: highlightNext && next >= 0 && i < next,
                ),
            ],
          ),
        if (next >= 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Próximo: ${times[next]}',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final bool isNext;
  final bool isPast;
  const _TimeChip(
      {required this.time, required this.isNext, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    if (isNext) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (isPast) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurfaceVariant.withValues(alpha: 0.5);
    } else {
      bg = cs.secondaryContainer;
      fg = cs.onSecondaryContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: isNext ? Border.all(color: cs.primary, width: 2) : null,
      ),
      child: Text(time,
          style: TextStyle(
              color: fg,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              fontFeatures: const [],
              fontSize: 15)),
    );
  }
}
