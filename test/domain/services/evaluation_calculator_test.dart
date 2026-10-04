import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/services/evaluation_calculator.dart';

Subject subject({RecoveryPolicy policy = RecoveryPolicy.highestGrade}) =>
    Subject(
        id: 's',
        academicYearId: '2026',
        academicYear: 2026,
        trackingMode: TrackingMode.tracked,
        name: 'Materia',
        subjectType: SubjectType.mandatory,
        duration: SubjectDuration.annual,
        courseStatus: CourseStatus.active,
        gradeMin: 0,
        gradeMax: 10,
        recoveryPolicy: policy,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
Evaluation grade(String id, double? value,
        {double max = 10,
        double weight = 1,
        bool counts = true,
        EvaluationStatus status = EvaluationStatus.approved,
        String? recoveryOf}) =>
    Evaluation(
        id: id,
        subjectId: 's',
        academicYear: 2026,
        name: 'Evaluación $id',
        type: recoveryOf == null
            ? EvaluationType.partial
            : EvaluationType.recovery,
        date: DateTime(2026),
        allDay: true,
        mandatory: true,
        countsTowardAverage: counts,
        grade: value,
        maxGrade: max,
        weight: weight,
        status: status,
        isRecovery: recoveryOf != null,
        recoveryOfEvaluationId: recoveryOf,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));

void main() {
  test(
      'promedio simple',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(), [grade('a', 8), grade('b', 6)]),
          7));
  test(
      'promedio ponderado',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(), [grade('a', 8, weight: 2), grade('b', 10)]),
          closeTo(8.666666, .00001)));
  test(
      'pending sin nota no afecta',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(), [grade('a', null, status: EvaluationStatus.pending)]),
          isNull));
  test(
      'counts false no afecta',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(), [grade('a', 8, counts: false)]),
          isNull));
  test(
      'absent no afecta',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(), [grade('a', 8, status: EvaluationStatus.absent)]),
          isNull));
  test(
      'normaliza 80/100 a 8/10',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(), [grade('a', 80, max: 100)]),
          8));
  test(
      'replaceGrade usa recuperatorio',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(policy: RecoveryPolicy.replaceGrade),
              [grade('a', 4), grade('r', 8, recoveryOf: 'a')]),
          8));
  test(
      'highestGrade conserva la mejor original',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(), [grade('a', 8), grade('r', 6, recoveryOf: 'a')]),
          8));
  test(
      'highestGrade usa mejor recuperatorio',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(), [grade('a', 4), grade('r', 8, recoveryOf: 'a')]),
          8));
  test(
      'approvalOnly conserva valor original',
      () => expect(
          EvaluationCalculator.currentAverage(
              subject(policy: RecoveryPolicy.approvalOnly),
              [grade('a', 4), grade('r', 8, recoveryOf: 'a')]),
          4));
}
