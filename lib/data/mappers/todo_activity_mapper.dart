import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/todo_activity.dart';
import 'firestore_mapper_utils.dart';

abstract final class TodoActivityMapper {
  static TodoActivity fromDocument(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};
    final storedDay = data['day'];
    return TodoActivity(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      day: storedDay is String
          ? DateTime.tryParse(storedDay) ?? DateTime(1970)
          : DateTime(1970),
      subjectId: data['subjectId'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: dateFromFirestore(data['createdAt']),
      updatedAt: dateFromFirestore(data['updatedAt']),
    );
  }

  static Map<String, dynamic> toMap(TodoActivity activity,
          {required bool creating}) =>
      {
        'title': activity.title.trim(),
        'description': activity.description?.trim().isEmpty ?? true
            ? null
            : activity.description!.trim(),
        'day': _dayKey(activity.day),
        'subjectId': activity.subjectId,
        'isCompleted': activity.isCompleted,
        if (creating) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      };

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
