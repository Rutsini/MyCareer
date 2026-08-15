import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/academic_year_exception.dart';

void ensureAcademicYearDoesNotExist({
  required bool exists,
  required int year,
}) {
  if (exists) {
    throw AcademicYearAlreadyExistsException(year);
  }
}

class AcademicYearService {
  AcademicYearService(this._firestore, this.userId);
  final FirebaseFirestore _firestore;
  final String userId;
  CollectionReference<Map<String, dynamic>> get _years =>
      _firestore.collection('users').doc(userId).collection('academicYears');
  CollectionReference<Map<String, dynamic>> get _subjects =>
      _firestore.collection('users').doc(userId).collection('subjects');
  Stream<QuerySnapshot<Map<String, dynamic>>> watchYears() =>
      _years.orderBy('year', descending: true).snapshots();
  Future<void> createYear(int year, {bool isCurrent = false}) async {
    final yearReference = _years.doc('$year');
    final yearDocument = await yearReference.get();
    ensureAcademicYearDoesNotExist(exists: yearDocument.exists, year: year);

    final batch = _firestore.batch();
    if (isCurrent) {
      final existing = await _years.where('isCurrent', isEqualTo: true).get();
      for (final doc in existing.docs) {
        batch.update(doc.reference,
            {'isCurrent': false, 'updatedAt': FieldValue.serverTimestamp()});
      }
    }
    batch.set(yearReference, {
      'year': year,
      'isCurrent': isCurrent,
      'startDate': null,
      'endDate': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp()
    });
    await batch.commit();
  }

  Future<void> setCurrent(String id) async {
    final existing = await _years.get();
    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {
        'isCurrent': doc.id == id,
        'updatedAt': FieldValue.serverTimestamp()
      });
    }
    await batch.commit();
  }

  Future<bool> deleteIfEmpty(String id) async {
    final used =
        await _subjects.where('academicYearId', isEqualTo: id).limit(1).get();
    if (used.docs.isNotEmpty) return false;
    await _years.doc(id).delete();
    return true;
  }
}
