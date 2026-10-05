import '../../domain/entities/todo_activity.dart';
import '../firebase/todo_activity_service.dart';
import '../mappers/todo_activity_mapper.dart';

abstract interface class TodoActivityRepository {
  Stream<List<TodoActivity>> watchActivities();
  Future<String> createActivity(TodoActivity activity);
  Future<void> updateActivity(TodoActivity activity);
  Future<void> deleteActivity(String id);
}

class FirebaseTodoActivityRepository implements TodoActivityRepository {
  FirebaseTodoActivityRepository(this._service);

  final TodoActivityService _service;

  @override
  Stream<List<TodoActivity>> watchActivities() =>
      _service.watchActivities().map((snapshot) {
        final activities =
            snapshot.docs.map(TodoActivityMapper.fromDocument).toList();
        activities.sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          final byDay = a.day.compareTo(b.day);
          return byDay != 0 ? byDay : a.title.compareTo(b.title);
        });
        return activities;
      });

  @override
  Future<String> createActivity(TodoActivity activity) =>
      _service.createActivity(activity);

  @override
  Future<void> updateActivity(TodoActivity activity) =>
      _service.updateActivity(activity);

  @override
  Future<void> deleteActivity(String id) => _service.deleteActivity(id);
}
