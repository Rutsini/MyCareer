import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/mappers/user_profile_mapper.dart';
import 'package:my_career/data/mappers/user_profile_repair_mapper.dart';

void main() {
  test('perfil nuevo contiene todos los defaults requeridos', () {
    final data = UserProfileRepairMapper.initialData(
      email: ' user@example.com ',
      displayName: ' Ada ',
    );

    expect(data['email'], 'user@example.com');
    expect(data['displayName'], 'Ada');
    expect(data['career'], {
      'name': null,
      'currentYear': null,
      'totalSubjects': null,
      'requiredElectivePoints': null,
    });
    expect(data['settings'], {
      'theme': 'system',
      'defaultGradeMin': 0,
      'defaultGradeMax': 10,
      'notifications': {
        'enabled': false,
        'defaultReminderOffsetsMinutes': [1440],
        'allDayReminderHour': 9,
        'allDayReminderMinute': 0,
      },
    });
  });

  test('reparación conserva la configuración académica existente', () {
    final patch = UserProfileRepairMapper.repairPatch({
      'displayName': 'Ada',
      'email': 'old@example.com',
      'career': {
        'name': 'Sistemas',
        'currentYear': 4,
        'totalSubjects': 42,
        'requiredElectivePoints': 20,
      },
      'settings': {
        'theme': 'dark',
        'defaultGradeMin': 1,
        'defaultGradeMax': 100,
        'notifications': {
          'enabled': true,
          'defaultReminderOffsetsMinutes': [0, 1440],
          'allDayReminderHour': 8,
          'allDayReminderMinute': 30,
        },
      },
      'schemaVersion': 1,
    }, email: 'new@example.com', displayName: 'Ada');

    expect(patch, {'email': 'new@example.com'});
  });

  test('reparación completa campos faltantes y sanea valores corruptos', () {
    final patch = UserProfileRepairMapper.repairPatch({
      'email': 4,
      'career': 'invalid',
      'settings': {
        'theme': '',
        'defaultGradeMin': 'zero',
        'notifications': {
          'enabled': 'yes',
          'defaultReminderOffsetsMinutes': [1440, -1, 'bad', 0],
          'allDayReminderHour': 27,
        },
      },
    }, email: 'user@example.com');

    expect(patch['email'], 'user@example.com');
    expect(patch['career'], isA<Map<String, dynamic>>());
    expect(patch['settings.theme'], 'system');
    expect(patch['settings.defaultGradeMin'], 0);
    expect(patch['settings.defaultGradeMax'], 10);
    expect(patch['settings.notifications.enabled'], isFalse);
    expect(patch['settings.notifications.defaultReminderOffsetsMinutes'],
        [0, 1440]);
    expect(patch['settings.notifications.allDayReminderHour'], 9);
    expect(patch['settings.notifications.allDayReminderMinute'], 0);
    expect(patch['schemaVersion'], 1);
  });

  test('mapper tolera estructuras corruptas mientras se reparan', () {
    final profile = UserProfileMapper.fromMap('user-id', {
      'email': 42,
      'displayName': false,
      'career': {
        'name': 12,
        'currentYear': 'four',
        'totalSubjects': false,
        'requiredElectivePoints': 'twenty',
      },
      'settings': {
        'theme': false,
        'notifications': {'enabled': 'yes'},
      },
    });

    expect(profile.id, 'user-id');
    expect(profile.email, isEmpty);
    expect(profile.displayName, isNull);
    expect(profile.career.name, isNull);
    expect(profile.career.currentYear, isNull);
    expect(profile.career.totalSubjects, isNull);
    expect(profile.career.requiredElectivePoints, isNull);
    expect(profile.settings.theme, 'system');
    expect(profile.settings.notifications.enabled, isFalse);
    expect(
        profile.settings.notifications.defaultReminderOffsetsMinutes, [1440]);
  });
}
