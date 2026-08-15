import 'notification_settings.dart';

class CareerSettings {
  const CareerSettings(
      {this.name,
      this.currentYear,
      this.totalSubjects,
      this.requiredElectivePoints});
  final String? name;
  final int? currentYear;
  final int? totalSubjects;
  final double? requiredElectivePoints;
}

class UserSettings {
  const UserSettings({
    this.theme = 'system',
    this.defaultGradeMin = 0,
    this.defaultGradeMax = 10,
    this.notifications = const NotificationSettings(),
  });
  final String theme;
  final double defaultGradeMin;
  final double defaultGradeMax;
  final NotificationSettings notifications;
}

class UserProfile {
  const UserProfile(
      {required this.id,
      required this.email,
      this.displayName,
      this.career = const CareerSettings(),
      this.settings = const UserSettings(),
      this.createdAt,
      this.updatedAt});
  final String id;
  final String email;
  final String? displayName;
  final CareerSettings career;
  final UserSettings settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
