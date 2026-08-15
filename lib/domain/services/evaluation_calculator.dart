// ignore_for_file: curly_braces_in_flow_control_structures
import '../entities/evaluation.dart';
import '../entities/subject.dart';
import 'evaluation_resolver.dart';

abstract final class EvaluationCalculator {
  static double? currentAverage(
    Subject subject,
    Iterable<Evaluation> evaluations,
  ) {
    final entries = <({double grade, double weight})>[];
    for (final logical in EvaluationResolver.resolve(subject, evaluations)) {
      final selected = logical.gradeSource;
      if (!logical.original.countsTowardAverage ||
          selected.grade == null ||
          selected.status == EvaluationStatus.absent) continue;
      entries.add(
          (grade: logical.normalizedGrade(subject), weight: selected.weight));
    }
    if (entries.isEmpty) return null;
    final totalWeight = entries.fold<double>(0, (sum, e) => sum + e.weight);
    return entries.fold<double>(0, (sum, e) => sum + e.grade * e.weight) /
        totalWeight;
  }

  static Evaluation? nextEvaluation(
    Iterable<Evaluation> evaluations, {
    required String subjectId,
    DateTime? now,
  }) {
    final instant = now ?? DateTime.now();
    final upcoming = evaluations
        .where((e) => e.subjectId == subjectId)
        .where((e) => e.status == EvaluationStatus.pending)
        .where((e) => !e.date.isBefore(instant))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.firstOrNull;
  }
}
