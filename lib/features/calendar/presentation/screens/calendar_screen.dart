import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../evaluations/application/evaluation_controller.dart';
import '../../../subjects/application/subject_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  @override
  Widget build(BuildContext context) => ContentPage(
      title: 'Calendario',
      child: ref.watch(evaluationsProvider).when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('No pudimos cargar el calendario.'),
          data: (evaluations) {
            final monthly = evaluations
                .where((e) =>
                    e.date.year == month.year && e.date.month == month.month)
                .toList();
            return Column(children: [
              Row(children: [
                IconButton(
                    onPressed: () => setState(
                        () => month = DateTime(month.year, month.month - 1)),
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                    child: Text('${_months[month.month - 1]} ${month.year}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    onPressed: () => setState(
                        () => month = DateTime(month.year, month.month + 1)),
                    icon: const Icon(Icons.chevron_right))
              ]),
              Row(children: [
                for (final day in [
                  'Lun',
                  'Mar',
                  'Mié',
                  'Jue',
                  'Vie',
                  'Sáb',
                  'Dom'
                ])
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(day, textAlign: TextAlign.center)))
              ]),
              LayoutBuilder(builder: (context, constraints) {
                final firstOffset =
                    DateTime(month.year, month.month, 1).weekday - 1;
                final days = DateTime(month.year, month.month + 1, 0).day;
                final rows = ((firstOffset + days) / 7).ceil();
                return SizedBox(
                    height: constraints.maxWidth < 600 ? rows * 58 : rows * 82,
                    child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7),
                        itemCount: rows * 7,
                        itemBuilder: (_, index) {
                          final day = index - firstOffset + 1;
                          if (day < 1 || day > days) return const SizedBox();
                          final date = DateTime(month.year, month.month, day);
                          final hasItems =
                              monthly.any((e) => _sameDay(e.date, date));
                          return Card(
                              margin: const EdgeInsets.all(2),
                              child: InkWell(
                                  onTap: () => _showDay(date, evaluations),
                                  child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Column(children: [
                                        Text('$day'),
                                        if (hasItems)
                                          Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  shape: BoxShape.circle))
                                      ]))));
                        }));
              }),
            ]);
          }));

  Future<void> _showDay(DateTime date, List<Evaluation> all) async {
    final items = all.where((e) => _sameDay(e.date, date)).toList();
    final subjects = ref.read(subjectsProvider).valueOrNull ?? const [];
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          '${date.day} de ${_months[date.month - 1].toLowerCase()} de ${date.year}',
          style: Theme.of(context).textTheme.titleLarge),
      Text(
          '${items.length} ${items.length == 1 ? 'actividad' : 'actividades'}'),
      const SizedBox(height: 12),
      if (items.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No hay actividades para este día.')),
      ...items.map((e) {
        final subject = subjects.where((s) => s.id == e.subjectId).firstOrNull;
        return Card(
            child: ListTile(
                title: Text(subject?.name ?? 'Materia'),
                subtitle: Text(e.reminders.where((r) => r.enabled).isEmpty
                    ? e.name
                    : '${e.name} · 🔔 ${e.reminders.where((r) => r.enabled).length}'),
                trailing: Text(_status(e.status))));
      }),
      const Spacer(),
      FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            context.push(
                '${AppRoutes.newEvaluation}?date=${date.toIso8601String().substring(0, 10)}');
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar actividad'))
    ]);
    if (!mounted) return;
    if (MediaQuery.sizeOf(context).width < 700) {
      await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child:
                  Padding(padding: const EdgeInsets.all(20), child: content)));
    } else {
      await showDialog<void>(
          context: context,
          builder: (_) => Dialog(
              child: SizedBox(
                  width: 480,
                  height: 520,
                  child: Padding(
                      padding: const EdgeInsets.all(24), child: content))));
    }
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
const _months = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre'
];
String _status(EvaluationStatus value) => switch (value) {
      EvaluationStatus.pending => 'Pendiente',
      EvaluationStatus.submitted => 'Presentada',
      EvaluationStatus.approved => 'Aprobada',
      EvaluationStatus.failed => 'Desaprobada',
      EvaluationStatus.absent => 'Ausente',
      EvaluationStatus.recovered => 'Recuperada'
    };
