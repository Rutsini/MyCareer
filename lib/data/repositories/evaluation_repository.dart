import '../../domain/entities/evaluation.dart';
import '../firebase/evaluation_service.dart';
import '../mappers/evaluation_mapper.dart';

abstract interface class EvaluationRepository {
  Stream<List<Evaluation>> watchEvaluations();
  Stream<Evaluation?> watchEvaluation(String id);
  Future<String> createEvaluation(Evaluation evaluation);
  Future<void> updateEvaluation(Evaluation evaluation);
  Future<void> deleteEvaluation(String id);
}

class FirebaseEvaluationRepository implements EvaluationRepository {
  FirebaseEvaluationRepository(this._service);
  final EvaluationService _service;

  @override
  Stream<List<Evaluation>> watchEvaluations() =>
      _service.watchEvaluations().map((snapshot) {
        final evaluations =
            snapshot.docs.map(EvaluationMapper.fromDocument).toList();
        evaluations.sort((a, b) => a.date.compareTo(b.date));
        return evaluations;
      });

  @override
  Stream<Evaluation?> watchEvaluation(String id) =>
      _service.watchEvaluation(id).map((document) =>
          document.exists ? EvaluationMapper.fromDocument(document) : null);

  @override
  Future<String> createEvaluation(Evaluation evaluation) =>
      _service.createEvaluation(evaluation);
  @override
  Future<void> updateEvaluation(Evaluation evaluation) =>
      _service.updateEvaluation(evaluation);
  @override
  Future<void> deleteEvaluation(String id) => _service.deleteEvaluation(id);
}
