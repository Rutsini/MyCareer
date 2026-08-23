import '../../domain/entities/academic_rule.dart';

String academicRuleTypeLabel(AcademicRuleType type) => switch (type) {
      AcademicRuleType.minimumAverage => 'Promedio mínimo',
      AcademicRuleType.minimumGradeByType =>
        'Nota mínima por tipo de evaluación',
      AcademicRuleType.minimumApprovedPercentage =>
        'Porcentaje mínimo aprobado',
      AcademicRuleType.minimumApprovedCount => 'Cantidad mínima aprobada',
      AcademicRuleType.allEvaluationsApproved =>
        'Todas las evaluaciones aprobadas',
      AcademicRuleType.requiredEvaluation => 'Evaluación obligatoria',
    };

String academicRuleTypeDescription(AcademicRuleType type) => switch (type) {
      AcademicRuleType.minimumAverage =>
        'Exige alcanzar un promedio mínimo entre las evaluaciones consideradas.',
      AcademicRuleType.minimumGradeByType =>
        'Exige una nota mínima en las evaluaciones de un tipo específico, por ejemplo parciales o trabajos prácticos.',
      AcademicRuleType.minimumApprovedPercentage =>
        'Exige aprobar un porcentaje mínimo de las evaluaciones consideradas.',
      AcademicRuleType.minimumApprovedCount =>
        'Exige aprobar una cantidad mínima de evaluaciones.',
      AcademicRuleType.allEvaluationsApproved =>
        'Exige aprobar todas las evaluaciones consideradas.',
      AcademicRuleType.requiredEvaluation =>
        'Exige aprobar una evaluación específica.',
    };
