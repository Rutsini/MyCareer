// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../../domain/entities/subject.dart';
import '../../../../domain/services/evaluation_calculator.dart';
import '../../../../domain/services/academic_engine.dart';
import '../../../evaluations/application/evaluation_controller.dart';
import '../../application/subject_controller.dart';
import '../../application/academic_controller.dart';
import '../widgets/conditions_tab.dart';

enum _Filter { all, pending, completed, partial, practicalWork, recovery }

class SubjectDetailScreen extends ConsumerStatefulWidget {
  const SubjectDetailScreen({required this.subjectId, super.key});
  final String subjectId;
  @override
  ConsumerState<SubjectDetailScreen> createState() => _State();
}

class _State extends ConsumerState<SubjectDetailScreen> {
  _Filter filter = _Filter.all;
  @override
  Widget build(BuildContext context) =>
      ref.watch(subjectProvider(widget.subjectId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const ContentPage(
              title: 'Materia', child: Text('No pudimos cargar la materia.')),
          data: (subject) {
            if (subject == null)
              return const ContentPage(
                  title: 'Materia', child: Text('La materia no existe.'));
            if (subject.trackingMode == TrackingMode.historical)
              return ContentPage(
                  title: subject.name, child: _summaryCard(subject, const []));
            return DefaultTabController(
                length: 3,
                child: ContentPage(
                    title: subject.name,
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        OutlinedButton.icon(
                            onPressed: () =>
                                context.go(AppRoutes.editSubject(subject.id)),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar')),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                            onPressed: () => context.push(
                                '${AppRoutes.newEvaluation}?subjectId=${subject.id}'),
                            icon: const Icon(Icons.add),
                            label: const Text('Evaluación'))
                      ]),
                      const TabBar(tabs: [
                        Tab(text: 'Resumen'),
                        Tab(text: 'Evaluaciones'),
                        Tab(text: 'Condiciones')
                      ]),
                      SizedBox(
                          height: 560,
                          child: TabBarView(children: [
                            ref.watch(subjectEvaluationsProvider(subject.id)).when(
                                loading: () => const LinearProgressIndicator(),
                                error: (_, __) => const Text(
                                    'No pudimos cargar tus evaluaciones.'),
                                data: (items) => _summaryCard(subject, items)),
                            _evaluationList(subject),
                            ConditionsTab(subject: subject),
                          ]))
                    ])));
          });

  Widget _summaryCard(Subject subject, List<Evaluation> items) {
    final average = EvaluationCalculator.currentAverage(subject, items);
    final academic = subject.trackingMode == TrackingMode.tracked
        ? const AcademicEngine().evaluate(subject: subject, evaluations: items)
        : null;
    final next =
        EvaluationCalculator.nextEvaluation(items, subjectId: subject.id);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(spacing: 40, runSpacing: 20, children: [
              _Item('Año', '${subject.academicYear}'),
              _Item(
                  'Condición actual',
                  subject.trackingMode == TrackingMode.tracked
                      ? ref
                              .watch(subjectAcademicResultProvider(subject.id))
                              .valueOrNull
                              ?.summary ??
                          'Sin datos'
                      : subject.finalOutcome?.name ?? '—'),
              _Item(
                  subject.trackingMode == TrackingMode.tracked
                      ? 'Promedio actual'
                      : 'Nota final',
                  subject.trackingMode == TrackingMode.historical
                      ? subject.finalGrade?.toString() ?? '—'
                      : average?.toStringAsFixed(2).replaceAll('.', ',') ??
                          '—'),
              if (subject.trackingMode == TrackingMode.tracked)
                _Item(
                    'Próxima evaluación',
                    next == null
                        ? '—'
                        : '${next.date.day}/${next.date.month} · ${next.name}'),
              if (academic != null && academic.promotionConfigured)
                _Item('Promoción',
                    '${academic.promotionResults.where((r) => r.status == RuleResultStatus.met).length} / ${academic.promotionResults.length} cumplidos'),
              if (academic != null && academic.regularityConfigured)
                _Item('Regularidad',
                    '${academic.regularityResults.where((r) => r.status == RuleResultStatus.met).length} / ${academic.regularityResults.length} cumplidos')
            ])));
  }

  Widget _evaluationList(Subject subject) =>
      ref.watch(subjectEvaluationsProvider(subject.id)).when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('No pudimos cargar tus evaluaciones.'),
          data: (all) {
            final items = all.where(_matches).toList();
            final now = DateTime.now();
            final upcoming = items
                .where((e) =>
                    e.status == EvaluationStatus.pending &&
                    !e.date.isBefore(now))
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
            final completed = items.where((e) => !upcoming.contains(e)).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            return ListView(padding: const EdgeInsets.only(top: 16), children: [
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: _Filter.values
                          .map((v) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                  label: Text(_filterLabel(v)),
                                  selected: filter == v,
                                  onSelected: (_) =>
                                      setState(() => filter = v))))
                          .toList())),
              if (upcoming.isNotEmpty) ...[
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Próximas')),
                ...upcoming.map(_card)
              ],
              if (completed.isNotEmpty) ...[
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Realizadas')),
                ...completed.map(_card)
              ],
              if (items.isEmpty)
                const Card(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Todavía no hay evaluaciones con este filtro.')))
            ]);
          });

  Widget _card(Evaluation e) => Card(
      child: ListTile(
          title: Text(e.name),
          isThreeLine: true,
          subtitle: Text(
              '${_typeLabel(e.type)} · ${e.date.day}/${e.date.month}/${e.date.year}\n${_statusLabel(e.status)} · ${e.mandatory ? 'Obligatoria' : 'Opcional'} · Peso ${_n(e.weight)}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(e.grade == null ? '—' : '${_n(e.grade!)} / ${_n(e.maxGrade)}'),
            PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') context.push(AppRoutes.editEvaluation(e.id));
                  if (v == 'grade') _quickGrade(e);
                  if (v == 'delete') _delete(e);
                },
                itemBuilder: (_) => [
                      if (e.status == EvaluationStatus.pending)
                        const PopupMenuItem(
                            value: 'grade', child: Text('Cargar nota')),
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Eliminar'))
                    ])
          ])));

  Future<void> _quickGrade(Evaluation e) async {
    final input = TextEditingController();
    var status = e.status;
    final accepted = await showDialog<bool>(
        context: context,
        builder: (dc) => StatefulBuilder(
            builder: (_, setLocal) => AlertDialog(
                    title: const Text('Cargar nota'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: input,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Nota (máximo ${_n(e.maxGrade)})')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField(
                          value: status,
                          decoration: const InputDecoration(
                              labelText: 'Estado (opcional)'),
                          items: EvaluationStatus.values
                              .map((v) => DropdownMenuItem(
                                  value: v, child: Text(_statusLabel(v))))
                              .toList(),
                          onChanged: (v) => setLocal(() => status = v!))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dc, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dc, true),
                          child: const Text('Guardar'))
                    ])));
    final grade = double.tryParse(input.text.replaceAll(',', '.'));
    input.dispose();
    if (accepted == true && grade != null) {
      final saved = await ref.read(evaluationControllerProvider.notifier).save(
          e.copyWith(grade: grade, status: status, updatedAt: DateTime.now()));
      if (mounted && saved != null)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota cargada correctamente.')));
    }
  }

  Future<void> _delete(Evaluation e) async {
    final linked =
        (ref.read(evaluationsProvider).valueOrNull ?? const <Evaluation>[])
            .any((v) => v.recoveryOfEvaluationId == e.id);
    final ok = await showDialog<bool>(
            context: context,
            builder: (dc) => AlertDialog(
                    title: Text('¿Eliminar ${e.name}?'),
                    content: Text(linked
                        ? 'También se eliminarán sus recuperatorios asociados. Esta acción no se puede deshacer.'
                        : 'Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dc, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dc, true),
                          child: const Text('Eliminar'))
                    ])) ??
        false;
    if (ok) await ref.read(evaluationControllerProvider.notifier).delete(e.id);
  }

  bool _matches(Evaluation e) => switch (filter) {
        _Filter.all => true,
        _Filter.pending => e.status == EvaluationStatus.pending,
        _Filter.completed => e.status != EvaluationStatus.pending,
        _Filter.partial => e.type == EvaluationType.partial,
        _Filter.practicalWork => e.type == EvaluationType.practicalWork,
        _Filter.recovery => e.type == EvaluationType.recovery
      };
}

