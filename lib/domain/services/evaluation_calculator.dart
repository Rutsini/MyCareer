import '../entities/evaluation.dart';
import '../entities/subject.dart';

abstract final class EvaluationCalculator {
  static double? currentAverage(
    Subject subject,
    Iterable<Evaluation> evaluations,
  ) {
    final valid = evaluations
        .where((e) => e.subjectId == subject.id)
        .where((e) => e.countsTowardAverage)
        .where((e) => e.grade != null)
        .where((e) => e.status != EvaluationStatus.absent)
        .toList();
    final byId = {for (final e in valid) e.id: e};
    final recoveries = <String, Evaluation>{};
    for (final evaluation in valid.where((e) => e.isRecovery)) {
      final originalId = evaluation.recoveryOfEvaluationId;
      if (originalId == null) continue;
      final previous = recoveries[originalId];
      if (previous == null || evaluation.date.isAfter(previous.date)) {
        recoveries[originalId] = evaluation;
      }
    }

    final entries = <({double grade, double weight})>[];
    for (final evaluation in valid.where((e) => !e.isRecovery)) {
      final recovery = recoveries[evaluation.id];
      var selected = evaluation;
      if (recovery != null) {
        switch (subject.recoveryPolicy) {
          case RecoveryPolicy.replaceGrade:
            selected = recovery;
          case RecoveryPolicy.highestGrade:
            if (_normalized(recovery, subject) >
                _normalized(evaluation, subject)) {
              selected = recovery;
            }
          case RecoveryPolicy.approvalOnly:
            break;
        }
      }
      entries.add(
          (grade: _normalized(selected, subject), weight: selected.weight));
    }
    // A recovery whose original is unavailable remains useful without double count.
    for (final recovery in valid.where((e) => e.isRecovery)) {
      if (!byId.containsKey(recovery.recoveryOfEvaluationId)) {
        entries.add(
            (grade: _normalized(recovery, subject), weight: recovery.weight));
      }
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

  static double _normalized(Evaluation evaluation, Subject subject) =>
      subject.gradeMin +
      (evaluation.grade! / evaluation.maxGrade) *
          (subject.gradeMax - subject.gradeMin);
}
