import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/subject.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../subjects/application/subject_controller.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider),
        profile = ref.watch(userProfileProvider);
    return ContentPage(
        title: 'Progreso académico',
        child: subjects.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('No pudimos cargar tu progreso.'),
            data: (all) {
              final graded = all
                  .where((s) =>
                      (s.finalOutcome == FinalOutcome.approved ||
                          s.finalOutcome == FinalOutcome.promoted) &&
                      s.finalGrade != null)
                  .toList();
              final avg = graded.isEmpty
                  ? null
                  : graded.fold<double>(0, (sum, s) => sum + s.finalGrade!) /
                      graded.length;
              final obtained = all
                  .where((s) =>
                      s.subjectType == SubjectType.elective &&
                      (s.finalOutcome == FinalOutcome.approved ||
                          s.finalOutcome == FinalOutcome.promoted))
                  .fold<double>(0, (sum, s) => sum + (s.electivePoints ?? 0));
              final active = all
                  .where((s) =>
                      s.subjectType == SubjectType.elective &&
                      s.trackingMode == TrackingMode.tracked &&
                      s.courseStatus == CourseStatus.active)
                  .fold<double>(0, (sum, s) => sum + (s.electivePoints ?? 0));
              final history = all.where((s) => s.finalOutcome != null).toList()
                ..sort((a, b) => b.academicYear.compareTo(a.academicYear));
              final grouped = <int, List<Subject>>{};
              for (final s in history) {
                grouped.putIfAbsent(s.academicYear, () => []).add(s);
              }
              final required =
                  profile.valueOrNull?.career.requiredElectivePoints;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      _Metric(
                          'Promedio general',
                          avg == null
                              ? '—'
                              : avg.toStringAsFixed(2).replaceAll('.', ',')),
                      _Metric('Puntos obtenidos', _n(obtained)),
                      _Metric('En curso', _n(active)),
                      _Metric('Requeridos',
                          required == null ? 'Sin configurar' : _n(required))
                    ]),
                    const SizedBox(height: 24),
                    Text('Historial académico',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    if (grouped.isEmpty)
                      const Card(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child:
                                  Text('Todavía no hay materias finalizadas.')))
                    else
                      ...grouped.entries.map((e) => Card(
                          child: ExpansionTile(
                              initiallyExpanded: true,
                              title: Text('${e.key}'),
                              children: e.value
                                  .map((s) => ListTile(
                                      title: Text(s.name),
                                      subtitle: Text(_label(s.finalOutcome)),
                                      trailing: Text(
                                          s.finalGrade?.toString() ?? '—')))
                                  .toList())))
                  ]);
            }));
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  String _label(FinalOutcome? v) => switch (v) {
        FinalOutcome.approved => 'Aprobada',
        FinalOutcome.promoted => 'Promocionada',
        FinalOutcome.regularized => 'Regularizada',
        FinalOutcome.failed => 'Desaprobada',
        FinalOutcome.abandoned => 'Abandonada',
        null => '—'
      };
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 210,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label),
                    const SizedBox(height: 8),
                    Text(value,
                        style: Theme.of(context).textTheme.headlineSmall)
                  ]))));
}
