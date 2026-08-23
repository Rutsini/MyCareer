import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/core/formatters/academic_rule_type_formatter.dart';
import 'package:my_career/domain/entities/academic_rule.dart';

void main() {
  test('expone nombre y ayuda para cada tipo de condición', () {
    expect(academicRuleTypeLabel(AcademicRuleType.minimumAverage),
        'Promedio mínimo');
    expect(academicRuleTypeDescription(AcademicRuleType.minimumAverage),
        'Exige alcanzar un promedio mínimo entre las evaluaciones consideradas.');
    expect(academicRuleTypeDescription(AcademicRuleType.minimumGradeByType),
        'Exige una nota mínima en las evaluaciones de un tipo específico, por ejemplo parciales o trabajos prácticos.');
    for (final type in AcademicRuleType.values) {
      expect(academicRuleTypeLabel(type), isNotEmpty);
      expect(academicRuleTypeDescription(type), isNotEmpty);
    }
  });
}
