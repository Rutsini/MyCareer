import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/mappers/evaluation_mapper.dart';
import 'package:my_career/data/mappers/user_profile_mapper.dart';

void main() {
  test('perfil antiguo recibe defaults backward-compatible', () {
    final settings = UserProfileMapper.notificationSettingsFromMap(null);
    expect(settings.enabled, isFalse);
    expect(settings.defaultReminderOffsetsMinutes, [1440]);
    expect(settings.allDayReminderHour, 9);
    expect(settings.allDayReminderMinute, 0);
  });

  test('settings corruptos aplican fallback y filtran offsets', () {
    final settings = UserProfileMapper.notificationSettingsFromMap({
      'enabled': true,
      'defaultReminderOffsetsMinutes': [-1, 0, 1440, 'bad'],
      'allDayReminderHour': 30,
      'allDayReminderMinute': -2,
    });
    expect(settings.enabled, isTrue);
    expect(settings.defaultReminderOffsetsMinutes, [0, 1440]);
    expect(settings.allDayReminderHour, 9);
    expect(settings.allDayReminderMinute, 0);
  });

  test('schema v1 sin reminders se interpreta como lista vacía', () {
    expect(EvaluationMapper.remindersFromValue(null), isEmpty);
  });

  test('schema v2 ignora reminders corruptos sin romper la lista', () {
    final reminders = EvaluationMapper.remindersFromValue([
      {'id': 'valid', 'offsetMinutes': 1440, 'enabled': true},
      {'id': '', 'offsetMinutes': 10},
      {'id': 'negative', 'offsetMinutes': -1},
      'bad',
    ]);
    expect(reminders, hasLength(1));
    expect(reminders.single.id, 'valid');
  });
}
