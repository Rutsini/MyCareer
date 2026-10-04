import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subject.dart';
import 'atomic_delete_guard.dart';
import '../mappers/subject_mapper.dart';

class SubjectService {
  SubjectService(this._firestore, this.userId);
  final FirebaseFirestore _firestore;
  final String userId;
  CollectionReference<Map<String, dynamic>> get _subjects =>
      _firestore.collection('users').doc(userId).collection('subjects');
  CollectionReference<Map<String, dynamic>> get _evaluations =>
      _firestore.collection('users').doc(userId).collection('evaluations');
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSubjects() =>
      _subjects.snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSubject(String id) =>
      _subjects.doc(id).snapshots();
  Future<String> createSubject(Subject subject) async {
    final doc =
        subject.id.isEmpty ? _subjects.doc() : _subjects.doc(subject.id);
    await doc.set(SubjectMapper.toMap(subject, creating: true));
    return doc.id;
  }

  Future<void> updateSubject(Subject subject) => _subjects
      .doc(subject.id)
      .update(SubjectMapper.toMap(subject, creating: false));

  Future<void> deleteSubject(String id) async {
    final evaluations = await _evaluations
        .where('subjectId', isEqualTo: id)
        .limit(maxFirestoreBatchWrites)
        .get();
    ensureAtomicDeletionCapacity(evaluations.docs.length);

    final batch = _firestore.batch();
    for (final evaluation in evaluations.docs) {
      batch.delete(evaluation.reference);
    }
    batch.delete(_subjects.doc(id));
    await batch.commit();
  }
}
