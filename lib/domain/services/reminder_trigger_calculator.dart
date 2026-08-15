import '../entities/evaluation.dart';
import '../entities/evaluation_reminder.dart';
import '../entities/notification_settings.dart';

class ReminderTriggerCalculator {
  const ReminderTriggerCalculator();

  DateTime? calculate({
    required Evaluation evaluation,
    required EvaluationReminder reminder,
    required NotificationSettings settings,
  }) {
    if (reminder.offsetMinutes < 0) return null;
    if (!evaluation.allDay) {
      return evaluation.date
          .subtract(Duration(minutes: reminder.offsetMinutes));
    }
    if (reminder.offsetMinutes % 1440 != 0) return null;
    final day = DateTime(
      evaluation.date.year,
      evaluation.date.month,
      evaluation.date.day,
      settings.allDayReminderHour,
      settings.allDayReminderMinute,
    );
    return day.subtract(Duration(days: reminder.offsetMinutes ~/ 1440));
  }
}
