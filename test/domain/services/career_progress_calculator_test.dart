import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/entities/user_profile.dart';
import 'package:my_career/domain/services/career_progress_calculator.dart';

Subject subject(
  String id, {
  SubjectType type = SubjectType.mandatory,
  TrackingMode tracking = TrackingMode.historical,
  CourseStatus status = CourseStatus.finished,
  FinalOutcome? outcome,
  double? grade,
  double? points,
}) =>
    Subject(
      id: id,
      academicYearId: 'y',
      academicYear: 2026,
      trackingMode: tracking,
      name: 'Materia $id',
      subjectType: type,
      electivePoints: points,
      duration: SubjectDuration.annual,
      courseStatus: status,
      currentCondition:
          tracking == TrackingMode.tracked ? AcademicCondition.noData : null,
      finalOutcome: outcome,
      finalGrade: grade,
      gradeMin: 0,
      gradeMax: 10,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('promedio incluye solo aprobadas y promocionadas con nota', () {
    final result = CareerProgressCalculator.calculate([
      subject('a', outcome: FinalOutcome.approved, grade: 8),
      subject('b', outcome: FinalOutcome.promoted, grade: 10),
      subject('c', outcome: FinalOutcome.regularized, grade: null),
      subject('d', outcome: FinalOutcome.failed, grade: 2),
      subject('e', outcome: FinalOutcome.approved),
      subject('f', tracking: TrackingMode.tracked, status: CourseStatus.active),
    ]);
    expect(result.generalAverage, 9);
  });

  test('electivas separan obtenidos y en curso', () {
    final result = CareerProgressCalculator.calculate([
      subject('a',
          type: SubjectType.elective,
          points: 5,
          outcome: FinalOutcome.approved),
      subject('b',
          type: SubjectType.elective,
          points: 4,
          outcome: FinalOutcome.promoted),
      subject('c',
          type: SubjectType.elective, points: 3, outcome: FinalOutcome.failed),
      subject('d',
          type: SubjectType.elective,
          points: 6,
          tracking: TrackingMode.tracked,
          status: CourseStatus.active),
      subject('e', points: 20, outcome: FinalOutcome.approved),
    ]);
    expect(result.electiveObtained, 9);
    expect(result.electiveInProgress, 6);
  });

  test('requeridos expone restante y progreso sin limitar los datos', () {
    final profile = UserProfile(
      id: 'u',
      email: 'a@b.com',
      career: const CareerSettings(requiredElectivePoints: 20),
    );
    var result = CareerProgressCalculator.calculate([
      subject('a',
          type: SubjectType.elective,
          points: 12,
          outcome: FinalOutcome.approved),
    ], profile: profile);
    expect(result.electiveRemaining, 8);
    expect(result.electiveProgress, .6);
    result = CareerProgressCalculator.calculate([
      subject('a',
          type: SubjectType.elective,
          points: 22,
          outcome: FinalOutcome.approved),
    ], profile: profile);
    expect(result.electiveObtained, 22);
    expect(result.electiveProgress, 1.1);
  });

  test('sin requerido no calcula porcentaje', () {
    final result = CareerProgressCalculator.calculate(const []);
    expect(result.electiveRequired, isNull);
    expect(result.electiveProgress, isNull);
  });
}
