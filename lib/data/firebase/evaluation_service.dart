import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/evaluation.dart';
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
    final linked =
        await _evaluations.where('recoveryOfEvaluationId', isEqualTo: id).get();
    await _deleteDocuments(
        [...linked.docs.map((d) => d.reference), _evaluations.doc(id)]);
  }

  Future<void> deleteEvaluationsBySubject(String subjectId) async {
    while (true) {
      final snapshot = await _evaluations
          .where('subjectId', isEqualTo: subjectId)
          .limit(450)
          .get();
      if (snapshot.docs.isEmpty) return;
      await _deleteDocuments(snapshot.docs.map((d) => d.reference).toList());
      if (snapshot.docs.length < 450) return;
    }
  }

  Future<void> _deleteDocuments(
      List<DocumentReference<Map<String, dynamic>>> documents) async {
    for (var offset = 0; offset < documents.length; offset += 450) {
      final batch = _firestore.batch();
      for (final document in documents.skip(offset).take(450)) {
        batch.delete(document);
      }
      await batch.commit();
    }
  }
}
