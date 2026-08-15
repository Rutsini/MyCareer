// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../../domain/entities/subject.dart';
import '../../../subjects/application/subject_controller.dart';
import '../../application/evaluation_controller.dart';

class EvaluationFormScreen extends ConsumerStatefulWidget {
  const EvaluationFormScreen(
      {this.evaluationId, this.subjectId, this.date, super.key});
  final String? evaluationId;
  final String? subjectId;
  final DateTime? date;

  @override
  ConsumerState<EvaluationFormScreen> createState() =>
      _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends ConsumerState<EvaluationFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _grade = TextEditingController();
  final _maxGrade = TextEditingController(text: '10');
  final _minimum = TextEditingController();
  final _weight = TextEditingController(text: '1');
  final _notes = TextEditingController();
  String? _subjectId;
  String? _recoveryOf;
  DateTime _date = DateTime.now();
  EvaluationType _type = EvaluationType.partial;
  EvaluationStatus _status = EvaluationStatus.pending;
  bool _allDay = true;
  bool _mandatory = true;
  bool _counts = true;
  bool? _presented;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjectId;
    _date = widget.date ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _grade,
      _maxGrade,
      _minimum,
      _weight,
      _notes
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  void _load(Evaluation evaluation) {
    if (_initialized) return;
    _initialized = true;
    _subjectId = evaluation.subjectId;
    _name.text = evaluation.name;
    _type = evaluation.type;
    _date = evaluation.date;
    _allDay = evaluation.allDay;
    _mandatory = evaluation.mandatory;
    _counts = evaluation.countsTowardAverage;
    _grade.text = evaluation.grade?.toString() ?? '';
    _maxGrade.text = evaluation.maxGrade.toString();
    _minimum.text = evaluation.minimumPassingGradeOverride?.toString() ?? '';
    _weight.text = evaluation.weight.toString();
    _presented = evaluation.presented;
    _status = evaluation.status;
    _recoveryOf = evaluation.recoveryOfEvaluationId;
    _notes.text = evaluation.notes ?? '';
  }

