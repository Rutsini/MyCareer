// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:math' as math;
import '../entities/academic_rule.dart';
import '../entities/evaluation.dart';
import '../entities/subject.dart';
import 'evaluation_calculator.dart';
import 'evaluation_resolver.dart';

enum RuleResultStatus { met, pending, unmet }

class AcademicRuleResult {
  const AcademicRuleResult(
      {required this.ruleId,
      required this.status,
      required this.reachable,
      required this.message,
      this.currentValue,
      this.requiredValue,
      this.actions = const []});
  final String ruleId;
  final RuleResultStatus status;
  final bool reachable;
  final String message;
  final double? currentValue;
  final double? requiredValue;
  final List<String> actions;
}

class AcademicSubjectResult {
  const AcademicSubjectResult(
      {required this.condition,
      required this.promotionResults,
      required this.regularityResults,
      required this.promotionConfigured,
      required this.regularityConfigured,
      required this.promotionReachable,
      required this.regularityReachable,
      required this.summary,
      required this.actions});
  final AcademicCondition? condition;
  final List<AcademicRuleResult> promotionResults, regularityResults;
  final bool promotionConfigured,
      regularityConfigured,
      promotionReachable,
      regularityReachable;
  final String summary;
  final List<String> actions;
}

class AcademicEngine {
  const AcademicEngine();
  AcademicSubjectResult evaluate(
      {required Subject subject, required List<Evaluation> evaluations}) {
    if (subject.trackingMode == TrackingMode.historical)
      return const AcademicSubjectResult(
          condition: null,
          promotionResults: [],
          regularityResults: [],
          promotionConfigured: false,
          regularityConfigured: false,
          promotionReachable: false,
          regularityReachable: false,
          summary: 'Las materias históricas no requieren reglas de cursado.',
          actions: []);
    List<AcademicRule> enabled(List<AcademicRule> rules) =>
        (rules.where((r) => r.enabled).toList()
          ..sort((a, b) => a.order.compareTo(b.order)));
    final promotion = enabled(subject.promotionRules);
    final regularity = enabled(subject.regularityRules);
    final pr =
        promotion.map((r) => _evaluate(r, subject, evaluations)).toList();
    final rr =
        regularity.map((r) => _evaluate(r, subject, evaluations)).toList();
    final hasEvidence = evaluations.where((e) => e.subjectId == subject.id).any(
        (e) =>
            e.grade != null ||
            e.status != EvaluationStatus.pending &&
                e.status != EvaluationStatus.submitted);
    bool allMet(List<AcademicRuleResult> r) =>
        r.isNotEmpty && r.every((e) => e.status == RuleResultStatus.met);
    final AcademicCondition condition;
    if (promotion.isEmpty && regularity.isEmpty)
      condition = AcademicCondition.noData;
    else if (allMet(pr))
      condition = AcademicCondition.promoting;
    else if (allMet(rr))
      condition = AcademicCondition.regular;
    else if (subject.courseStatus == CourseStatus.pending && !hasEvidence)
      condition = AcademicCondition.noData;
    else if (rr.any((e) => e.status == RuleResultStatus.unmet))
      condition = subject.courseStatus == CourseStatus.finished
          ? AcademicCondition.failed
          : AcademicCondition.atRisk;
    else
      condition = AcademicCondition.noData;
    final actions = [...pr, ...rr].expand((e) => e.actions).toList();
    return AcademicSubjectResult(
        condition: condition,
        promotionResults: pr,
        regularityResults: rr,
        promotionConfigured: promotion.isNotEmpty,
        regularityConfigured: regularity.isNotEmpty,
        promotionReachable: pr.every((e) => e.reachable),
        regularityReachable: rr.every((e) => e.reachable),
        summary: _conditionLabel(condition),
        actions: actions);
  }

