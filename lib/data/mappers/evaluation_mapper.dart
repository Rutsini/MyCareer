import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/evaluation.dart';
import '../../domain/entities/evaluation_reminder.dart';
import 'firestore_mapper_utils.dart';

T _enumValue<T extends Enum>(List<T> values, Object? value, T fallback) =>
    values.where((item) => item.name == value).firstOrNull ?? fallback;

abstract final class EvaluationMapper {
  static List<EvaluationReminder> remindersFromValue(Object? value) {
    if (value is! List) return const [];
    final result = <EvaluationReminder>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final id = map['id'];
      final offset = map['offsetMinutes'];
      if (id is! String || id.trim().isEmpty || offset is! num) continue;
      final reminder = EvaluationReminder(
        id: id,
        offsetMinutes: offset.toInt(),
        enabled: map['enabled'] as bool? ?? true,
      );
      if (reminder.validate() == null) result.add(reminder);
      if (result.length == 5) break;
    }
    return List.unmodifiable(result);
  }

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
      reminders: remindersFromValue(data['reminders']),
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
        'reminders': evaluation.reminders
            .map((reminder) => {
                  'id': reminder.id,
                  'offsetMinutes': reminder.offsetMinutes,
                  'enabled': reminder.enabled,
                })
            .toList(),
        'schemaVersion': 2,
      };
}
