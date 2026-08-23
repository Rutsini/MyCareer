// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/academic_rule.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../../domain/entities/subject.dart';
import '../../../../domain/services/academic_engine.dart';
import '../../../../core/formatters/academic_rule_type_formatter.dart';
import '../../../evaluations/application/evaluation_controller.dart';
import '../../application/academic_controller.dart';
import 'academic_rule_editor.dart';
import 'academic_rule_type_help_button.dart';

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
                        title: Row(children: [
                          Expanded(child: Text(rule.name)),
                          AcademicRuleTypeHelpButton(type: rule.type),
                        ]),
                        subtitle: Text(
                            '${academicRuleTypeLabel(rule.type)}\n${!rule.enabled ? 'Deshabilitada' : _resultText(result)}'),
                        isThreeLine: true,
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
    final rule = await showAcademicRuleEditor(context,
        subject: subject,
        evaluations: evaluations,
        existing: existing,
        order: existing?.order ??
            (promotion
                ? subject.promotionRules.length
                : subject.regularityRules.length));
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
