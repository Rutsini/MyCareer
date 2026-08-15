import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  UserProfileService(this._firestore, this.userId);
  final FirebaseFirestore _firestore;
  final String userId;
  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('users').doc(userId);
  Stream<DocumentSnapshot<Map<String, dynamic>>> watch() => _doc.snapshots();
  Future<void> updateCareer(Map<String, dynamic> career) => _doc
      .update({'career': career, 'updatedAt': FieldValue.serverTimestamp()});
}