  Evaluation _build(List<Subject> subjects) {
    final subject = subjects.firstWhere((item) => item.id == _subjectId);
    final recovery = _type == EvaluationType.recovery;
    final now = DateTime.now();
    return Evaluation(
      id: widget.evaluationId ?? '',
      subjectId: subject.id,
      academicYear: subject.academicYear,
      name: _name.text,
      type: _type,
      date: _date,
      allDay: _allDay,
      mandatory: _mandatory,
      countsTowardAverage: _counts,
      grade: _number(_grade.text),
      maxGrade: _number(_maxGrade.text) ?? 0,
      minimumPassingGradeOverride: _number(_minimum.text),
      weight: _number(_weight.text) ?? 0,
      presented: _presented,
      status: _status,
      isRecovery: recovery,
      recoveryOfEvaluationId: recovery ? _recoveryOf : null,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _save(List<Subject> subjects) async {
    if (!_form.currentState!.validate() || _subjectId == null) return;
    final id = await ref
        .read(evaluationControllerProvider.notifier)
        .save(_build(subjects));
    if (!mounted || id == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluación guardada correctamente.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final existing = widget.evaluationId == null
        ? null
        : ref.watch(evaluationProvider(widget.evaluationId!));
    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const ContentPage(
          title: 'Evaluación', child: Text('No pudimos cargar tus materias.')),
      data: (allSubjects) {
        final subjects = allSubjects
            .where((s) => s.trackingMode == TrackingMode.tracked)
            .toList();
        if (existing?.isLoading == true)
          return const Center(child: CircularProgressIndicator());
        if (existing?.hasError == true)
          return const ContentPage(
              title: 'Evaluación',
              child: Text('No pudimos cargar la evaluación.'));
        if (existing?.valueOrNull case final evaluation?) _load(evaluation);
        if (!_initialized && widget.evaluationId == null) {
          _initialized = true;
          if (_subjectId != null) {
            final subject =
                subjects.where((s) => s.id == _subjectId).firstOrNull;
            if (subject != null) _maxGrade.text = subject.gradeMax.toString();
          }
        }
        final evaluations =
            ref.watch(evaluationsProvider).valueOrNull ?? const <Evaluation>[];
        final originals = evaluations
            .where((e) =>
                e.subjectId == _subjectId &&
                !e.isRecovery &&
                e.id != widget.evaluationId)
            .toList();
        final state = ref.watch(evaluationControllerProvider);
        return ContentPage(
          title: widget.evaluationId == null
              ? 'Nueva evaluación'
              : 'Editar evaluación',
          child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: subjects.any((s) => s.id == _subjectId)
                        ? _subjectId
                        : null,
                    decoration: const InputDecoration(labelText: 'Materia *'),
                    items: subjects
                        .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (value) => setState(() {
                      _subjectId = value;
                      _recoveryOf = null;
                      final subject = subjects.firstWhere((s) => s.id == value);
                      _maxGrade.text = subject.gradeMax.toString();
                    }),
                    validator: (value) =>
                        value == null ? 'Seleccioná una materia.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nombre *'),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        return length < 2 || length > 100
                            ? 'Ingresá entre 2 y 100 caracteres.'
                            : null;
                      }),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EvaluationType>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Tipo *'),
                      items: EvaluationType.values
                          .map((v) => DropdownMenuItem(
                              value: v, child: Text(_typeLabel(v))))
                          .toList(),
                      onChanged: (value) => setState(() {
                            _type = value!;
                            if (_type != EvaluationType.recovery)
                              _recoveryOf = null;
                          })),
                  if (_type == EvaluationType.recovery) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        value: originals.any((e) => e.id == _recoveryOf)
                            ? _recoveryOf
                            : null,
                        decoration: const InputDecoration(
                            labelText: 'Evaluación que recupera *'),
                        items: originals
                            .map((e) => DropdownMenuItem(
                                value: e.id, child: Text(e.name)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _recoveryOf = value),
                        validator: (value) => value == null
                            ? 'Seleccioná la evaluación original.'
                            : null),
                  ],
                  const SizedBox(height: 12),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha *'),
                      subtitle:
                          Text('${_date.day}/${_date.month}/${_date.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final value = await showDatePicker(
                            context: context,
                            firstDate: DateTime(1950),
                            lastDate: DateTime(2200),
                            initialDate: _date);
                        if (value != null) setState(() => _date = value);
                      }),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Todo el día'),
                      value: _allDay,
                      onChanged: (v) => setState(() => _allDay = v)),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Obligatoria'),
                      value: _mandatory,
                      onChanged: (v) => setState(() => _mandatory = v)),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Participa del promedio'),
                      value: _counts,
                      onChanged: (v) => setState(() => _counts = v)),
                  Row(children: [
                    Expanded(child: _numberField(_grade, 'Nota (opcional)')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(_maxGrade, 'Nota máxima *'))
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _numberField(
                            _minimum, 'Nota mínima de aprobación')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(_weight, 'Peso *'))
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EvaluationStatus>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: EvaluationStatus.values
                          .map((v) => DropdownMenuItem(
                              value: v, child: Text(_statusLabel(v))))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool?>(
                      value: _presented,
                      decoration: const InputDecoration(
                          labelText: 'Presentada (opcional)'),
                      items: const [
                        DropdownMenuItem(
                            value: null, child: Text('Sin indicar')),
                        DropdownMenuItem(value: true, child: Text('Sí')),
                        DropdownMenuItem(value: false, child: Text('No'))
                      ],
                      onChanged: (v) => setState(() => _presented = v)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Notas / observaciones')),
                  if (state.hasError)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text((state.error as AppException).message,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: state.isLoading ? null : () => _save(subjects),
                      child: const Text('Guardar')),
                ]),
          ),
        );
      },
    );
  }

  Widget _numberField(TextEditingController controller, String label) =>
      TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label));
}

String _typeLabel(EvaluationType value) => switch (value) {
      EvaluationType.partial => 'Parcial',
      EvaluationType.recovery => 'Recuperatorio',
      EvaluationType.practicalWork => 'Trabajo práctico',
      EvaluationType.deliverable => 'Entregable',
      EvaluationType.project => 'Proyecto',
      EvaluationType.colloquium => 'Coloquio',
      EvaluationType.finalExam => 'Examen final',
      EvaluationType.other => 'Otro',
    };
String _statusLabel(EvaluationStatus value) => switch (value) {
      EvaluationStatus.pending => 'Pendiente',
      EvaluationStatus.submitted => 'Presentada / Entregada',
      EvaluationStatus.approved => 'Aprobada',
      EvaluationStatus.failed => 'Desaprobada',
      EvaluationStatus.absent => 'Ausente',
      EvaluationStatus.recovered => 'Recuperada',
    };
