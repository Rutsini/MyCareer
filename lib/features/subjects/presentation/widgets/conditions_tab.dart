// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/academic_rule.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../../domain/entities/subject.dart';
import '../../../../domain/services/academic_engine.dart';
import '../../../evaluations/application/evaluation_controller.dart';
import '../../application/academic_controller.dart';

class ConditionsTab extends ConsumerWidget {
  const ConditionsTab({required this.subject, super.key});
  final Subject subject;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subject.trackingMode == TrackingMode.historical)
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                  'Las materias históricas utilizan su resultado final y no requieren reglas de cursado.')));
    return ref.watch(subjectAcademicResultProvider(subject.id)).when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) =>
            const Text('No pudimos recalcular la condición académica.'),
        data: (result) =>
            ListView(padding: const EdgeInsets.only(top: 16), children: [
              Card(
                  child: ListTile(
                      leading: Icon(_conditionIcon(result.condition)),
                      title: const Text('Condición actual'),
                      subtitle: Text(result.summary))),
              _section(context, ref, 'CONDICIONES DE PROMOCIÓN',
                  subject.promotionRules, result.promotionResults, true),
              _section(context, ref, 'CONDICIONES DE REGULARIDAD',
                  subject.regularityRules, result.regularityResults, false),
            ]));
  }

  Widget _section(
      BuildContext context,
      WidgetRef ref,
      String title,
      List<AcademicRule> rules,
      List<AcademicRuleResult> results,
      bool promotion) {
    final sorted = [...rules]..sort((a, b) => a.order.compareTo(b.order));
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(title,
                            style: Theme.of(context).textTheme.titleMedium)),
                    IconButton(
                        onPressed: () => _edit(context, ref, promotion, null),
                        icon: const Icon(Icons.add),
                        tooltip: 'Agregar condición')
                  ]),
                  if (sorted.isEmpty)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                            'Esta materia todavía no tiene condiciones de ${promotion ? 'promoción' : 'regularidad'} configuradas.')),
                  ...sorted.map((rule) {
                    final result =
                        results.where((r) => r.ruleId == rule.id).firstOrNull;
                    return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(!rule.enabled
                            ? Icons.pause_circle_outline
                            : result?.status == RuleResultStatus.met
                                ? Icons.check_circle
                                : result?.status == RuleResultStatus.unmet
                                    ? Icons.warning_amber
                                    : Icons.schedule),
                        title: Text(rule.name),
                        subtitle: Text(!rule.enabled
                            ? 'Deshabilitada'
                            : _resultText(result)),
                        trailing: PopupMenuButton<String>(
                            onSelected: (v) =>
                                _action(context, ref, promotion, rule, v),
                            itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Editar')),
                                  PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(rule.enabled
                                          ? 'Deshabilitar'
                                          : 'Habilitar')),
                                  if (rule.order > 0)
                                    const PopupMenuItem(
                                        value: 'up', child: Text('Subir')),
                                  const PopupMenuItem(
                                      value: 'down', child: Text('Bajar')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Eliminar'))
                                ]));
                  }),
                  FilledButton.tonalIcon(
                      onPressed: () => _edit(context, ref, promotion, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar condición'))
                ])));
  }

  Future<void> _action(BuildContext context, WidgetRef ref, bool promotion,
      AcademicRule rule, String action) async {
    if (action == 'edit') {
      await _edit(context, ref, promotion, rule);
      return;
    }
    final list = [
      ...(promotion ? subject.promotionRules : subject.regularityRules)
    ];
    final index = list.indexWhere((e) => e.id == rule.id);
    if (action == 'delete') {
      final yes = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                      title: const Text('¿Eliminar esta condición?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancelar')),
                        FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Eliminar'))
                      ])) ??
          false;
      if (!yes) return;
      list.removeAt(index);
    }
    if (action == 'toggle') list[index] = rule.copyWith(enabled: !rule.enabled);
    if (action == 'up' && index > 0) {
      final other = list[index - 1];
      list[index - 1] = rule.copyWith(order: other.order);
      list[index] = other.copyWith(order: rule.order);
    }
    if (action == 'down' && index < list.length - 1) {
      final other = list[index + 1];
      list[index + 1] = rule.copyWith(order: other.order);
      list[index] = other.copyWith(order: rule.order);
    }
    await ref.read(academicRuleControllerProvider.notifier).saveRules(subject,
        promotion: promotion ? list : null,
        regularity: promotion ? null : list);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, bool promotion,
      AcademicRule? existing) async {
    final evaluations =
        ref.read(subjectEvaluationsProvider(subject.id)).valueOrNull ??
            const <Evaluation>[];
    final rule = await showDialog<AcademicRule>(
        context: context,
        builder: (_) => _RuleDialog(
            subject: subject,
            evaluations: evaluations,
            existing: existing,
            order: existing?.order ??
                (promotion
                    ? subject.promotionRules.length
                    : subject.regularityRules.length)));
    if (rule == null) return;
    final list = [
      ...(promotion ? subject.promotionRules : subject.regularityRules)
    ];
    final i = list.indexWhere((e) => e.id == rule.id);
    if (i < 0)
      list.add(rule);
    else
      list[i] = rule;
    await ref.read(academicRuleControllerProvider.notifier).saveRules(subject,
        promotion: promotion ? list : null,
        regularity: promotion ? null : list);
  }

  IconData _conditionIcon(AcademicCondition? c) => switch (c) {
        AcademicCondition.promoting => Icons.trending_up,
        AcademicCondition.regular => Icons.check_circle_outline,
        AcademicCondition.atRisk => Icons.warning_amber,
        AcademicCondition.failed => Icons.cancel_outlined,
        _ => Icons.info_outline
      };
  String _resultText(AcademicRuleResult? result) {
    if (result == null) return 'Pendiente';
    final progress = result.currentValue == null || result.requiredValue == null
        ? ''
        : '\nActual ${_number(result.currentValue!)} / Requerido ${_number(result.requiredValue!)}';
    final actions =
        result.actions.isEmpty ? '' : '\n${result.actions.join(' ')}';
    return '${result.message}$progress$actions';
  }

  String _number(double value) => value
      .toStringAsFixed(value == value.roundToDouble() ? 0 : 1)
      .replaceAll('.', ',');
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog(
      {required this.subject,
      required this.evaluations,
      required this.order,
      this.existing});
  final Subject subject;
  final List<Evaluation> evaluations;
  final int order;
  final AcademicRule? existing;
  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late AcademicRuleType type;
  late TextEditingController name, value, description;
  bool enabled = true, mandatory = true;
  EvaluationType evaluationType = EvaluationType.partial;
  Set<EvaluationType> evaluationTypes = {};
  String? evaluationId;
  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    type = r?.type ?? AcademicRuleType.minimumAverage;
    name = TextEditingController(text: r?.name ?? _label(type));
    description = TextEditingController(text: r?.description ?? '');
    value = TextEditingController(text: _value(r?.config));
    enabled = r?.enabled ?? true;
    final c = r?.config;
    if (c is MinimumGradeByTypeConfig) evaluationType = c.evaluationType;
    if (c is RequiredEvaluationConfig) evaluationId = c.evaluationId;
    if (c is MinimumApprovedCountConfig) mandatory = c.mandatoryOnly;
    if (c is MinimumApprovedCountConfig)
      evaluationTypes = {...c.evaluationTypes};
    if (c is MinimumApprovedPercentageConfig) mandatory = c.mandatoryOnly;
    if (c is MinimumApprovedPercentageConfig)
      evaluationTypes = {...c.evaluationTypes};
    if (c is AllEvaluationsApprovedConfig) mandatory = c.mandatoryOnly;
    if (c is AllEvaluationsApprovedConfig)
      evaluationTypes = {...c.evaluationTypes};
  }

  String _value(AcademicRuleConfig? c) => switch (c) {
        MinimumAverageConfig c => '${c.minimumAverage}',
        MinimumGradeByTypeConfig c => '${c.minimumGrade}',
        MinimumApprovedPercentageConfig c => '${c.minimumPercentage}',
        MinimumApprovedCountConfig c => '${c.minimumCount}',
        _ => ''
      };
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.existing == null
              ? 'Agregar condición'
              : 'Editar condición'),
          content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField(
                    value: type,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de regla'),
                    items: AcademicRuleType.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(_label(e))))
                        .toList(),
                    onChanged: (v) => setState(() {
                          type = v!;
                          name.text = _label(type);
                          value.clear();
                        })),
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(
                    controller: description,
                    decoration: const InputDecoration(
                        labelText: 'Descripción opcional')),
                if (type == AcademicRuleType.minimumAverage ||
                    type == AcademicRuleType.minimumGradeByType ||
                    type == AcademicRuleType.minimumApprovedPercentage ||
                    type == AcademicRuleType.minimumApprovedCount)
                  TextField(
                      controller: value,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: switch (type) {
                        AcademicRuleType.minimumAverage => 'Promedio requerido',
                        AcademicRuleType.minimumGradeByType => 'Nota mínima',
                        AcademicRuleType.minimumApprovedPercentage =>
                          'Porcentaje',
                        _ => 'Cantidad'
                      })),
                if (type == AcademicRuleType.minimumGradeByType)
                  DropdownButtonFormField(
                      value: evaluationType,
                      decoration: const InputDecoration(
                          labelText: 'Tipo de evaluación'),
                      items: EvaluationType.values
                          .where((e) => e != EvaluationType.recovery)
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)))
                          .toList(),
                      onChanged: (v) => setState(() => evaluationType = v!)),
                if (type == AcademicRuleType.requiredEvaluation)
                  DropdownButtonFormField<String>(
                      value: evaluationId,
                      decoration:
                          const InputDecoration(labelText: 'Evaluación'),
                      items: widget.evaluations
                          .where((e) => !e.isRecovery)
                          .map((e) => DropdownMenuItem(
                              value: e.id, child: Text(e.name)))
                          .toList(),
                      onChanged: (v) => setState(() => evaluationId = v)),
                if (type == AcademicRuleType.minimumApprovedPercentage ||
                    type == AcademicRuleType.minimumApprovedCount ||
                    type == AcademicRuleType.allEvaluationsApproved)
                  SwitchListTile(
                      value: mandatory,
                      onChanged: (v) => setState(() => mandatory = v),
                      title: const Text('Solo obligatorias')),
                if (type == AcademicRuleType.minimumApprovedPercentage ||
                    type == AcademicRuleType.minimumApprovedCount ||
                    type == AcademicRuleType.allEvaluationsApproved) ...[
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Tipos (vacío = todos)')),
                  Wrap(
                      spacing: 6,
                      children: EvaluationType.values
                          .where((e) => e != EvaluationType.recovery)
                          .map((e) => FilterChip(
                              label: Text(e.name),
                              selected: evaluationTypes.contains(e),
                              onSelected: (selected) => setState(() => selected
                                  ? evaluationTypes.add(e)
                                  : evaluationTypes.remove(e))))
                          .toList()),
                ],
                SwitchListTile(
                    value: enabled,
                    onChanged: (v) => setState(() => enabled = v),
                    title: const Text('Habilitada'))
              ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(onPressed: _save, child: const Text('Guardar'))
          ]);
  void _save() {
    final number = double.tryParse(value.text.replaceAll(',', '.'));
    final AcademicRuleConfig config = switch (type) {
      AcademicRuleType.minimumAverage =>
        MinimumAverageConfig(number ?? double.nan),
      AcademicRuleType.minimumGradeByType =>
        MinimumGradeByTypeConfig(evaluationType, number ?? double.nan),
      AcademicRuleType.minimumApprovedPercentage =>
        MinimumApprovedPercentageConfig(number ?? double.nan,
            evaluationTypes: evaluationTypes, mandatoryOnly: mandatory),
      AcademicRuleType.minimumApprovedCount => MinimumApprovedCountConfig(
          number?.toInt() ?? 0,
          evaluationTypes: evaluationTypes,
          mandatoryOnly: mandatory),
      AcademicRuleType.allEvaluationsApproved => AllEvaluationsApprovedConfig(
          evaluationTypes: evaluationTypes, mandatoryOnly: mandatory),
      AcademicRuleType.requiredEvaluation =>
        RequiredEvaluationConfig(evaluationId ?? '')
    };
    final rule = AcademicRule(
        id: widget.existing?.id ??
            '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}',
        type: type,
        name: name.text,
        description: description.text,
        enabled: enabled,
        order: widget.order,
        config: config);
    final error = rule.validate(widget.subject);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context, rule);
  }

  String _label(AcademicRuleType t) => switch (t) {
        AcademicRuleType.minimumAverage => 'Promedio mínimo',
        AcademicRuleType.minimumGradeByType => 'Nota mínima por tipo',
        AcademicRuleType.minimumApprovedPercentage =>
          'Porcentaje mínimo aprobado',
        AcademicRuleType.minimumApprovedCount => 'Cantidad mínima aprobada',
        AcademicRuleType.allEvaluationsApproved =>
          'Todas las evaluaciones aprobadas',
        AcademicRuleType.requiredEvaluation => 'Evaluación obligatoria'
      };
}
