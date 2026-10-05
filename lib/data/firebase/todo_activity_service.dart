import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/todo_activity.dart';
import '../mappers/todo_activity_mapper.dart';

class TodoActivityService {
  TodoActivityService(this._firestore, this.userId);

  final FirebaseFirestore _firestore;
  final String userId;

  CollectionReference<Map<String, dynamic>> get _activities =>
      _firestore.collection('users').doc(userId).collection('activities');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActivities() =>
      _activities.snapshots();

  Future<String> createActivity(TodoActivity activity) async {
    final document =
        activity.id.isEmpty ? _activities.doc() : _activities.doc(activity.id);
    await document.set(TodoActivityMapper.toMap(activity, creating: true));
    return document.id;
  }

  Future<void> updateActivity(TodoActivity activity) => _activities
      .doc(activity.id)
      .update(TodoActivityMapper.toMap(activity, creating: false));

  Future<void> deleteActivity(String id) => _activities.doc(id).delete();
}
