// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../domain/entities/academic_rule.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/services/academic_engine.dart';
import '../../evaluations/application/evaluation_controller.dart';
import 'subject_controller.dart';

final academicEngineProvider = Provider((_) => const AcademicEngine());
final subjectAcademicResultProvider =
    Provider.family<AsyncValue<AcademicSubjectResult>, String>((ref, id) {
  final subject = ref.watch(subjectProvider(id));
  final evaluations = ref.watch(subjectEvaluationsProvider(id));
  return subject.when(
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
      data: (value) {
        if (value == null)
          return AsyncError(
              const AppException('La materia no existe.'), StackTrace.current);
        return evaluations.when(
            loading: () => const AsyncLoading(),
            error: AsyncError.new,
            data: (items) => AsyncData(ref
                .watch(academicEngineProvider)
                .evaluate(subject: value, evaluations: items)));
      });
});

final academicRuleControllerProvider =
    StateNotifierProvider<AcademicRuleController, AsyncValue<void>>(
        (ref) => AcademicRuleController(ref.watch(subjectRepositoryProvider)));

class AcademicRuleController extends StateNotifier<AsyncValue<void>> {
  AcademicRuleController(this.repository) : super(const AsyncData(null));
  final SubjectRepository repository;
  Future<bool> saveRules(Subject subject,
      {List<AcademicRule>? promotion, List<AcademicRule>? regularity}) async {
    state = const AsyncLoading();
    try {
      final updated = subject.copyWith(
          promotionRules: promotion,
          regularityRules: regularity,
          updatedAt: DateTime.now());
      for (final rule in [
        ...updated.promotionRules,
        ...updated.regularityRules
      ]) {
        final error = rule.validate(updated);
        if (error != null) throw AppException(error);
      }
      await repository.updateSubject(updated);
      state = const AsyncData(null);
      return true;
    } on AppException catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    } catch (_, stack) {
      state = AsyncError(
          const AppException('No pudimos guardar las condiciones.'), stack);
      return false;
    }
  }
}