  AcademicRuleResult _evaluate(
      AcademicRule rule, Subject s, List<Evaluation> evaluations) {
    final logical = EvaluationResolver.resolve(s, evaluations);
    bool reachable(RuleResultStatus status) =>
        status == RuleResultStatus.met ||
        s.courseStatus != CourseStatus.finished;
    AcademicRuleResult result(RuleResultStatus status, String message,
            {double? current,
            double? required,
            List<String> actions = const []}) =>
        AcademicRuleResult(
            ruleId: rule.id,
            status: status,
            reachable: reachable(status),
            message: message,
            currentValue: current,
            requiredValue: required,
            actions: actions);
    final c = rule.config;
    if (c is MinimumAverageConfig) {
      final average = EvaluationCalculator.currentAverage(s, evaluations);
      if (average == null)
        return result(RuleResultStatus.pending,
            'Aún no hay notas suficientes para calcular el promedio.',
            required: c.minimumAverage);
      final met = average >= c.minimumAverage;
      final actions = <String>[];
      if (!met) actions.add(_averageAction(s, evaluations, c.minimumAverage));
      return result(
          met ? RuleResultStatus.met : RuleResultStatus.unmet,
          met
              ? 'Cumplís el promedio mínimo.'
              : 'Tu promedio actual es ${_n(average)} y se requiere ${_n(c.minimumAverage)}.',
          current: average,
          required: c.minimumAverage,
          actions: actions);
    }
    bool filter(
            EffectiveEvaluation e, Set<EvaluationType> types, bool mandatory) =>
        (!mandatory || e.original.mandatory) &&
        (types.isEmpty || types.contains(e.original.type));
    if (c is MinimumGradeByTypeConfig) {
      final values =
          logical.where((e) => e.original.type == c.evaluationType).toList();
      if (values.isEmpty)
        return result(
            RuleResultStatus.pending, 'Todavía no hay evaluaciones aplicables.',
            required: c.minimumGrade);
      if (values.any((e) => e.pending || e.gradeSource.grade == null))
        return result(
            RuleResultStatus.pending, 'Todavía hay evaluaciones sin resultado.',
            required: c.minimumGrade);
      final minimum = values.map((e) => e.normalizedGrade(s)).reduce(math.min);
      final met = minimum >= c.minimumGrade;
      return result(
          met ? RuleResultStatus.met : RuleResultStatus.unmet,
          met
              ? 'Todas las evaluaciones del tipo cumplen la nota mínima.'
              : 'Hay evaluaciones por debajo de ${_n(c.minimumGrade)}.',
          current: minimum,
          required: c.minimumGrade,
          actions:
              met ? [] : ['Mejorar las evaluaciones por debajo del mínimo.']);
    }
    if (c is MinimumApprovedCountConfig) {
      final values = logical
          .where((e) => filter(e, c.evaluationTypes, c.mandatoryOnly))
          .toList();
      final count = values.where((e) => e.approved).length;
      final met = count >= c.minimumCount;
      return result(met ? RuleResultStatus.met : RuleResultStatus.unmet,
          'Tenés $count de ${c.minimumCount} evaluaciones aprobadas.',
          current: count.toDouble(),
          required: c.minimumCount.toDouble(),
          actions: met
              ? []
              : [
                  'Falta aprobar ${c.minimumCount - count} evaluación${c.minimumCount - count == 1 ? '' : 'es'}.'
                ]);
    }
    if (c is MinimumApprovedPercentageConfig) {
      final values = logical
          .where((e) => filter(e, c.evaluationTypes, c.mandatoryOnly))
          .toList();
      if (values.isEmpty)
        return result(
            RuleResultStatus.pending, 'Todavía no hay evaluaciones aplicables.',
            required: c.minimumPercentage);
      final approved = values.where((e) => e.approved).length;
      final pct = approved * 100 / values.length;
      final met = pct >= c.minimumPercentage;
      final needed = (c.minimumPercentage * values.length / 100).ceil();
      return result(met ? RuleResultStatus.met : RuleResultStatus.unmet,
          'Tenés ${_n(pct)} % de evaluaciones aprobadas.',
          current: pct,
          required: c.minimumPercentage,
          actions: met
              ? []
              : [
                  'Necesitás al menos $needed de ${values.length} evaluaciones aprobadas.'
                ]);
    }
    if (c is AllEvaluationsApprovedConfig) {
      final values = logical
          .where((e) => filter(e, c.evaluationTypes, c.mandatoryOnly))
          .toList();
      if (values.isEmpty)
        return result(RuleResultStatus.pending,
            'Todavía no hay evaluaciones aplicables.');
      final failed = values.where((e) => !e.approved && !e.pending).toList();
      final pending = values.where((e) => e.pending).toList();
      if (failed.isNotEmpty)
        return result(RuleResultStatus.unmet,
            'Hay evaluaciones obligatorias no aprobadas.',
            actions: failed.map((e) => 'Aprobar ${e.original.name}.').toList());
      if (pending.isNotEmpty)
        return result(
            RuleResultStatus.pending, 'Todavía hay evaluaciones pendientes.',
            actions:
                pending.map((e) => 'Aprobar ${e.original.name}.').toList());
      return result(RuleResultStatus.met,
          'Todas las evaluaciones aplicables están aprobadas.');
    }
    if (c is RequiredEvaluationConfig) {
      final value =
          logical.where((e) => e.original.id == c.evaluationId).firstOrNull;
      if (value == null)
        return result(RuleResultStatus.pending,
            'La evaluación configurada ya no existe. Editá esta regla.',
            actions: [
              'Revisar la evaluación eliminada asociada a esta regla.'
            ]);
      if (value.approved)
        return result(
            RuleResultStatus.met, 'La evaluación obligatoria está aprobada.');
      if (value.pending)
        return result(RuleResultStatus.pending,
            '${value.original.name} todavía está pendiente.',
            actions: ['Aprobar ${value.original.name}.']);
      return result(
          RuleResultStatus.unmet, '${value.original.name} no está aprobada.',
          actions: ['Aprobar ${value.original.name}.']);
    }
    throw StateError('Configuración de regla no soportada.');
  }

  String _averageAction(Subject s, List<Evaluation> all, double target) {
    final pending = all
        .where((e) =>
            e.subjectId == s.id &&
            !e.isRecovery &&
            e.countsTowardAverage &&
            e.grade == null)
        .toList();
    if (pending.length != 1)
      return 'Subir el promedio hasta ${_n(target)}. No hay una única nota exacta porque quedan varias evaluaciones pendientes.';
    final known = EvaluationResolver.resolve(s, all)
        .where((e) =>
            e.original.countsTowardAverage && e.gradeSource.grade != null)
        .toList();
    final weight = known.fold<double>(0, (a, e) => a + e.gradeSource.weight);
    final sum = known.fold<double>(
        0, (a, e) => a + e.normalizedGrade(s) * e.gradeSource.weight);
    final p = pending.single;
    final normalized = (target * (weight + p.weight) - sum) / p.weight;
    final raw =
        (normalized - s.gradeMin) / (s.gradeMax - s.gradeMin) * p.maxGrade;
    if (raw > p.maxGrade)
      return 'Con ${p.name} sola no alcanza para llegar al promedio requerido.';
    return 'Necesitás al menos ${_n(raw)} en ${p.name}.';
  }

  static String _n(double v) =>
      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1).replaceAll('.', ',');
  static String _conditionLabel(AcademicCondition c) => switch (c) {
        AcademicCondition.noData => 'Sin datos',
        AcademicCondition.promoting => 'En condición de promoción',
        AcademicCondition.regular => 'Regular',
        AcademicCondition.atRisk => 'En riesgo',
        AcademicCondition.failed => 'No regularizó'
      };
}