class _Item extends StatelessWidget {
  const _Item(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 190,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium)
      ]));
}

String _n(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
String _filterLabel(_Filter v) => switch (v) {
      _Filter.all => 'Todas',
      _Filter.pending => 'Pendientes',
      _Filter.completed => 'Realizadas',
      _Filter.partial => 'Parciales',
      _Filter.practicalWork => 'TP',
      _Filter.recovery => 'Recuperatorios'
    };
String _typeLabel(EvaluationType v) => switch (v) {
      EvaluationType.partial => 'Parcial',
      EvaluationType.recovery => 'Recuperatorio',
      EvaluationType.practicalWork => 'Trabajo práctico',
      EvaluationType.deliverable => 'Entregable',
      EvaluationType.project => 'Proyecto',
      EvaluationType.colloquium => 'Coloquio',
      EvaluationType.finalExam => 'Examen final',
      EvaluationType.other => 'Otro'
    };
String _statusLabel(EvaluationStatus v) => switch (v) {
      EvaluationStatus.pending => 'Pendiente',
      EvaluationStatus.submitted => 'Presentada / Entregada',
      EvaluationStatus.approved => 'Aprobada',
      EvaluationStatus.failed => 'Desaprobada',
      EvaluationStatus.absent => 'Ausente',
      EvaluationStatus.recovered => 'Recuperada'
    };
