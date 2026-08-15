import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/evaluation.dart';
import 'firestore_mapper_utils.dart';

T _enumValue<T extends Enum>(List<T> values, Object? value, T fallback) =>
    values.where((item) => item.name == value).firstOrNull ?? fallback;

abstract final class EvaluationMapper {
  static Evaluation fromDocument(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};
    return Evaluation(
      id: document.id,
      subjectId: data['subjectId'] as String? ?? '',
      academicYear: (data['academicYear'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      type:
          _enumValue(EvaluationType.values, data['type'], EvaluationType.other),
      date: dateFromFirestore(data['date']),
      allDay: data['allDay'] as bool? ?? true,
      mandatory: data['mandatory'] as bool? ?? true,
      countsTowardAverage: data['countsTowardAverage'] as bool? ?? true,
      grade: (data['grade'] as num?)?.toDouble(),
      maxGrade: numberToDouble(data['maxGrade'], 10),
      minimumPassingGradeOverride:
          (data['minimumPassingGradeOverride'] as num?)?.toDouble(),
      weight: numberToDouble(data['weight'], 1),
      presented: data['presented'] as bool?,
      status: _enumValue(
          EvaluationStatus.values, data['status'], EvaluationStatus.pending),
      isRecovery: data['isRecovery'] as bool? ?? false,
      recoveryOfEvaluationId: data['recoveryOfEvaluationId'] as String?,
      notes: data['notes'] as String?,
      createdAt: dateFromFirestore(data['createdAt']),
      updatedAt: dateFromFirestore(data['updatedAt']),
    );
  }

  static Map<String, dynamic> toMap(Evaluation evaluation,
          {required bool creating}) =>
      {
        'subjectId': evaluation.subjectId,
        'academicYear': evaluation.academicYear,
        'name': evaluation.name.trim(),
        'type': evaluation.type.name,
        'date': Timestamp.fromDate(evaluation.date),
        'allDay': evaluation.allDay,
        'mandatory': evaluation.mandatory,
        'countsTowardAverage': evaluation.countsTowardAverage,
        'grade': evaluation.grade,
        'maxGrade': evaluation.maxGrade,
        'minimumPassingGradeOverride': evaluation.minimumPassingGradeOverride,
        'weight': evaluation.weight,
        'presented': evaluation.presented,
        'status': evaluation.status.name,
        'isRecovery': evaluation.isRecovery,
        'recoveryOfEvaluationId':
            evaluation.isRecovery ? evaluation.recoveryOfEvaluationId : null,
        'notes': evaluation.notes?.trim().isEmpty ?? true
            ? null
            : evaluation.notes!.trim(),
        if (creating) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      };
}
