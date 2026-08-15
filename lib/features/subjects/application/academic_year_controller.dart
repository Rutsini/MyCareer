// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/firebase/academic_year_service.dart';
import '../../../data/repositories/academic_year_repository.dart';
import '../../../domain/entities/academic_year.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';

final academicYearServiceProvider = Provider((ref) =>
    AcademicYearService(ref.watch(firestoreProvider), requireUserId(ref)));
final academicYearRepositoryProvider = Provider<AcademicYearRepository>((ref) =>
    FirebaseAcademicYearRepository(ref.watch(academicYearServiceProvider)));
final academicYearsProvider = StreamProvider<List<AcademicYear>>(
    (ref) => ref.watch(academicYearRepositoryProvider).watchYears());
final selectedYearIdProvider = StateProvider<String?>((ref) => null);
final academicYearControllerProvider =
    StateNotifierProvider<AcademicYearController, AsyncValue<void>>((ref) =>
        AcademicYearController(ref.watch(academicYearRepositoryProvider)));

class AcademicYearController extends StateNotifier<AsyncValue<void>> {
  AcademicYearController(this._repository) : super(const AsyncData(null));
  final AcademicYearRepository _repository;
  Future<bool> create(int year, {bool current = false}) =>
      _run(() => _repository.createYear(year, isCurrent: current));
  Future<bool> setCurrent(String id) => _run(() => _repository.setCurrent(id));
  Future<bool?> delete(String id) async {
    bool? result;
    final ok = await _run(() async {
      result = await _repository.deleteIfEmpty(id);
      if (result == false)
        throw const AppException(
            'No podés eliminar un año que tiene materias.');
    });
    return ok ? result : null;
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return true;
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    } catch (e, st) {
      state = AsyncError(
          const AppException('No pudimos actualizar los años académicos.'), st);
      return false;
    }
  }
}
