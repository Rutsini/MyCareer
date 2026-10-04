import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/evaluation.dart';
import 'atomic_delete_guard.dart';
import '../mappers/evaluation_mapper.dart';

class EvaluationService {
  EvaluationService(this._firestore, this.userId);

  final FirebaseFirestore _firestore;
  final String userId;

  CollectionReference<Map<String, dynamic>> get _evaluations =>
      _firestore.collection('users').doc(userId).collection('evaluations');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEvaluations() =>
      _evaluations.snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchEvaluation(String id) =>
      _evaluations.doc(id).snapshots();

  Future<String> createEvaluation(Evaluation evaluation) async {
    final document = evaluation.id.isEmpty
        ? _evaluations.doc()
        : _evaluations.doc(evaluation.id);
    await document.set(EvaluationMapper.toMap(evaluation, creating: true));
    return document.id;
  }

  Future<void> updateEvaluation(Evaluation evaluation) => _evaluations
      .doc(evaluation.id)
      .update(EvaluationMapper.toMap(evaluation, creating: false));

  Future<void> deleteEvaluation(String id) async {
    final linked = await _evaluations
        .where('recoveryOfEvaluationId', isEqualTo: id)
        .limit(maxFirestoreBatchWrites)
        .get();
    ensureAtomicDeletionCapacity(linked.docs.length);

    final batch = _firestore.batch();
    for (final recovery in linked.docs) {
      batch.delete(recovery.reference);
    }
    batch.delete(_evaluations.doc(id));
    await batch.commit();
  }
}
