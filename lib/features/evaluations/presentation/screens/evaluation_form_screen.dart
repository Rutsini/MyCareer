// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/formatters/evaluation_type_formatter.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../../domain/entities/evaluation_reminder.dart';
import '../../../../domain/entities/subject.dart';
import '../../../subjects/application/subject_controller.dart';
import '../../application/evaluation_controller.dart';
import '../../../profile/application/profile_controller.dart';

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
  bool _submitting = false;
  List<EvaluationReminder> _reminders = [];

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
    _reminders = List.of(evaluation.reminders);
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
      reminders: List.unmodifiable(_reminders),
    );
  }

  Future<void> _save(List<Subject> subjects) async {
    if (_submitting) return;
    if (!_form.currentState!.validate() || _subjectId == null) return;
    setState(() => _submitting = true);
    try {
      final evaluation = _build(subjects);
      final id = await ref
          .read(evaluationControllerProvider.notifier)
          .save(evaluation);
      if (!mounted || id == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluación guardada correctamente.')));
      if (widget.evaluationId != null && context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.subject(evaluation.subjectId));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goBackFallback() => context.go(
      _subjectId == null ? AppRoutes.calendar : AppRoutes.subject(_subjectId!));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final existing = widget.evaluationId == null
        ? null
        : ref.watch(evaluationProvider(widget.evaluationId!));
    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ContentPage(
          title: 'Evaluación',
          showBackButton: true,
          backFallback: _goBackFallback,
          child: const Text('No pudimos cargar tus materias.')),
      data: (allSubjects) {
        final subjects = allSubjects
            .where((s) => s.trackingMode == TrackingMode.tracked)
            .toList();
        if (existing?.isLoading == true)
          return const Center(child: CircularProgressIndicator());
        if (existing?.hasError == true)
          return ContentPage(
              title: 'Evaluación',
              showBackButton: true,
              backFallback: _goBackFallback,
              child: const Text('No pudimos cargar la evaluación.'));
        if (existing?.valueOrNull case final evaluation?) _load(evaluation);
        if (!_initialized && widget.evaluationId == null) {
          _initialized = true;
          if (_subjectId != null) {
            final subject =
                subjects.where((s) => s.id == _subjectId).firstOrNull;
            if (subject != null) _maxGrade.text = subject.gradeMax.toString();
          }
          final defaults = ref
                  .read(userProfileProvider)
                  .valueOrNull
                  ?.settings
                  .notifications
                  .defaultReminderOffsetsMinutes ??
              const <int>[1440];
          _reminders = defaults
              .where((offset) => _allDay ? offset % 1440 == 0 : true)
              .take(5)
              .map((offset) => EvaluationReminder(
                    id: 'reminder_${DateTime.now().microsecondsSinceEpoch}_$offset',
                    offsetMinutes: offset,
                  ))
              .toList();
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
          showBackButton: true,
          backFallback: _goBackFallback,
          child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fieldLabel(
                      'Materia *',
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: subjects.any((s) => s.id == _subjectId)
                            ? _subjectId
                            : null,
                        decoration: const InputDecoration(),
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                value: s.id, child: Text(s.name)))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _subjectId = value;
                          _recoveryOf = null;
                          final subject =
                              subjects.firstWhere((s) => s.id == value);
                          _maxGrade.text = subject.gradeMax.toString();
                        }),
                        validator: (value) =>
                            value == null ? 'Seleccioná una materia.' : null,
                      )),
                  const SizedBox(height: 16),
                  _fieldLabel(
                      'Nombre *',
                      TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(),
                          validator: (value) {
                            final length = value?.trim().length ?? 0;
                            return length < 2 || length > 100
                                ? 'Ingresá entre 2 y 100 caracteres.'
                                : null;
                          })),
                  const SizedBox(height: 16),
                  _fieldLabel(
                      'Tipo *',
                      DropdownButtonFormField<EvaluationType>(
                          isExpanded: true,
                          value: _type,
                          decoration: const InputDecoration(),
                          items: EvaluationType.values
                              .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(evaluationTypeLabel(v))))
                              .toList(),
                          onChanged: (value) => setState(() {
                                _type = value!;
                                if (_type != EvaluationType.recovery)
                                  _recoveryOf = null;
                              }))),
                  if (_type == EvaluationType.recovery) ...[
                    const SizedBox(height: 12),
                    _fieldLabel(
                        'Evaluación que recupera *',
                        DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: originals.any((e) => e.id == _recoveryOf)
                                ? _recoveryOf
                                : null,
                            decoration: const InputDecoration(),
                            items: originals
                                .map((e) => DropdownMenuItem(
                                    value: e.id, child: Text(e.name)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _recoveryOf = value),
                            validator: (value) => value == null
                                ? 'Seleccioná la evaluación original.'
                                : null)),
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
                        if (value != null) {
                          setState(() => _date = DateTime(
                              value.year,
                              value.month,
                              value.day,
                              _date.hour,
                              _date.minute));
                        }
                      }),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Todo el día'),
                      value: _allDay,
                      onChanged: (v) => setState(() {
                            _allDay = v;
                            if (v) {
                              _reminders = _reminders
                                  .where((r) => r.offsetMinutes % 1440 == 0)
                                  .toList();
                            }
                          })),
                  if (!_allDay)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hora *'),
                      subtitle: Text(
                        '${_date.hour.toString().padLeft(2, '0')}:'
                        '${_date.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.schedule),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_date),
                        );
                        if (time != null) {
                          setState(() => _date = DateTime(_date.year,
                              _date.month, _date.day, time.hour, time.minute));
                        }
                      },
                    ),
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
                    Expanded(child: _numberField(_grade, 'Nota')),
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
                  _fieldLabel(
                      'Estado',
                      DropdownButtonFormField<EvaluationStatus>(
                          isExpanded: true,
                          value: _status,
                          decoration: const InputDecoration(),
                          items: EvaluationStatus.values
                              .map((v) => DropdownMenuItem(
                                  value: v, child: Text(_statusLabel(v))))
                              .toList(),
                          onChanged: (v) => setState(() => _status = v!))),
                  const SizedBox(height: 12),
                  _fieldLabel(
                      'Presentada',
                      DropdownButtonFormField<bool?>(
                          isExpanded: true,
                          value: _presented,
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(
                                value: null, child: Text('Sin indicar')),
                            DropdownMenuItem(value: true, child: Text('Sí')),
                            DropdownMenuItem(value: false, child: Text('No'))
                          ],
                          onChanged: (v) => setState(() => _presented = v))),
                  const SizedBox(height: 12),
                  _fieldLabel(
                      'Notas / observaciones',
                      TextFormField(
                          controller: _notes,
                          maxLines: 3,
                          decoration: const InputDecoration())),
                  const SizedBox(height: 20),
                  Text('Recordatorios',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_allDay
                            ? const <int, String>{
                                0: 'El mismo día',
                                1440: '1 día antes',
                                2880: '2 días antes',
                                10080: '1 semana antes',
                              }
                            : const <int, String>{
                                0: 'Al momento',
                                15: '15 min antes',
                                30: '30 min antes',
                                60: '1 hora antes',
                                120: '2 horas antes',
                                1440: '1 día antes',
                                2880: '2 días antes',
                                10080: '1 semana antes',
                              })
                        .entries
                        .map((preset) {
                      final selected = _reminders.any(
                          (r) => r.offsetMinutes == preset.key && r.enabled);
                      return FilterChip(
                        label: Text(preset.value),
                        selected: selected,
                        onSelected: (value) => setState(() {
                          if (value && _reminders.length < 5) {
                            _reminders.add(EvaluationReminder(
                              id: 'reminder_${DateTime.now().microsecondsSinceEpoch}_${preset.key}',
                              offsetMinutes: preset.key,
                            ));
                          } else if (!value) {
                            _reminders.removeWhere(
                                (r) => r.offsetMinutes == preset.key);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  if (!(ref
                          .watch(userProfileProvider)
                          .valueOrNull
                          ?.settings
                          .notifications
                          .enabled ??
                      false))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Estos recordatorios se guardarán, pero no se mostrarán hasta que actives las notificaciones.',
                      ),
                    ),
                  if (state.hasError)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text((state.error as AppException).message,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: state.isLoading || _submitting
                          ? null
                          : () => _save(subjects),
                      child: const Text('Guardar')),
                ]),
          ),
        );
      },
    );
  }

  Widget _numberField(TextEditingController controller, String label) =>
      _fieldLabel(
          label,
          TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration()));

  Widget _fieldLabel(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          field,
        ],
      );
}

String _statusLabel(EvaluationStatus value) => switch (value) {
      EvaluationStatus.pending => 'Pendiente',
      EvaluationStatus.submitted => 'Presentada / Entregada',
      EvaluationStatus.approved => 'Aprobada',
      EvaluationStatus.failed => 'Desaprobada',
      EvaluationStatus.absent => 'Ausente',
      EvaluationStatus.recovered => 'Recuperada',
    };
