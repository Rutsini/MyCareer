import '../entities/subject.dart';
import '../entities/user_profile.dart';
import '../models/career_progress_summary.dart';

abstract final class CareerProgressCalculator {
  static CareerProgressSummary calculate(
    Iterable<Subject> subjects, {
    UserProfile? profile,
  }) {
    final completedWithGrade = subjects.where(
      (subject) =>
          (subject.finalOutcome == FinalOutcome.approved ||
              subject.finalOutcome == FinalOutcome.promoted) &&
          subject.finalGrade != null,
    );
    final grades = completedWithGrade.map((subject) => subject.finalGrade!);
    final gradeList = grades.toList();
    final generalAverage = gradeList.isEmpty
        ? null
        : gradeList.fold<double>(0, (sum, grade) => sum + grade) /
            gradeList.length;

    double points(Iterable<Subject> values) => values.fold<double>(
          0,
          (sum, subject) => sum + (subject.electivePoints ?? 0),
        );

    final electiveObtained = points(subjects.where(
      (subject) =>
          subject.subjectType == SubjectType.elective &&
          (subject.finalOutcome == FinalOutcome.approved ||
              subject.finalOutcome == FinalOutcome.promoted),
    ));
    final electiveInProgress = points(subjects.where(
      (subject) =>
          subject.subjectType == SubjectType.elective &&
          subject.trackingMode == TrackingMode.tracked &&
          subject.courseStatus == CourseStatus.active,
    ));

    return CareerProgressSummary(
      generalAverage: generalAverage,
      electiveObtained: electiveObtained,
      electiveInProgress: electiveInProgress,
      electiveRequired: profile?.career.requiredElectivePoints,
    );
  }
}
