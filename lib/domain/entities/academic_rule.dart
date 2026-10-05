import 'evaluation.dart';
import 'subject.dart';

const maxAcademicRulesPerCategory = 20;

enum AcademicRuleType {
  minimumAverage,
  minimumGradeByType,
  minimumApprovedPercentage,
  minimumApprovedCount,
  allEvaluationsApproved,
  requiredEvaluation,
}

sealed class AcademicRuleConfig {
  const AcademicRuleConfig();
}

class MinimumAverageConfig extends AcademicRuleConfig {
  const MinimumAverageConfig(this.minimumAverage);
  final double minimumAverage;
}

class MinimumGradeByTypeConfig extends AcademicRuleConfig {
  const MinimumGradeByTypeConfig(this.evaluationType, this.minimumGrade);
  final EvaluationType evaluationType;
  final double minimumGrade;
}

class MinimumApprovedPercentageConfig extends AcademicRuleConfig {
  const MinimumApprovedPercentageConfig(this.minimumPercentage,
      {this.evaluationTypes = const {}, this.mandatoryOnly = true});
  final double minimumPercentage;
  final Set<EvaluationType> evaluationTypes;
  final bool mandatoryOnly;
}

class MinimumApprovedCountConfig extends AcademicRuleConfig {
  const MinimumApprovedCountConfig(this.minimumCount,
      {this.evaluationTypes = const {}, this.mandatoryOnly = true});
  final int minimumCount;
  final Set<EvaluationType> evaluationTypes;
  final bool mandatoryOnly;
}

class AllEvaluationsApprovedConfig extends AcademicRuleConfig {
  const AllEvaluationsApprovedConfig(
      {this.evaluationTypes = const {}, this.mandatoryOnly = true});
  final Set<EvaluationType> evaluationTypes;
  final bool mandatoryOnly;
}

class RequiredEvaluationConfig extends AcademicRuleConfig {
  const RequiredEvaluationConfig(this.evaluationId);
  final String evaluationId;
}

class AcademicRule {
  const AcademicRule({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    this.enabled = true,
    required this.order,
    required this.config,
  });

  final String id;
  final AcademicRuleType type;
  final String name;
  final String? description;
  final bool enabled;
  final int order;
  final AcademicRuleConfig config;

  String? validate(Subject subject) {
    final length = name.trim().length;
    if (length < 2 || length > 100) {
      return 'El nombre debe tener entre 2 y 100 caracteres.';
    }
    if ((description?.trim().length ?? 0) > 500) {
      return 'La descripción puede tener hasta 500 caracteres.';
    }
    bool inScale(double value) =>
        value >= subject.gradeMin && value <= subject.gradeMax;
    return switch (config) {
      MinimumAverageConfig c when !inScale(c.minimumAverage) =>
        'El promedio debe estar dentro de la escala de la materia.',
      MinimumGradeByTypeConfig c
          when c.evaluationType == EvaluationType.recovery =>
        'Los recuperatorios no pueden configurarse como tipo objetivo.',
      MinimumGradeByTypeConfig c when !inScale(c.minimumGrade) =>
        'La nota mínima debe estar dentro de la escala de la materia.',
      MinimumApprovedPercentageConfig c
          when c.minimumPercentage <= 0 || c.minimumPercentage > 100 =>
        'El porcentaje debe ser mayor a 0 y menor o igual a 100.',
      MinimumApprovedCountConfig c when c.minimumCount <= 0 =>
        'La cantidad mínima debe ser mayor a cero.',
      RequiredEvaluationConfig c when c.evaluationId.trim().isEmpty =>
        'Seleccioná una evaluación.',
      _ => null,
    };
  }

  AcademicRule copyWith({
    String? id,
    AcademicRuleType? type,
    String? name,
    String? description,
    bool clearDescription = false,
    bool? enabled,
    int? order,
    AcademicRuleConfig? config,
  }) =>
      AcademicRule(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        description: clearDescription ? null : description ?? this.description,
        enabled: enabled ?? this.enabled,
        order: order ?? this.order,
        config: config ?? this.config,
      );
}
