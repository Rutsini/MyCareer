import '../entities/evaluation.dart';
import '../entities/notification_settings.dart';
import '../models/scheduled_reminder.dart';
import 'notification_id_generator.dart';
import 'reminder_trigger_calculator.dart';

class ReminderPlanner {
  const ReminderPlanner({
    this.triggerCalculator = const ReminderTriggerCalculator(),
  });

  final ReminderTriggerCalculator triggerCalculator;

  List<ScheduledReminder> plan({
    required Evaluation evaluation,
    required NotificationSettings settings,
    required DateTime now,
  }) {
    if (!settings.enabled || evaluation.status != EvaluationStatus.pending) {
      return const [];
    }
    final result = <ScheduledReminder>[];
    final ids = <int>{};
    final offsets = <int>{};
    for (final reminder in evaluation.reminders) {
      if (!reminder.enabled || reminder.validate() != null) continue;
      if (!offsets.add(reminder.offsetMinutes)) continue;
      final trigger = triggerCalculator.calculate(
        evaluation: evaluation,
        reminder: reminder,
        settings: settings,
      );
      if (trigger == null || !trigger.isAfter(now)) continue;
      final id = NotificationIdGenerator.generate(evaluation.id, reminder.id);
      if (!ids.add(id)) continue;
      result.add(ScheduledReminder(
        notificationId: id,
        reminderId: reminder.id,
        evaluationId: evaluation.id,
        subjectId: evaluation.subjectId,
        triggerAt: trigger,
      ));
    }
    result.sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
    return result;
  }
}
