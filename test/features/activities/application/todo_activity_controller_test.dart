import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/repositories/todo_activity_repository.dart';
import 'package:my_career/domain/entities/todo_activity.dart';
import 'package:my_career/features/activities/application/todo_activity_controller.dart';

class FakeTodoActivityRepository implements TodoActivityRepository {
  String? operation;
  TodoActivity? saved;

  @override
  Future<String> createActivity(TodoActivity activity) async {
    operation = 'create';
    saved = activity;
    return 'new';
  }

  @override
  Future<void> updateActivity(TodoActivity activity) async {
    operation = 'update';
    saved = activity;
  }

  @override
  Future<void> deleteActivity(String id) async {
    operation = 'delete';
  }

  @override
  Stream<List<TodoActivity>> watchActivities() => const Stream.empty();
}

TodoActivity value(String id, {bool completed = false}) => TodoActivity(
      id: id,
      title: '  Leer capítulo  ',
      day: DateTime(2026, 10, 5, 18),
      isCompleted: completed,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('crea y normaliza una actividad', () async {
    final repository = FakeTodoActivityRepository();
    final controller = TodoActivityController(repository);

    expect(await controller.save(value('')), 'new');
    expect(repository.operation, 'create');
    expect(repository.saved?.title, 'Leer capítulo');
    expect(repository.saved?.day, DateTime(2026, 10, 5));
  });

  test('actualiza el estado completado', () async {
    final repository = FakeTodoActivityRepository();
    final controller = TodoActivityController(repository);

    expect(await controller.setCompleted(value('activity'), true), isTrue);
    expect(repository.operation, 'update');
    expect(repository.saved?.isCompleted, isTrue);
  });

  test('elimina una actividad', () async {
    final repository = FakeTodoActivityRepository();
    final controller = TodoActivityController(repository);

    expect(await controller.delete('activity'), isTrue);
    expect(repository.operation, 'delete');
  });
}
