import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/formatters/academic_rule_type_formatter.dart';
import '../../../../core/formatters/evaluation_type_formatter.dart';
import '../../../../domain/entities/academic_rule.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../../domain/entities/subject.dart';
import 'academic_rule_type_help_button.dart';

Future<AcademicRule?> showAcademicRuleEditor(
  BuildContext context, {
  required Subject subject,
  required List<Evaluation> evaluations,
  required int order,
  AcademicRule? existing,
  bool allowRequiredEvaluation = true,
}) {
  final editor = AcademicRuleEditor(
    subject: subject,
    evaluations: evaluations,
    order: order,
    existing: existing,
    allowRequiredEvaluation: allowRequiredEvaluation,
  );
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<AcademicRule>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: editor,
      ),
    );
  }
  return showDialog<AcademicRule>(
    context: context,
    builder: (context) => Dialog(child: SizedBox(width: 560, child: editor)),
  );
}

class AcademicRuleEditor extends StatefulWidget {
  const AcademicRuleEditor({
    required this.subject,
    required this.evaluations,
    required this.order,
    this.existing,
    this.allowRequiredEvaluation = true,
    super.key,
  });
  final Subject subject;
  final List<Evaluation> evaluations;
  final int order;
  final AcademicRule? existing;
  final bool allowRequiredEvaluation;

  @override
  State<AcademicRuleEditor> createState() => _AcademicRuleEditorState();
}

class _AcademicRuleEditorState extends State<AcademicRuleEditor> {
  final _formKey = GlobalKey<FormState>();
  late AcademicRuleType _type;
  late final TextEditingController _name, _value, _description;
  bool _enabled = true, _mandatory = true, _saving = false;
  EvaluationType _evaluationType = EvaluationType.partial;
  Set<EvaluationType> _evaluationTypes = {};
  String? _evaluationId;

