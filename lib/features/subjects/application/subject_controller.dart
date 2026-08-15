import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/firebase/subject_service.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../domain/entities/subject.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';

final subjectServiceProvider = Provider(
    (ref) => SubjectService(ref.watch(firestoreProvider), requireUserId(ref)));
final subjectRepositoryProvider = Provider<SubjectRepository>(
    (ref) => FirebaseSubjectRepository(ref.watch(subjectServiceProvider)));
final subjectsProvider = StreamProvider<List<Subject>>(
    (ref) => ref.watch(subjectRepositoryProvider).watchSubjects());
final subjectProvider = StreamProvider.family<Subject?, String>(
    (ref, id) => ref.watch(subjectRepositoryProvider).watchSubject(id));
final subjectControllerProvider =
    StateNotifierProvider<SubjectController, AsyncValue<void>>(
        (ref) => SubjectController(ref.watch(subjectRepositoryProvider)));

class SubjectController extends StateNotifier<AsyncValue<void>> {
  SubjectController(this._repository) : super(const AsyncData(null));
  final SubjectRepository _repository;
  Future<String?> save(Subject subject) async {
    state = const AsyncLoading();
    try {
      final validation = subject.validate();
      if (validation != null) throw AppException(validation);
      final id = subject.id.isEmpty
          ? await _repository.createSubject(subject)
          : subject.id;
      if (subject.id.isNotEmpty) await _repository.updateSubject(subject);
      state = const AsyncData(null);
      return id;
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      return null;
    } catch (e, st) {
      state =
          AsyncError(const AppException('No pudimos guardar la materia.'), st);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteSubject(id);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state =
          AsyncError(const AppException('No pudimos eliminar la materia.'), st);
      return false;
    }
  }
}
