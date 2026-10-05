// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/formatters/academic_rule_type_formatter.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/academic_year.dart';
import '../../../../domain/entities/academic_rule.dart';
import '../../../../domain/entities/subject.dart';
import '../../../../domain/entities/subject_schedule_block.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../evaluations/application/evaluation_controller.dart';
import '../../application/academic_year_controller.dart';
import '../../application/subject_controller.dart';
import '../widgets/academic_rule_editor.dart';
import '../widgets/academic_rule_type_help_button.dart';
import '../widgets/subject_schedule_editor.dart';

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
  RecoveryPolicy _recoveryPolicy = RecoveryPolicy.highestGrade;
  DateTime? _approvedAt;
  int _step = 0;
  bool _initialized = false;
  bool _submitting = false;
  List<AcademicRule> _promotionRules = [];
  List<AcademicRule> _regularityRules = [];
  List<SubjectScheduleBlock> _scheduleBlocks = [];
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
    _recoveryPolicy = s.recoveryPolicy;
    _approvedAt = s.approvedAt;
    _promotionRules = [...s.promotionRules];
    _regularityRules = [...s.regularityRules];
    _scheduleBlocks = [...s.scheduleBlocks];
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
        finalOutcome: outcome,
        finalGrade: historical && !disallowGrade ? _number(_grade.text) : null,
        approvedAt: historical ? _approvedAt : null,
        gradeMin: _number(_min.text) ?? 0,
        gradeMax: _number(_max.text) ?? 10,
        recoveryPolicy: _recoveryPolicy,
        notes: _optional(_notes.text),
        scheduleBlocks: List.unmodifiable(_scheduleBlocks),
        promotionRules: List.unmodifiable(_promotionRules),
        regularityRules: List.unmodifiable(_regularityRules),
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
    if (_submitting) return;
    if (!_form.currentState!.validate()) return;
    final error = _validate(years);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final id = await ref
          .read(subjectControllerProvider.notifier)
          .save(_build(years));
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
          _promotionRules = [];
          _regularityRules = [];
          _scheduleBlocks = [];
        });
      } else {
        context.go(AppRoutes.subject(id));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createYear() async {
    final controller = TextEditingController(text: '${DateTime.now().year}');
    var markCurrent = true;
    final result = await showDialog<(int?, bool)>(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                    title: const Text('Crear año académico'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Align(
                          alignment: Alignment.centerLeft, child: Text('Año')),
                      const SizedBox(height: 6),
                      TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration()),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: markCurrent,
                        onChanged: (value) =>
                            setDialogState(() => markCurrent = value ?? false),
                        title: const Text('Marcar como año académico actual'),
                      )
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(
                              c, (int.tryParse(controller.text), markCurrent)),
                          child: const Text('Crear'))
                    ])));
    controller.dispose();
    if (result == null) return;
    final (value, selectedCurrent) = result;
    if (value == null) return;
    if (value < 1900 || value > 2200) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingresá un año válido.')));
      return;
    }
    final ok = await ref
        .read(academicYearControllerProvider.notifier)
        .create(value, current: selectedCurrent);
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
        error: (_, __) => ContentPage(
            title: 'Materia',
            showBackButton: true,
            backFallback: () => context.go(AppRoutes.subjects),
            child: const Text('No pudimos cargar los años académicos.')),
        data: (years) {
          if (existing?.isLoading == true)
            return const Center(child: CircularProgressIndicator());
          if (existing?.hasError == true)
            return ContentPage(
                title: 'Materia',
                showBackButton: true,
                backFallback: () => context.go(AppRoutes.subjects),
                child: const Text('No pudimos cargar la materia.'));
          if (existing?.valueOrNull case final s?) _load(s);
          _defaults(years);
          final saving =
              _submitting || ref.watch(subjectControllerProvider).isLoading;
          return ContentPage(
              title: widget.subjectId == null
                  ? (_mode == TrackingMode.tracked
                      ? 'Nueva materia en cursado'
                      : 'Materia ya cursada')
                  : 'Editar materia',
              showBackButton: true,
              backFallback: () => context.go(AppRoutes.subjects),
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_mode == TrackingMode.tracked) ...[
                          _currentStepper(years, saving)
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

  bool _canContinueFrom(int step) {
    if (step != 0) return true;
    final fieldsAreValid = _form.currentState?.validate() ?? false;
    if (_yearId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná o creá un año académico.')));
      return false;
    }
    return fieldsAreValid;
  }

  void _goToStep(int target) {
    if (target <= _step || _canContinueFrom(_step)) {
      setState(() => _step = target);
    }
  }

  Widget _stepActions(List<AcademicYear> years, bool saving) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          children: [
            if (_step > 0) ...[
              TextButton(
                onPressed: saving ? null : () => setState(() => _step--),
                child: const Text('Atrás'),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () {
                        if (_step < 3) {
                          if (_canContinueFrom(_step)) {
                            setState(() => _step++);
                          }
                        } else {
                          _save(years);
                        }
                      },
                child: saving && _step == 3
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_step == 3
                        ? (widget.subjectId == null
                            ? 'Crear materia'
                            : 'Guardar cambios')
                        : 'Continuar'),
              ),
            ),
          ],
        ),
      );

  Widget _stepContent(Widget child, List<AcademicYear> years, bool saving) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child, _stepActions(years, saving)],
        ),
      );

  Widget _currentStepper(List<AcademicYear> years, bool saving) => Stepper(
          currentStep: _step,
          onStepTapped: _goToStep,
          controlsBuilder: (_, __) => const SizedBox.shrink(),
          steps: [
            Step(
                title: const Text('Datos básicos'),
                isActive: _step >= 0,
                content: _stepContent(_basic(years), years, saving)),
            Step(
                title: const Text('Tipo y duración'),
                isActive: _step >= 1,
                content: _stepContent(_typeDuration(), years, saving)),
            Step(
                title: const Text('Condiciones académicas'),
                isActive: _step >= 2,
                content: _stepContent(_conditionsStep(), years, saving)),
            Step(
                title: const Text('Revisión'),
                isActive: _step >= 3,
                content: _stepContent(_review(years), years, saving))
          ]);
  Widget _historicalForm(List<AcademicYear> years) => Column(children: [
        _basic(years),
        const SizedBox(height: 20),
        _typeDuration(),
        const SizedBox(height: 20),
        _fieldLabel(
            'Resultado final *',
            DropdownButtonFormField(
                value: _outcome,
                decoration: const InputDecoration(),
                items: FinalOutcome.values
                    .map((v) => DropdownMenuItem(
                        value: v, child: Text(_outcomeLabel(v))))
                    .toList(),
                onChanged: (v) => setState(() {
                      _outcome = v!;
                      if (v == FinalOutcome.abandoned ||
                          v == FinalOutcome.regularized) _grade.clear();
                    }))),
        const SizedBox(height: 12),
        if (_outcome != FinalOutcome.abandoned &&
            _outcome != FinalOutcome.regularized)
          _fieldLabel(
              'Nota final',
              TextFormField(
                  controller: _grade,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration())),
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
        _fieldLabel(
            'Observaciones',
            TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration())),
        const SizedBox(height: 12),
        _advanced()
      ]);
  Widget _basic(List<AcademicYear> years) => Column(children: [
        _fieldLabel(
            'Nombre *',
            TextFormField(
                controller: _name,
                decoration:
                    const InputDecoration(hintText: 'Ej.: Redes de Datos'),
                validator: (v) {
                  final n = v?.trim() ?? '';
                  if (n.length < 2 || n.length > 100)
                    return 'Ingresá entre 2 y 100 caracteres.';
                  return null;
                })),
        const SizedBox(height: 12),
        _fieldLabel(
            'Nombre corto',
            TextFormField(
                controller: _short,
                decoration: const InputDecoration(hintText: 'Ej.: Redes'),
                validator: (v) => (v?.trim().length ?? 0) > 15
                    ? 'Máximo 15 caracteres.'
                    : null)),
        const SizedBox(height: 12),
        _fieldLabel(
            'Código',
            TextFormField(
                controller: _code, decoration: const InputDecoration())),
        const SizedBox(height: 12),
        _fieldLabel(
            'Comisión',
            TextFormField(
                controller: _commission,
                decoration: const InputDecoration(hintText: 'Ej.: 4K3'))),
        const SizedBox(height: 12),
        _fieldLabel(
            'Año académico *',
            DropdownButtonFormField<String>(
                isExpanded: true,
                value: years.any((y) => y.id == _yearId) ? _yearId : null,
                decoration: const InputDecoration(),
                items: years
                    .map((y) => DropdownMenuItem(
                        value: y.id,
                        child:
                            Text('${y.year}${y.isCurrent ? ' · Actual' : ''}')))
                    .toList(),
                onChanged: (v) => setState(() => _yearId = v))),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                onPressed: _createYear,
                icon: const Icon(Icons.add),
                label: const Text('Crear año'))),
        if (years.where((y) => y.id == _yearId && !y.isCurrent).firstOrNull
            case final selected?)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _markCurrent(selected),
              icon: const Icon(Icons.event_available),
              label: Text('Marcar ${selected.year} como año actual'),
            ),
          )
      ]);
  Widget _typeDuration() => Column(children: [
        _fieldLabel(
            'Tipo',
            DropdownButtonFormField(
                isExpanded: true,
                value: _type,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(
                      value: SubjectType.mandatory, child: Text('Obligatoria')),
                  DropdownMenuItem(
                      value: SubjectType.elective, child: Text('Electiva'))
                ],
                onChanged: (v) => setState(() {
                      _type = v!;
                      if (v == SubjectType.mandatory) _points.clear();
                    }))),
        if (_type == SubjectType.elective) ...[
          const SizedBox(height: 12),
          _fieldLabel(
              'Puntos electivos *',
              TextFormField(
                  controller: _points,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration()))
        ],
        const SizedBox(height: 12),
        _fieldLabel(
            'Duración',
            DropdownButtonFormField(
                isExpanded: true,
                value: _duration,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(
                      value: SubjectDuration.annual, child: Text('Anual')),
                  DropdownMenuItem(
                      value: SubjectDuration.semester,
                      child: Text('Cuatrimestral'))
                ],
                onChanged: (v) => setState(() {
                      _duration = v!;
                      if (v == SubjectDuration.annual) _semester = null;
                    }))),
        if (_duration == SubjectDuration.semester) ...[
          const SizedBox(height: 12),
          _fieldLabel(
              'Cuatrimestre *',
              DropdownButtonFormField(
                  isExpanded: true,
                  value: _semester,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(
                        value: Semester.first,
                        child: Text('Primer cuatrimestre')),
                    DropdownMenuItem(
                        value: Semester.second,
                        child: Text('Segundo cuatrimestre'))
                  ],
                  onChanged: (v) => setState(() => _semester = v)))
        ],
        const SizedBox(height: 12),
        _advanced(),
        const SizedBox(height: 12),
        ExpansionTile(
          key: const Key('subject-schedule-section'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Horarios de cursado'),
          children: [
            SubjectScheduleEditor(
              blocks: _scheduleBlocks,
              onChanged: (blocks) => setState(() => _scheduleBlocks = blocks),
            ),
          ],
        ),
      ]);

  Future<void> _markCurrent(AcademicYear year) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('¿Usar ${year.year} como año académico actual?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmar')),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await ref
          .read(academicYearControllerProvider.notifier)
          .setCurrent(year.id);
    }
  }

  Widget _conditionsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ruleSection('Condiciones de promoción', _promotionRules, true),
          const SizedBox(height: 20),
          _ruleSection('Condiciones de regularidad', _regularityRules, false),
          if (widget.subjectId == null) ...[
            const SizedBox(height: 12),
            const Text(
              'Las condiciones asociadas a una evaluación específica pueden configurarse después de crear la materia y cargar sus evaluaciones.',
            ),
          ],
        ],
      );

  Widget _ruleSection(String title, List<AcademicRule> rules, bool promotion) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (rules.isEmpty) const Text('Sin condiciones'),
          ...rules.map((rule) => Card(
                child: ListTile(
                  title: Row(children: [
                    Expanded(child: Text(rule.name)),
                    AcademicRuleTypeHelpButton(type: rule.type),
                  ]),
                  subtitle: Text(
                      '${academicRuleTypeLabel(rule.type)}${_ruleValue(rule.config)}${rule.enabled ? '' : ' · Deshabilitada'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) =>
                        _ruleAction(promotion, rule, action),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                              rule.enabled ? 'Deshabilitar' : 'Habilitar')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _editRule(promotion, null),
            icon: const Icon(Icons.add),
            label: const Text('Agregar condición'),
          ),
        ],
      );

  String _ruleValue(AcademicRuleConfig config) => switch (config) {
        MinimumAverageConfig c =>
          ' · Promedio requerido: ${_displayNumber(c.minimumAverage)}',
        MinimumGradeByTypeConfig c =>
          ' · Nota mínima: ${_displayNumber(c.minimumGrade)}',
        MinimumApprovedPercentageConfig c =>
          ' · Requerido: ${_displayNumber(c.minimumPercentage)} %',
        MinimumApprovedCountConfig c => ' · Requerido: ${c.minimumCount}',
        _ => '',
      };

  String _displayNumber(double value) => value
      .toStringAsFixed(value == value.roundToDouble() ? 0 : 1)
      .replaceAll('.', ',');

  Future<void> _ruleAction(
      bool promotion, AcademicRule rule, String action) async {
    if (action == 'edit') return _editRule(promotion, rule);
    setState(() {
      final rules = promotion ? _promotionRules : _regularityRules;
      final index = rules.indexWhere((item) => item.id == rule.id);
      if (action == 'delete') rules.removeAt(index);
      if (action == 'toggle')
        rules[index] = rule.copyWith(enabled: !rule.enabled);
    });
  }

  Future<void> _editRule(bool promotion, AcademicRule? existing) async {
    final rules = promotion ? _promotionRules : _regularityRules;
    final subject = _draftSubject();
    final rule = await showAcademicRuleEditor(
      context,
      subject: subject,
      evaluations: widget.subjectId == null
          ? const []
          : ref
                  .read(subjectEvaluationsProvider(widget.subjectId!))
                  .valueOrNull ??
              const [],
      order: existing?.order ?? rules.length,
      existing: existing,
      allowRequiredEvaluation: widget.subjectId != null,
    );
    if (rule == null || !mounted) return;
    setState(() {
      final index = rules.indexWhere((item) => item.id == rule.id);
      if (index < 0)
        rules.add(rule);
      else
        rules[index] = rule;
    });
  }

  Subject _draftSubject() => Subject(
        id: widget.subjectId ?? '',
        academicYearId: _yearId ?? '',
        academicYear: 0,
        trackingMode: TrackingMode.tracked,
        name: _name.text.trim().isEmpty ? 'Materia' : _name.text.trim(),
        subjectType: _type,
        duration: _duration,
        semester: _duration == SubjectDuration.semester ? _semester : null,
        courseStatus: CourseStatus.active,
        gradeMin: _number(_min.text) ?? 0,
        gradeMax: _number(_max.text) ?? 10,
        scheduleBlocks: List.unmodifiable(_scheduleBlocks),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
  Widget _advanced() => ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Opciones avanzadas'),
          children: [
            Row(children: [
              Expanded(
                  child: _fieldLabel(
                      'Nota mínima',
                      TextFormField(
                          controller: _min,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration()))),
              const SizedBox(width: 12),
              Expanded(
                  child: _fieldLabel(
                      'Nota máxima',
                      TextFormField(
                          controller: _max,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration())))
            ]),
            if (_mode == TrackingMode.tracked) ...[
              const SizedBox(height: 12),
              _fieldLabel(
                  'Política de recuperatorios',
                  DropdownButtonFormField<RecoveryPolicy>(
                      isExpanded: true,
                      value: _recoveryPolicy,
                      decoration: const InputDecoration(),
                      items: RecoveryPolicy.values
                          .map((policy) => DropdownMenuItem(
                              value: policy,
                              child: Text(switch (policy) {
                                RecoveryPolicy.replaceGrade =>
                                  'El recuperatorio reemplaza la nota original',
                                RecoveryPolicy.highestGrade =>
                                  'Se toma la mejor nota',
                                RecoveryPolicy.approvalOnly =>
                                  'El recuperatorio solo recupera la aprobación',
                              })))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _recoveryPolicy = value!))),
            ]
          ]);

  Widget _fieldLabel(String text, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          field,
        ],
      );
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
                  'Duración: ${_duration == SubjectDuration.annual ? 'Anual' : _semester == Semester.first ? '1°C' : '2°C'}'),
              const SizedBox(height: 8),
              Text(
                  'Promoción: ${_promotionRules.isEmpty ? 'Sin condiciones' : '${_promotionRules.length} ${_promotionRules.length == 1 ? 'condición' : 'condiciones'}'}'),
              Text(
                  'Regularidad: ${_regularityRules.isEmpty ? 'Sin condiciones' : '${_regularityRules.length} ${_regularityRules.length == 1 ? 'condición' : 'condiciones'}'}')
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
