// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/academic_year.dart';
import '../../../../domain/entities/subject.dart';
import '../../../profile/application/profile_controller.dart';
import '../../application/academic_year_controller.dart';
import '../../application/subject_controller.dart';

class SubjectFormScreen extends ConsumerStatefulWidget {
  const SubjectFormScreen({this.mode, this.subjectId, super.key});
  final TrackingMode? mode;
  final String? subjectId;
  @override
  ConsumerState<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends ConsumerState<SubjectFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _short = TextEditingController(),
      _code = TextEditingController(),
      _commission = TextEditingController(),
      _points = TextEditingController(),
      _min = TextEditingController(text: '0'),
      _max = TextEditingController(text: '10'),
      _grade = TextEditingController(),
      _notes = TextEditingController();
  String? _yearId;
  SubjectType _type = SubjectType.mandatory;
  SubjectDuration _duration = SubjectDuration.annual;
  Semester? _semester;
  FinalOutcome _outcome = FinalOutcome.approved;
  DateTime? _approvedAt;
  int _step = 0;
  bool _initialized = false;
  TrackingMode get _mode =>
      widget.mode ??
      ref.read(subjectProvider(widget.subjectId!)).valueOrNull?.trackingMode ??
      TrackingMode.tracked;
  @override
  void dispose() {
    for (final c in [
      _name,
      _short,
      _code,
      _commission,
      _points,
      _min,
      _max,
      _grade,
      _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Subject s) {
    if (_initialized) return;
    _initialized = true;
    _name.text = s.name;
    _short.text = s.shortName ?? '';
    _code.text = s.code ?? '';
    _commission.text = s.commission ?? '';
    _points.text = s.electivePoints?.toString() ?? '';
    _min.text = s.gradeMin.toString();
    _max.text = s.gradeMax.toString();
    _grade.text = s.finalGrade?.toString() ?? '';
    _notes.text = s.notes ?? '';
    _yearId = s.academicYearId;
    _type = s.subjectType;
    _duration = s.duration;
    _semester = s.semester;
    _outcome = s.finalOutcome ?? FinalOutcome.approved;
    _approvedAt = s.approvedAt;
  }

  void _defaults(List<AcademicYear> years) {
    if (_initialized || widget.subjectId != null) return;
    _initialized = true;
    final current = years.where((y) => y.isCurrent).firstOrNull;
    _yearId = (current ?? years.firstOrNull)?.id;
    final p = ref.read(userProfileProvider).valueOrNull;
    _min.text = '${p?.settings.defaultGradeMin ?? 0}';
    _max.text = '${p?.settings.defaultGradeMax ?? 10}';
  }

  double? _number(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
  String? _optional(String text) => text.trim().isEmpty ? null : text.trim();

  Subject _build(List<AcademicYear> years) {
    final y = years.firstWhere((e) => e.id == _yearId);
    final historical = _mode == TrackingMode.historical;
    final outcome = historical ? _outcome : null;
    final disallowGrade = outcome == FinalOutcome.abandoned ||
        outcome == FinalOutcome.regularized;
    return Subject(
        id: widget.subjectId ?? '',
        academicYearId: y.id,
        academicYear: y.year,
        trackingMode: _mode,
        name: _name.text.trim(),
        shortName: _optional(_short.text),
        code: _optional(_code.text),
        commission: _optional(_commission.text),
        subjectType: _type,
        electivePoints:
            _type == SubjectType.elective ? _number(_points.text) : null,
        duration: _duration,
        semester: _duration == SubjectDuration.semester ? _semester : null,
        courseStatus: historical
            ? (outcome == FinalOutcome.abandoned
                ? CourseStatus.abandoned
                : CourseStatus.finished)
            : CourseStatus.active,
        currentCondition: historical ? null : AcademicCondition.noData,
        finalOutcome: outcome,
        finalGrade: historical && !disallowGrade ? _number(_grade.text) : null,
        approvedAt: historical ? _approvedAt : null,
        gradeMin: _number(_min.text) ?? 0,
        gradeMax: _number(_max.text) ?? 10,
        notes: _optional(_notes.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now());
  }

  String? _validate(List<AcademicYear> years) {
    if (_yearId == null) return 'Seleccioná o creá un año académico.';
    if (_type == SubjectType.elective && (_number(_points.text) ?? 0) <= 0)
      return 'Ingresá puntos electivos mayores a cero.';
    if (_duration == SubjectDuration.semester && _semester == null)
      return 'Seleccioná el cuatrimestre.';
    return _build(years).validate();
  }

  Future<void> _save(List<AcademicYear> years, {bool another = false}) async {
    if (!_form.currentState!.validate()) return;
    final error = _validate(years);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final id =
        await ref.read(subjectControllerProvider.notifier).save(_build(years));
    if (!mounted || id == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_mode == TrackingMode.historical
            ? '✓ Materia agregada al historial'
            : '✓ Materia creada')));
    if (another) {
      final year = _yearId;
      setState(() {
        for (final c in [
          _name,
          _short,
          _code,
          _commission,
          _points,
          _grade,
          _notes
        ]) {
          c.clear();
        }
        _yearId = year;
        _type = SubjectType.mandatory;
        _duration = SubjectDuration.annual;
        _semester = null;
        _outcome = FinalOutcome.approved;
        _approvedAt = null;
      });
    } else {
      context.go(AppRoutes.subject(id));
    }
  }

  Future<void> _createYear() async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Crear año académico'),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Año', hintText: '2026')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(c, int.tryParse(controller.text)),
                      child: const Text('Crear'))
                ]));
    controller.dispose();
    if (value == null) return;
    if (value < 1900 || value > 2200) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingresá un año válido.')));
      return;
    }
    final ok =
        await ref.read(academicYearControllerProvider.notifier).create(value);
    if (ok && mounted) setState(() => _yearId = '$value');
  }

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final existing = widget.subjectId == null
        ? null
        : ref.watch(subjectProvider(widget.subjectId!));
    return yearsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const ContentPage(
            title: 'Materia',
            child: Text('No pudimos cargar los años académicos.')),
        data: (years) {
          if (existing?.isLoading == true)
            return const Center(child: CircularProgressIndicator());
          if (existing?.hasError == true)
            return const ContentPage(
                title: 'Materia', child: Text('No pudimos cargar la materia.'));
          if (existing?.valueOrNull case final s?) _load(s);
          _defaults(years);
          final saving = ref.watch(subjectControllerProvider).isLoading;
          return ContentPage(
              title: widget.subjectId == null
                  ? (_mode == TrackingMode.tracked
                      ? 'Nueva materia en cursado'
                      : 'Materia ya cursada')
                  : 'Editar materia',
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_mode == TrackingMode.tracked) ...[
                          _currentStepper(years)
                        ] else ...[
                          _historicalForm(years)
                        ],
                        const SizedBox(height: 20),
                        if (ref.watch(subjectControllerProvider).hasError)
                          Text(
                              (ref.watch(subjectControllerProvider).error
                                      as AppException)
                                  .message,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        if (_mode == TrackingMode.historical)
                          Wrap(spacing: 12, runSpacing: 8, children: [
                            FilledButton(
                                onPressed: saving ? null : () => _save(years),
                                child: Text(widget.subjectId == null
                                    ? 'Guardar'
                                    : 'Guardar cambios')),
                            if (widget.subjectId == null)
                              OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () => _save(years, another: true),
                                  child: const Text('Guardar y agregar otra'))
                          ])
                      ])));
        });
  }

  Widget _currentStepper(List<AcademicYear> years) => Stepper(
          currentStep: _step,
          onStepTapped: (v) => setState(() => _step = v),
          onStepCancel: _step == 0 ? null : () => setState(() => _step--),
          onStepContinue: () {
            if (_step < 3) {
              setState(() => _step++);
            } else {
              _save(years);
            }
          },
          controlsBuilder: (context, d) => Row(children: [
                FilledButton(
                    onPressed: d.onStepContinue,
                    child: Text(_step == 3 ? 'Crear materia' : 'Continuar')),
                if (_step > 0)
                  TextButton(
                      onPressed: d.onStepCancel, child: const Text('Atrás'))
              ]),
          steps: [
            Step(
                title: const Text('Datos básicos'),
                isActive: _step >= 0,
                content: _basic(years)),
            Step(
                title: const Text('Tipo y duración'),
                isActive: _step >= 1,
                content: _typeDuration()),
            Step(
                title: const Text('Condiciones académicas'),
                isActive: _step >= 2,
                content: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline),
                    title: Text(
                        'La configuración de promoción y regularidad se incorporará en la próxima versión.'),
                    subtitle: Text('Podrás editarla posteriormente.'))),
            Step(
                title: const Text('Revisión'),
                isActive: _step >= 3,
                content: _review(years))
          ]);
  Widget _historicalForm(List<AcademicYear> years) => Column(children: [
        _basic(years),
        const SizedBox(height: 20),
        _typeDuration(),
        const SizedBox(height: 20),
        DropdownButtonFormField(
            value: _outcome,
            decoration: const InputDecoration(labelText: 'Resultado final *'),
            items: FinalOutcome.values
                .map((v) =>
                    DropdownMenuItem(value: v, child: Text(_outcomeLabel(v))))
                .toList(),
            onChanged: (v) => setState(() {
                  _outcome = v!;
                  if (v == FinalOutcome.abandoned ||
                      v == FinalOutcome.regularized) _grade.clear();
                })),
        const SizedBox(height: 12),
        if (_outcome != FinalOutcome.abandoned &&
            _outcome != FinalOutcome.regularized)
          TextFormField(
              controller: _grade,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Nota final')),
        const SizedBox(height: 12),
        ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha de aprobación'),
            subtitle: Text(_approvedAt == null
                ? 'Sin fecha'
                : '${_approvedAt!.day}/${_approvedAt!.month}/${_approvedAt!.year}'),
            trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2200),
                      initialDate: _approvedAt ?? DateTime.now());
                  if (d != null) setState(() => _approvedAt = d);
                })),
        TextFormField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Observaciones')),
        const SizedBox(height: 12),
        _advanced()
      ]);
  Widget _basic(List<AcademicYear> years) => Column(children: [
        TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            validator: (v) {
              final n = v?.trim() ?? '';
              if (n.length < 2 || n.length > 100)
                return 'Ingresá entre 2 y 100 caracteres.';
              return null;
            }),
        const SizedBox(height: 12),
        TextFormField(
            controller: _short,
            decoration: const InputDecoration(labelText: 'Nombre corto'),
            validator: (v) =>
                (v?.trim().length ?? 0) > 15 ? 'Máximo 15 caracteres.' : null),
        const SizedBox(height: 12),
        TextFormField(
            controller: _code,
            decoration: const InputDecoration(labelText: 'Código')),
        const SizedBox(height: 12),
        TextFormField(
            controller: _commission,
            decoration: const InputDecoration(labelText: 'Comisión')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: DropdownButtonFormField<String>(
                  value: years.any((y) => y.id == _yearId) ? _yearId : null,
                  decoration:
                      const InputDecoration(labelText: 'Año académico *'),
                  items: years
                      .map((y) => DropdownMenuItem(
                          value: y.id,
                          child: Text(
                              '${y.year}${y.isCurrent ? ' · Actual' : ''}')))
                      .toList(),
                  onChanged: (v) => setState(() => _yearId = v))),
          const SizedBox(width: 8),
          TextButton.icon(
              onPressed: _createYear,
              icon: const Icon(Icons.add),
              label: const Text('Crear año'))
        ])
      ]);
  Widget _typeDuration() => Column(children: [
        DropdownButtonFormField(
            value: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: const [
              DropdownMenuItem(
                  value: SubjectType.mandatory, child: Text('Obligatoria')),
              DropdownMenuItem(
                  value: SubjectType.elective, child: Text('Electiva'))
            ],
            onChanged: (v) => setState(() {
                  _type = v!;
                  if (v == SubjectType.mandatory) _points.clear();
                })),
        if (_type == SubjectType.elective) ...[
          const SizedBox(height: 12),
          TextFormField(
              controller: _points,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Puntos electivos *'))
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField(
            value: _duration,
            decoration: const InputDecoration(labelText: 'Duración'),
            items: const [
              DropdownMenuItem(
                  value: SubjectDuration.annual, child: Text('Anual')),
              DropdownMenuItem(
                  value: SubjectDuration.semester, child: Text('Cuatrimestral'))
            ],
            onChanged: (v) => setState(() {
                  _duration = v!;
                  if (v == SubjectDuration.annual) _semester = null;
                })),
        if (_duration == SubjectDuration.semester) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField(
              value: _semester,
              decoration: const InputDecoration(labelText: 'Cuatrimestre *'),
              items: const [
                DropdownMenuItem(
                    value: Semester.first, child: Text('Primer cuatrimestre')),
                DropdownMenuItem(
                    value: Semester.second, child: Text('Segundo cuatrimestre'))
              ],
              onChanged: (v) => setState(() => _semester = v))
        ],
        const SizedBox(height: 12),
        _advanced()
      ]);
  Widget _advanced() => ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Opciones avanzadas'),
          children: [
            Row(children: [
              Expanded(
                  child: TextFormField(
                      controller: _min,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Nota mínima'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextFormField(
                      controller: _max,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Nota máxima')))
            ])
          ]);
  Widget _review(List<AcademicYear> years) {
    final year = years.where((y) => y.id == _yearId).firstOrNull;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name.text.isEmpty ? 'Sin nombre' : _name.text,
                  style: Theme.of(context).textTheme.titleLarge),
              Text('Año: ${year?.year ?? '—'}'),
              Text('Comisión: ${_optional(_commission.text) ?? '—'}'),
              Text(
                  'Tipo: ${_type == SubjectType.mandatory ? 'Obligatoria' : 'Electiva'}'),
              Text(
                  'Duración: ${_duration == SubjectDuration.annual ? 'Anual' : _semester == Semester.first ? '1°C' : '2°C'}')
            ])));
  }

  String _outcomeLabel(FinalOutcome v) => switch (v) {
        FinalOutcome.approved => 'Aprobada',
        FinalOutcome.promoted => 'Promocionada',
        FinalOutcome.regularized => 'Regularizada',
        FinalOutcome.failed => 'Desaprobada',
        FinalOutcome.abandoned => 'Abandonada'
      };
}
