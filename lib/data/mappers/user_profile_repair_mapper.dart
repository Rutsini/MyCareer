import '../../core/constants/app_constants.dart';

abstract final class UserProfileRepairMapper {
  static const _careerDefaults = <String, dynamic>{
    'name': null,
    'currentYear': null,
    'totalSubjects': null,
    'requiredElectivePoints': null,
  };

  static const _notificationDefaults = <String, dynamic>{
    'enabled': false,
    'defaultReminderOffsetsMinutes': <int>[1440],
    'allDayReminderHour': 9,
    'allDayReminderMinute': 0,
  };

  static const _settingsDefaults = <String, dynamic>{
    'theme': 'system',
    'defaultGradeMin': 0,
    'defaultGradeMax': 10,
    'notifications': _notificationDefaults,
  };

  static Map<String, dynamic> initialData({
    required String email,
    String? displayName,
  }) =>
      {
        'displayName': _normalizedName(displayName),
        'email': email.trim(),
        'career': Map<String, dynamic>.from(_careerDefaults),
        'settings': {
          ..._settingsDefaults,
          'notifications': Map<String, dynamic>.from(_notificationDefaults),
        },
        'schemaVersion': AppConstants.schemaVersion,
      };

  static Map<String, dynamic> repairPatch(
    Map<String, dynamic> data, {
    required String email,
    String? displayName,
  }) {
    final patch = <String, dynamic>{};
    final normalizedEmail = email.trim();
    final normalizedName = _normalizedName(displayName);

    if (normalizedEmail.isNotEmpty && data['email'] != normalizedEmail) {
      patch['email'] = normalizedEmail;
    } else if (data['email'] is! String) {
      patch['email'] = normalizedEmail;
    }

    if (normalizedName != null && data['displayName'] != normalizedName) {
      patch['displayName'] = normalizedName;
    } else if (!data.containsKey('displayName') ||
        data['displayName'] is! String?) {
      patch['displayName'] = normalizedName;
    }

    _repairCareer(data['career'], patch);
    _repairSettings(data['settings'], patch);

    final schemaVersion = data['schemaVersion'];
    if (schemaVersion is! num ||
        schemaVersion.toInt() < AppConstants.schemaVersion) {
      patch['schemaVersion'] = AppConstants.schemaVersion;
    }
    return patch;
  }

  static void _repairCareer(Object? value, Map<String, dynamic> patch) {
    if (value is! Map) {
      patch['career'] = Map<String, dynamic>.from(_careerDefaults);
      return;
    }
    final career = Map<String, dynamic>.from(value);
    _repairNullableField(
      career,
      patch,
      field: 'name',
      path: 'career.name',
      isValid: (value) => value is String,
    );
    for (final field in const ['currentYear', 'totalSubjects']) {
      _repairNullableField(
        career,
        patch,
        field: field,
        path: 'career.$field',
        isValid: (value) => value is num,
      );
    }
    _repairNullableField(
      career,
      patch,
      field: 'requiredElectivePoints',
      path: 'career.requiredElectivePoints',
      isValid: (value) => value is num,
    );
  }

  static void _repairSettings(Object? value, Map<String, dynamic> patch) {
    if (value is! Map) {
      patch['settings'] = {
        ..._settingsDefaults,
        'notifications': Map<String, dynamic>.from(_notificationDefaults),
      };
      return;
    }
    final settings = Map<String, dynamic>.from(value);
    if (settings['theme'] is! String ||
        (settings['theme'] as String).trim().isEmpty) {
      patch['settings.theme'] = 'system';
    }
    if (settings['defaultGradeMin'] is! num) {
      patch['settings.defaultGradeMin'] = 0;
    }
    if (settings['defaultGradeMax'] is! num) {
      patch['settings.defaultGradeMax'] = 10;
    }
    _repairNotifications(settings['notifications'], patch);
  }

  static void _repairNotifications(Object? value, Map<String, dynamic> patch) {
    if (value is! Map) {
      patch['settings.notifications'] =
          Map<String, dynamic>.from(_notificationDefaults);
      return;
    }
    final notifications = Map<String, dynamic>.from(value);
    if (notifications['enabled'] is! bool) {
      patch['settings.notifications.enabled'] = false;
    }

    final rawOffsets = notifications['defaultReminderOffsetsMinutes'];
    if (rawOffsets is! List) {
      patch['settings.notifications.defaultReminderOffsetsMinutes'] =
          const <int>[1440];
    } else {
      final offsets = rawOffsets
          .whereType<num>()
          .map((value) => value.toInt())
          .where((value) => value >= 0)
          .toSet()
          .toList()
        ..sort();
      if (offsets.length != rawOffsets.length ||
          !_sameValues(offsets, rawOffsets)) {
        patch['settings.notifications.defaultReminderOffsetsMinutes'] = offsets;
      }
    }

    final hour = notifications['allDayReminderHour'];
    if (hour is! num || hour.toInt() < 0 || hour.toInt() > 23) {
      patch['settings.notifications.allDayReminderHour'] = 9;
    }
    final minute = notifications['allDayReminderMinute'];
    if (minute is! num || minute.toInt() < 0 || minute.toInt() > 59) {
      patch['settings.notifications.allDayReminderMinute'] = 0;
    }
  }

  static void _repairNullableField(
    Map<String, dynamic> source,
    Map<String, dynamic> patch, {
    required String field,
    required String path,
    required bool Function(Object value) isValid,
  }) {
    if (!source.containsKey(field) ||
        (source[field] != null && !isValid(source[field] as Object))) {
      patch[path] = null;
    }
  }

  static bool _sameValues(List<int> normalized, List<dynamic> raw) {
    if (normalized.length != raw.length) return false;
    for (var index = 0; index < normalized.length; index++) {
      final value = raw[index];
      if (value is! num || value.toInt() != normalized[index]) return false;
    }
    return true;
  }

  static String? _normalizedName(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
