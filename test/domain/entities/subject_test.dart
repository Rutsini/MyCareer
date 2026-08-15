import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/subject.dart';

Subject subject({
  TrackingMode mode = TrackingMode.tracked,
  String name = 'Física II',
  SubjectType type = SubjectType.mandatory,
  double? points,
  SubjectDuration duration = SubjectDuration.annual,
  Semester? semester,
  FinalOutcome? outcome,
  double? grade,
}) =>
    Subject(
      id: '',
      academicYearId: '2026',
      academicYear: 2026,
      trackingMode: mode,
      name: name,
      subjectType: type,
      electivePoints: points,
      duration: duration,
      semester: semester,
      courseStatus: mode == TrackingMode.tracked
          ? CourseStatus.active
          : CourseStatus.finished,
      currentCondition:
          mode == TrackingMode.tracked ? AcademicCondition.noData : null,
      finalOutcome: outcome,
      finalGrade: grade,
      gradeMin: 0,
      gradeMax: 10,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('Subject', () {
    test('exige nombre válido',
        () => expect(subject(name: '').validate(), isNotNull));
    test(
        'electiva exige puntos positivos',
        () =>
            expect(subject(type: SubjectType.elective).validate(), isNotNull));
    test('obligatoria no admite puntos',
        () => expect(subject(points: 3).validate(), isNotNull));
    test('anual exige semester null',
        () => expect(subject(semester: Semester.first).validate(), isNotNull));
    test(
        'cuatrimestral exige semester',
        () => expect(
            subject(duration: SubjectDuration.semester).validate(), isNotNull));
    test(
        'nota final debe respetar escala',
        () => expect(
            subject(
                    mode: TrackingMode.historical,
                    outcome: FinalOutcome.approved,
                    grade: 11)
                .validate(),
            isNotNull));
  });
  group('Historical subject', () {
    test(
        'abandonada no admite nota',
        () => expect(
            subject(
                    mode: TrackingMode.historical,
                    outcome: FinalOutcome.abandoned,
                    grade: 7)
                .validate(),
            isNotNull));
    test(
        'regularizada puede no tener nota',
        () => expect(
            subject(
                    mode: TrackingMode.historical,
                    outcome: FinalOutcome.regularized)
                .validate(),
            isNull));
    test(
        'aprobada admite nota final',
        () => expect(
            subject(
                    mode: TrackingMode.historical,
                    outcome: FinalOutcome.approved,
                    grade: 8)
                .validate(),
            isNull));
  });
}
