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
      enabled: notifications['enabled'] as bool? ?? false,
      defaultReminderOffsetsMinutes: offsets,
      allDayReminderHour: hour != null && hour >= 0 && hour <= 23 ? hour : 9,
      allDayReminderMinute:
          minute != null && minute >= 0 && minute <= 59 ? minute : 0,
    );
  }

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
