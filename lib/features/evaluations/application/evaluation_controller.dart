import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/firebase/evaluation_service.dart';
import '../../../data/repositories/evaluation_repository.dart';
import '../../../domain/entities/evaluation.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';

final evaluationServiceProvider = Provider((ref) =>
    EvaluationService(ref.watch(firestoreProvider), requireUserId(ref)));
final evaluationRepositoryProvider = Provider<EvaluationRepository>((ref) =>
    FirebaseEvaluationRepository(ref.watch(evaluationServiceProvider)));
final evaluationsProvider = StreamProvider<List<Evaluation>>(
    (ref) => ref.watch(evaluationRepositoryProvider).watchEvaluations());
final evaluationProvider = StreamProvider.family<Evaluation?, String>(
    (ref, id) => ref.watch(evaluationRepositoryProvider).watchEvaluation(id));
final subjectEvaluationsProvider =
    Provider.family<AsyncValue<List<Evaluation>>, String>((ref, subjectId) =>
        ref.watch(evaluationsProvider).whenData((items) => items
            .where((evaluation) => evaluation.subjectId == subjectId)
            .toList()));
final evaluationControllerProvider =
    StateNotifierProvider<EvaluationController, AsyncValue<void>>(
        (ref) => EvaluationController(ref.watch(evaluationRepositoryProvider)));

class EvaluationController extends StateNotifier<AsyncValue<void>> {
  EvaluationController(this._repository) : super(const AsyncData(null));
  final EvaluationRepository _repository;

  Future<String?> save(Evaluation evaluation) async {
    state = const AsyncLoading();
    try {
      final validation = evaluation.validate();
      if (validation != null) throw AppException(validation);
      final id = evaluation.id.isEmpty
          ? await _repository.createEvaluation(evaluation)
          : evaluation.id;
      if (evaluation.id.isNotEmpty) {
        await _repository.updateEvaluation(evaluation);
      }
      state = const AsyncData(null);
      return id;
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    } catch (_, stackTrace) {
      state = AsyncError(
          const AppException('No pudimos guardar la evaluación.'), stackTrace);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteEvaluation(id);
      state = const AsyncData(null);
      return true;
    } catch (_, stackTrace) {
      state = AsyncError(
          const AppException('No pudimos eliminar la evaluación.'), stackTrace);
      return false;
    }
  }
}
