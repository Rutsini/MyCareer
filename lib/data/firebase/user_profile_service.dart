import 'package:cloud_firestore/cloud_firestore.dart';

import '../mappers/user_profile_repair_mapper.dart';

class UserProfileService {
  UserProfileService(this._firestore, this.userId);
  final FirebaseFirestore _firestore;
  final String userId;
  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('users').doc(userId);
  Stream<DocumentSnapshot<Map<String, dynamic>>> watch() => _doc.snapshots();

  Future<void> ensureProfile({
    required String email,
    String? displayName,
  }) =>
      _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(_doc);
        final data = snapshot.data();
        if (!snapshot.exists || data == null) {
          transaction.set(_doc, {
            ...UserProfileRepairMapper.initialData(
              email: email,
              displayName: displayName,
            ),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        }

        final patch = UserProfileRepairMapper.repairPatch(
          data,
          email: email,
          displayName: displayName,
        );
        if (data['createdAt'] is! Timestamp) {
          patch['createdAt'] = FieldValue.serverTimestamp();
        }
        if (patch.isEmpty) return;
        transaction.update(_doc, {
          ...patch,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

  Future<void> updateCareer(Map<String, dynamic> career) => _doc
      .update({'career': career, 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) =>
      _doc.update({
        'settings.notifications': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
