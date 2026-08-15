import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/academic_rule.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/subject.dart';

void main() {
  final s = Subject(
      id: 's',
      academicYearId: 'y',
      academicYear: 2026,
      trackingMode: TrackingMode.tracked,
      name: 'Materia',
      subjectType: SubjectType.mandatory,
      duration: SubjectDuration.annual,
      courseStatus: CourseStatus.active,
      currentCondition: AcademicCondition.noData,
      gradeMin: 0,
      gradeMax: 10,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026));
  AcademicRule r(AcademicRuleConfig c) => AcademicRule(
      id: 'r',
      type: AcademicRuleType.minimumAverage,
      name: 'Regla',
      order: 0,
      config: c);
  test('average dentro y fuera de escala', () {
    expect(r(const MinimumAverageConfig(8)).validate(s), isNull);
    expect(r(const MinimumAverageConfig(11)).validate(s), isNotNull);
  });
  test('minimum grade y recovery', () {
    expect(
        r(const MinimumGradeByTypeConfig(EvaluationType.partial, 6))
            .validate(s),
        isNull);
    expect(
        r(const MinimumGradeByTypeConfig(EvaluationType.recovery, 6))
            .validate(s),
        isNotNull);
  });
  test('porcentaje y count', () {
    expect(r(const MinimumApprovedPercentageConfig(100)).validate(s), isNull);
    expect(
        r(const MinimumApprovedPercentageConfig(101)).validate(s), isNotNull);
    expect(r(const MinimumApprovedCountConfig(0)).validate(s), isNotNull);
  });
  test(
      'required vacío',
      () =>
          expect(r(const RequiredEvaluationConfig('')).validate(s), isNotNull));
}
