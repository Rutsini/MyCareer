import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';
import 'firestore_mapper_utils.dart';

abstract final class UserProfileMapper {
  static UserProfile fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final career = data['career'] as Map<String, dynamic>? ?? const {};
    final settings = data['settings'] as Map<String, dynamic>? ?? const {};
    return UserProfile(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      career: CareerSettings(
        name: career['name'] as String?,
        currentYear: (career['currentYear'] as num?)?.toInt(),
        totalSubjects: (career['totalSubjects'] as num?)?.toInt(),
        requiredElectivePoints:
            (career['requiredElectivePoints'] as num?)?.toDouble(),
      ),
      settings: UserSettings(
        theme: settings['theme'] as String? ?? 'system',
        defaultGradeMin: numberToDouble(settings['defaultGradeMin']),
        defaultGradeMax: numberToDouble(settings['defaultGradeMax'], 10),
      ),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