  @override
  void initState() {
    super.initState();
    final rule = widget.existing;
    _type = rule?.type ?? AcademicRuleType.minimumAverage;
    _name =
        TextEditingController(text: rule?.name ?? academicRuleTypeLabel(_type));
    _description = TextEditingController(text: rule?.description ?? '');
    _value = TextEditingController(text: _configValue(rule?.config));
    _enabled = rule?.enabled ?? true;
    final config = rule?.config;
    if (config is MinimumGradeByTypeConfig) {
      _evaluationType = config.evaluationType;
    }
    if (config is RequiredEvaluationConfig) _evaluationId = config.evaluationId;
    if (config is MinimumApprovedCountConfig) {
      _mandatory = config.mandatoryOnly;
      _evaluationTypes = {...config.evaluationTypes};
    }
    if (config is MinimumApprovedPercentageConfig) {
      _mandatory = config.mandatoryOnly;
      _evaluationTypes = {...config.evaluationTypes};
    }
    if (config is AllEvaluationsApprovedConfig) {
      _mandatory = config.mandatoryOnly;
      _evaluationTypes = {...config.evaluationTypes};
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
                widget.existing == null
                    ? 'Agregar condición'
                    : 'Editar condición',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: Text('Tipo de condición',
                      style: Theme.of(context).textTheme.labelLarge)),
              AcademicRuleTypeHelpButton(type: _type),
            ]),
            const SizedBox(height: 6),
            DropdownButtonFormField<AcademicRuleType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: AcademicRuleType.values
                  .where((type) =>
                      widget.allowRequiredEvaluation ||
                      type != AcademicRuleType.requiredEvaluation)
                  .map((type) => DropdownMenuItem(
                      value: type, child: Text(academicRuleTypeLabel(type))))
                  .toList(),
              onChanged: (value) => setState(() {
                _type = value!;
                _name.text = academicRuleTypeLabel(_type);
                _value.clear();
              }),
            ),
            const SizedBox(height: 16),
            _field(
                'Nombre',
                TextFormField(
                    controller: _name, decoration: const InputDecoration())),
            const SizedBox(height: 16),
            _field(
                'Descripción (opcional)',
                TextFormField(
                    controller: _description,
                    maxLines: 2,
                    decoration: const InputDecoration())),
            if (_needsValue) ...[
              const SizedBox(height: 16),
              _field(
                  _valueLabel,
                  TextFormField(
                    controller: _value,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(),
                  )),
            ],
            if (_type == AcademicRuleType.minimumGradeByType) ...[
              const SizedBox(height: 16),
              _field(
                  'Tipo de evaluación',
                  DropdownButtonFormField<EvaluationType>(
                    initialValue: _evaluationType,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: EvaluationType.values
                        .where((e) => e != EvaluationType.recovery)
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(evaluationTypeLabel(e))))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _evaluationType = value!),
                  )),
            ],
            if (_type == AcademicRuleType.requiredEvaluation) ...[
              const SizedBox(height: 16),
              _field(
                  'Evaluación',
                  DropdownButtonFormField<String>(
                    initialValue:
                        widget.evaluations.any((e) => e.id == _evaluationId)
                            ? _evaluationId
                            : null,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: widget.evaluations
                        .where((e) => !e.isRecovery)
                        .map((e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _evaluationId = value),
                  )),
            ],
            if (_usesEvaluationFilters) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _mandatory,
                  onChanged: (value) => setState(() => _mandatory = value),
                  title: const Text('Solo obligatorias')),
              Text('Tipos de evaluación (vacío = todos)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: EvaluationType.values
                      .where((e) => e != EvaluationType.recovery)
                      .map((e) => FilterChip(
                          label: Text(evaluationTypeLabel(e)),
                          selected: _evaluationTypes.contains(e),
                          onSelected: (selected) => setState(() => selected
                              ? _evaluationTypes.add(e)
                              : _evaluationTypes.remove(e))))
                      .toList()),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
                title: const Text('Habilitada')),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Guardar')),
            ]),
          ]),
        ),
      );

  Widget _field(String label, Widget child) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        child,
      ]);
  bool get _needsValue =>
      _type == AcademicRuleType.minimumAverage ||
      _type == AcademicRuleType.minimumGradeByType ||
      _type == AcademicRuleType.minimumApprovedPercentage ||
      _type == AcademicRuleType.minimumApprovedCount;
  bool get _usesEvaluationFilters =>
      _type == AcademicRuleType.minimumApprovedPercentage ||
      _type == AcademicRuleType.minimumApprovedCount ||
      _type == AcademicRuleType.allEvaluationsApproved;
  String get _valueLabel => switch (_type) {
        AcademicRuleType.minimumAverage => 'Promedio requerido',
        AcademicRuleType.minimumGradeByType => 'Nota mínima',
        AcademicRuleType.minimumApprovedPercentage => 'Porcentaje requerido',
        _ => 'Cantidad requerida',
      };
  String _configValue(AcademicRuleConfig? config) => switch (config) {
        MinimumAverageConfig c => '${c.minimumAverage}',
        MinimumGradeByTypeConfig c => '${c.minimumGrade}',
        MinimumApprovedPercentageConfig c => '${c.minimumPercentage}',
        MinimumApprovedCountConfig c => '${c.minimumCount}',
        _ => '',
      };

  void _save() {
    if (_saving) return;
    setState(() => _saving = true);
    final number = double.tryParse(_value.text.replaceAll(',', '.'));
    final config = switch (_type) {
      AcademicRuleType.minimumAverage =>
        MinimumAverageConfig(number ?? double.nan),
      AcademicRuleType.minimumGradeByType =>
        MinimumGradeByTypeConfig(_evaluationType, number ?? double.nan),
      AcademicRuleType.minimumApprovedPercentage =>
        MinimumApprovedPercentageConfig(number ?? double.nan,
            evaluationTypes: _evaluationTypes, mandatoryOnly: _mandatory),
      AcademicRuleType.minimumApprovedCount => MinimumApprovedCountConfig(
          number?.toInt() ?? 0,
          evaluationTypes: _evaluationTypes,
          mandatoryOnly: _mandatory),
      AcademicRuleType.allEvaluationsApproved => AllEvaluationsApprovedConfig(
          evaluationTypes: _evaluationTypes, mandatoryOnly: _mandatory),
      AcademicRuleType.requiredEvaluation =>
        RequiredEvaluationConfig(_evaluationId ?? ''),
    };
    final rule = AcademicRule(
        id: widget.existing?.id ??
            '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}',
        type: _type,
        name: _name.text,
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        enabled: _enabled,
        order: widget.order,
        config: config);
    final error = rule.validate(widget.subject);
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context, rule);
  }
}
