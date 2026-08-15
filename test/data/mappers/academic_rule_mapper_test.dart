import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/mappers/academic_rule_mapper.dart';
import 'package:my_career/domain/entities/academic_rule.dart';
import 'package:my_career/domain/entities/evaluation.dart';

void main() {
  test('roundtrip de regla schema v2', () {
    const rule = AcademicRule(
        id: 'r',
        type: AcademicRuleType.minimumGradeByType,
        name: 'Mínimo parcial',
        order: 1,
        config: MinimumGradeByTypeConfig(EvaluationType.partial, 6));
    final parsed =
        AcademicRuleMapper.tryFromMap(AcademicRuleMapper.toMap(rule));
    expect(parsed, isNotNull);
    expect(parsed!.type, AcademicRuleType.minimumGradeByType);
    expect((parsed.config as MinimumGradeByTypeConfig).minimumGrade, 6);
  });
  test(
      'tipo desconocido se ignora',
      () => expect(
          AcademicRuleMapper.tryFromMap(
              {'id': 'x', 'type': 'future', 'name': 'X', 'config': {}}),
          isNull));
  test(
      'config corrupta se ignora sin excepción',
      () => expect(
          AcademicRuleMapper.tryFromMap({
            'id': 'x',
            'type': 'minimumAverage',
            'name': 'X',
            'config': {'minimumAverage': 'bad'}
          }),
          isNull));
}
