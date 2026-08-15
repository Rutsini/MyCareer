// ignore_for_file: curly_braces_in_flow_control_structures
import '../entities/evaluation.dart';
import '../entities/subject.dart';

class EffectiveEvaluation {
  const EffectiveEvaluation(
      {required this.original,
      this.recovery,
      required this.gradeSource,
      required this.approved,
      required this.pending});
  final Evaluation original;
  final Evaluation? recovery;
  final Evaluation gradeSource;
  final bool approved;
  final bool pending;
  double normalizedGrade(Subject subject) =>
      EvaluationResolver.normalizedGrade(gradeSource, subject);
}

abstract final class EvaluationResolver {
  static List<EffectiveEvaluation> resolve(
      Subject subject, Iterable<Evaluation> values) {
    final items = values.where((e) => e.subjectId == subject.id).toList();
    final originals = items.where((e) => !e.isRecovery).toList();
    final recoveries = <String, Evaluation>{};
    for (final r in items.where((e) => e.isRecovery)) {
      final id = r.recoveryOfEvaluationId;
      if (id == null) continue;
      final old = recoveries[id];
      if (old == null || r.date.isAfter(old.date)) recoveries[id] = r;
    }
    return originals.map((original) {
      final recovery = recoveries[original.id];
      var source = original;
      if (recovery?.grade != null) {
        switch (subject.recoveryPolicy) {
          case RecoveryPolicy.replaceGrade:
            source = recovery!;
          case RecoveryPolicy.highestGrade:
            if (original.grade == null ||
                normalizedGrade(recovery!, subject) >
                    normalizedGrade(original, subject)) source = recovery!;
          case RecoveryPolicy.approvalOnly:
            break;
        }
      }
      final originalApproved = _approved(original);
      final recoveryApproved = recovery != null && _approved(recovery);
      final approved = subject.recoveryPolicy == RecoveryPolicy.approvalOnly
          ? originalApproved || recoveryApproved
          : _approved(source);
      final pending =
          !_decided(original) && (recovery == null || !_decided(recovery));
      return EffectiveEvaluation(
          original: original,
          recovery: recovery,
          gradeSource: source,
          approved: approved,
          pending: pending);
    }).toList();
  }

  static double normalizedGrade(Evaluation e, Subject subject) {
    if (e.grade == null) return subject.gradeMin;
    return subject.gradeMin +
        (e.grade! / e.maxGrade) * (subject.gradeMax - subject.gradeMin);
  }

  static bool _approved(Evaluation e) =>
      e.status == EvaluationStatus.approved ||
      e.status == EvaluationStatus.recovered;
  static bool _decided(Evaluation e) =>
      e.status != EvaluationStatus.pending &&
      e.status != EvaluationStatus.submitted;
}
