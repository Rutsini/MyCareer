import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/formatters/evaluation_type_formatter.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../application/evaluation_controller.dart';

Future<void> openEvaluationActivity(
  BuildContext context,
  WidgetRef ref, {
  required Evaluation evaluation,
  required String subjectName,
}) async {
  final content = EvaluationActivitySheet(
    evaluation: evaluation,
    subjectName: subjectName,
  );
  final Future<bool?> result;
  if (MediaQuery.sizeOf(context).width < 700) {
    result = showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => content,
    );
  } else {
    result = showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
          child: content,
        ),
      ),
    );
  }
  final saved = await result;
  if (!context.mounted) return;
  if (saved == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resultado guardado.')),
    );
  }
}

class EvaluationActivitySheet extends ConsumerStatefulWidget {
  const EvaluationActivitySheet({
    required this.evaluation,
    required this.subjectName,
    super.key,
  });

  final Evaluation evaluation;
  final String subjectName;

  @override
  ConsumerState<EvaluationActivitySheet> createState() =>
      _EvaluationActivitySheetState();
}

class _EvaluationActivitySheetState
    extends ConsumerState<EvaluationActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _grade = TextEditingController();
  EvaluationStatus _status = EvaluationStatus.approved;
  bool _submitting = false;
  String? _saveError;

  @override
  void dispose() {
    _grade.dispose();
    super.dispose();
  }

  double? _parsedGrade() {
    if (_status == EvaluationStatus.absent) return null;
    final text = _grade.text.trim();
    return text.isEmpty ? null : double.tryParse(text.replaceAll(',', '.'));
  }

  String? _validateGrade(String? value) {
    if (_status == EvaluationStatus.absent) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final grade = double.tryParse(text.replaceAll(',', '.'));
    if (grade == null) return 'Ingresá una nota válida.';
    return widget.evaluation
        .copyWith(
          grade: grade,
          status: _status,
          updatedAt: DateTime.now(),
        )
        .validate();
  }

  Future<void> _save() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    final grade = _parsedGrade();
    final updated = widget.evaluation.copyWith(
      grade: grade,
      clearGrade: grade == null,
      status: _status,
      updatedAt: DateTime.now(),
    );
    final id =
        await ref.read(evaluationControllerProvider.notifier).save(updated);
    if (!mounted) return;
    if (id != null) {
      Navigator.pop(context, true);
      return;
    }
    final state = ref.read(evaluationControllerProvider);
    final error = state.error;
    setState(() {
      _submitting = false;
      _saveError = error is AppException
          ? error.message
          : 'No pudimos guardar el resultado. Intentá nuevamente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.evaluation.status == EvaluationStatus.pending;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: pending ? _resultForm(context) : _readOnlyDetail(context),
        ),
      ),
    );
  }

  Widget _resultForm(BuildContext context) => Form(
        key: _formKey,
        child: Column(
          key: const Key('evaluation-result-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            const SizedBox(height: 20),
            _information(),
            const SizedBox(height: 24),
            Text(
              'Registrar resultado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('result-grade-field'),
                    controller: _grade,
                    enabled: !_submitting && _status != EvaluationStatus.absent,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Nota'),
                    validator: _validateGrade,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text('/ ${_number(widget.evaluation.maxGrade)}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EvaluationStatus>(
              key: const Key('result-status-field'),
              initialValue: _status,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Estado final'),
              items: EvaluationStatus.values
                  .where((status) => status != EvaluationStatus.pending)
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(evaluationStatusLabel(status)),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _status = value;
                        if (value == EvaluationStatus.absent) _grade.clear();
                      });
                    },
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                key: const Key('result-save-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed:
                      _submitting ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  key: const Key('save-evaluation-result'),
                  onPressed: _submitting ? null : _save,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Guardar y finalizar'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _readOnlyDetail(BuildContext context) {
    final evaluation = widget.evaluation;
    final enabledReminders =
        evaluation.reminders.where((reminder) => reminder.enabled).length;
    return Column(
      key: const Key('evaluation-read-only-detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context),
        const SizedBox(height: 20),
        _information(),
        const SizedBox(height: 20),
        Text('Resultado', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          evaluationStatusLabel(evaluation.status),
          key: const Key('activity-specific-status'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (evaluation.grade != null) ...[
          const SizedBox(height: 12),
          Text(
            'Nota: ${_number(evaluation.grade!)} / ${_number(evaluation.maxGrade)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          '${evaluationTypeLabel(evaluation.type)} · '
          '${evaluation.mandatory ? 'Obligatoria' : 'Opcional'}',
        ),
        Text('Peso: ${_number(evaluation.weight)}'),
        Text(
          'Presentada: ${evaluation.presented == null ? 'Sin registrar' : evaluation.presented! ? 'Sí' : 'No'}',
        ),
        if (enabledReminders > 0)
          Text(
            '$enabledReminders ${enabledReminders == 1 ? 'recordatorio activo' : 'recordatorios activos'}',
          ),
        if (evaluation.notes?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text('Observaciones', style: Theme.of(context).textTheme.labelLarge),
          Text(evaluation.notes!.trim()),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          key: const Key('view-subject-evaluations'),
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.pop(context);
            router.go(
              '${AppRoutes.subject(evaluation.subjectId)}?tab=evaluations',
            );
          },
          icon: const Icon(Icons.school_outlined),
          label: const Text('Ver evaluaciones de la materia'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_available_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.evaluation.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: _submitting ? null : () => Navigator.pop(context, false),
            icon: const Icon(Icons.close),
          ),
        ],
      );

  Widget _information() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Info('Materia', widget.subjectName),
          _Info('Fecha', _date(widget.evaluation.date)),
          if (!widget.evaluation.allDay)
            _Info('Hora', _time(widget.evaluation.date)),
          _Info('Tipo', evaluationTypeLabel(widget.evaluation.type)),
          _Info(
            'Modalidad',
            widget.evaluation.mandatory ? 'Obligatoria' : 'Opcional',
          ),
        ],
      );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}

String evaluationStatusLabel(EvaluationStatus status) => switch (status) {
      EvaluationStatus.pending => 'Pendiente',
      EvaluationStatus.submitted => 'Presentada / Entregada',
      EvaluationStatus.approved => 'Aprobada',
      EvaluationStatus.failed => 'Desaprobada',
      EvaluationStatus.absent => 'Ausente',
      EvaluationStatus.recovered => 'Recuperada',
    };

String _date(DateTime value) =>
    '${value.day} ${_months[value.month - 1]} ${value.year}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];
