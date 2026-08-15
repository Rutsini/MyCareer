import '../../domain/entities/academic_rule.dart';
import '../../domain/entities/evaluation.dart';

abstract final class AcademicRuleMapper {
  static AcademicRule? tryFromMap(Object? value) {
    try {
      if (value is! Map) return null;
      final map = Map<String, dynamic>.from(value);
      final config = map['config'];
      if (config is! Map) return null;
      final c = Map<String, dynamic>.from(config);
      final type = AcademicRuleType.values
          .where((e) => e.name == map['type'])
          .firstOrNull;
      if (type == null) return null;
      Set<EvaluationType> types() =>
          ((c['evaluationTypes'] as List?) ?? const [])
              .map((v) =>
                  EvaluationType.values.where((e) => e.name == v).firstOrNull)
              .whereType<EvaluationType>()
              .toSet();
      final AcademicRuleConfig parsed = switch (type) {
        AcademicRuleType.minimumAverage =>
          MinimumAverageConfig((c['minimumAverage'] as num).toDouble()),
        AcademicRuleType.minimumGradeByType => MinimumGradeByTypeConfig(
            EvaluationType.values
                .firstWhere((e) => e.name == c['evaluationType']),
            (c['minimumGrade'] as num).toDouble()),
        AcademicRuleType.minimumApprovedPercentage =>
          MinimumApprovedPercentageConfig(
              (c['minimumPercentage'] as num).toDouble(),
              evaluationTypes: types(),
              mandatoryOnly: c['mandatoryOnly'] as bool? ?? true),
        AcademicRuleType.minimumApprovedCount => MinimumApprovedCountConfig(
            (c['minimumCount'] as num).toInt(),
            evaluationTypes: types(),
            mandatoryOnly: c['mandatoryOnly'] as bool? ?? true),
        AcademicRuleType.allEvaluationsApproved => AllEvaluationsApprovedConfig(
            evaluationTypes: types(),
            mandatoryOnly: c['mandatoryOnly'] as bool? ?? true),
        AcademicRuleType.requiredEvaluation =>
          RequiredEvaluationConfig(c['evaluationId'] as String),
      };
      return AcademicRule(
          id: map['id'] as String,
          type: type,
          name: map['name'] as String,
          description: map['description'] as String?,
          enabled: map['enabled'] as bool? ?? true,
          order: (map['order'] as num?)?.toInt() ?? 0,
          config: parsed);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> toMap(AcademicRule r) => {
        'id': r.id,
        'type': r.type.name,
        'name': r.name.trim(),
        'description': r.description?.trim().isEmpty ?? true
            ? null
            : r.description!.trim(),
        'enabled': r.enabled,
        'order': r.order,
        'config': _config(r.config)
      };
  static Map<String, dynamic> _config(AcademicRuleConfig c) => switch (c) {
        MinimumAverageConfig c => {'minimumAverage': c.minimumAverage},
        MinimumGradeByTypeConfig c => {
            'evaluationType': c.evaluationType.name,
            'minimumGrade': c.minimumGrade
          },
        MinimumApprovedPercentageConfig c => {
            'minimumPercentage': c.minimumPercentage,
            'evaluationTypes': c.evaluationTypes.map((e) => e.name).toList(),
            'mandatoryOnly': c.mandatoryOnly
          },
        MinimumApprovedCountConfig c => {
            'minimumCount': c.minimumCount,
            'evaluationTypes': c.evaluationTypes.map((e) => e.name).toList(),
            'mandatoryOnly': c.mandatoryOnly
          },
        AllEvaluationsApprovedConfig c => {
            'evaluationTypes': c.evaluationTypes.map((e) => e.name).toList(),
            'mandatoryOnly': c.mandatoryOnly
          },
        RequiredEvaluationConfig c => {'evaluationId': c.evaluationId},
      };
}
