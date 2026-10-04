import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/notification_settings.dart';
import 'firestore_mapper_utils.dart';

abstract final class UserProfileMapper {
  static NotificationSettings notificationSettingsFromMap(Object? value) {
    final notifications = value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final offsets = notifications['defaultReminderOffsetsMinutes'] is List
        ? (notifications['defaultReminderOffsetsMinutes'] as List)
            .whereType<num>()
            .map((value) => value.toInt())
            .where((value) => value >= 0)
            .toSet()
            .toList()
        : const <int>[1440];
    final hour = (notifications['allDayReminderHour'] as num?)?.toInt();
    final minute = (notifications['allDayReminderMinute'] as num?)?.toInt();
    return NotificationSettings(
      enabled: notifications['enabled'] is bool
          ? notifications['enabled'] as bool
          : false,
      defaultReminderOffsetsMinutes: offsets,
      allDayReminderHour: hour != null && hour >= 0 && hour <= 23 ? hour : 9,
      allDayReminderMinute:
          minute != null && minute >= 0 && minute <= 59 ? minute : 0,
    );
  }

  static UserProfile fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return fromMap(doc.id, data);
  }

  static UserProfile fromMap(String id, Map<String, dynamic> data) {
    final career = data['career'] is Map
        ? Map<String, dynamic>.from(data['career'] as Map)
        : const <String, dynamic>{};
    final settings = data['settings'] is Map
        ? Map<String, dynamic>.from(data['settings'] as Map)
        : const <String, dynamic>{};
    return UserProfile(
      id: id,
      email: data['email'] is String ? data['email'] as String : '',
      displayName:
          data['displayName'] is String ? data['displayName'] as String : null,
      career: CareerSettings(
        name: career['name'] is String ? career['name'] as String : null,
        currentYear: career['currentYear'] is num
            ? (career['currentYear'] as num).toInt()
            : null,
        totalSubjects: career['totalSubjects'] is num
            ? (career['totalSubjects'] as num).toInt()
            : null,
        requiredElectivePoints: career['requiredElectivePoints'] is num
            ? (career['requiredElectivePoints'] as num).toDouble()
            : null,
      ),
      settings: UserSettings(
        theme: settings['theme'] is String
            ? settings['theme'] as String
            : 'system',
        defaultGradeMin: numberToDouble(settings['defaultGradeMin']),
        defaultGradeMax: numberToDouble(settings['defaultGradeMax'], 10),
        notifications: notificationSettingsFromMap(settings['notifications']),
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
