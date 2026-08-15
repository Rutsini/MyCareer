// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/subject.dart';
import '../../application/subject_controller.dart';

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({required this.subjectId, super.key});
  final String subjectId;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(subjectProvider(subjectId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const ContentPage(
              title: 'Materia', child: Text('No pudimos cargar la materia.')),
          data: (s) {
            if (s == null)
              return const ContentPage(
                  title: 'Materia', child: Text('La materia no existe.'));
            return ContentPage(
                title: s.name,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.go(AppRoutes.editSubject(s.id)),
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'))),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child:
                                  Wrap(spacing: 40, runSpacing: 20, children: [
                                _Item('Nombre corto', s.shortName ?? '—'),
                                _Item('Comisión', s.commission ?? '—'),
                                _Item('Año', '${s.academicYear}'),
                                _Item(
                                    'Tipo',
                                    s.subjectType == SubjectType.mandatory
                                        ? 'Obligatoria'
                                        : 'Electiva'),
                                _Item(
                                    'Duración',
                                    s.duration == SubjectDuration.annual
                                        ? 'Anual'
                                        : s.semester == Semester.first
                                            ? '1°C'
                                            : '2°C'),
                                _Item(
                                    'Estado / resultado',
                                    s.trackingMode == TrackingMode.tracked
                                        ? 'Sin datos'
                                        : _label(s.finalOutcome)),
                                _Item('Nota final',
                                    s.finalGrade?.toString() ?? '—')
                              ]))),
                      if (s.trackingMode == TrackingMode.tracked) ...[
                        const SizedBox(height: 16),
                        const Card(
                            child: ListTile(
                                leading: Icon(Icons.info_outline),
                                title: Text('Resumen'),
                                subtitle: Text(
                                    'Evaluaciones y condiciones estarán disponibles en la próxima versión.')))
                      ]
                    ]));
          });
  String _label(FinalOutcome? v) => switch (v) {
        FinalOutcome.approved => 'Aprobada',
        FinalOutcome.promoted => 'Promocionada',
        FinalOutcome.regularized => 'Regularizada',
        FinalOutcome.failed => 'Desaprobada',
        FinalOutcome.abandoned => 'Abandonada',
        null => '—'
      };
}

class _Item extends StatelessWidget {
  const _Item(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 180,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium)
      ]));
}
