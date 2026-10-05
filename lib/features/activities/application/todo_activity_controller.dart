import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/firebase/todo_activity_service.dart';
import '../../../data/repositories/todo_activity_repository.dart';
import '../../../domain/entities/todo_activity.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';

final todoActivityServiceProvider = Provider((ref) => TodoActivityService(
      ref.watch(firestoreProvider),
      requireUserId(ref),
    ));
final todoActivityRepositoryProvider = Provider<TodoActivityRepository>((ref) =>
    FirebaseTodoActivityRepository(ref.watch(todoActivityServiceProvider)));
final todoActivitiesProvider = StreamProvider<List<TodoActivity>>(
    (ref) => ref.watch(todoActivityRepositoryProvider).watchActivities());
final todoActivityControllerProvider =
    StateNotifierProvider<TodoActivityController, AsyncValue<void>>((ref) =>
        TodoActivityController(ref.watch(todoActivityRepositoryProvider)));

class TodoActivityController extends StateNotifier<AsyncValue<void>> {
  TodoActivityController(this._repository) : super(const AsyncData(null));

  final TodoActivityRepository _repository;

  Future<String?> save(TodoActivity activity) async {
    state = const AsyncLoading();
    try {
      final validation = activity.validate();
      if (validation != null) throw AppException(validation);
      final normalized = activity.copyWith(
        title: activity.title.trim(),
        description: activity.description?.trim(),
        day: DateTime(activity.day.year, activity.day.month, activity.day.day),
      );
      final id = normalized.id.isEmpty
          ? await _repository.createActivity(normalized)
          : normalized.id;
      if (normalized.id.isNotEmpty) {
        await _repository.updateActivity(normalized);
      }
      state = const AsyncData(null);
      return id;
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    } catch (_, stackTrace) {
      state = AsyncError(
          const AppException('No pudimos guardar la actividad.'), stackTrace);
      return null;
    }
  }

  Future<bool> setCompleted(TodoActivity activity, bool completed) async {
    return await save(activity.copyWith(
          isCompleted: completed,
          updatedAt: DateTime.now(),
        )) !=
        null;
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteActivity(id);
      state = const AsyncData(null);
      return true;
    } catch (_, stackTrace) {
      state = AsyncError(
          const AppException('No pudimos eliminar la actividad.'), stackTrace);
      return false;
    }
  }
}
