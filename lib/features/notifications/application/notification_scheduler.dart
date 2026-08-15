import '../../../core/notifications/local_notification_gateway.dart';
import '../../../core/notifications/notification_payload.dart';
import '../../../domain/entities/evaluation.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/services/notification_id_generator.dart';
import '../../../domain/services/reminder_message_builder.dart';
import '../../../domain/services/reminder_planner.dart';

class NotificationScheduler {
  NotificationScheduler(this.gateway, {this.planner = const ReminderPlanner()});

  final LocalNotificationGateway gateway;
  final ReminderPlanner planner;

  Future<void> synchronizeAll({
    required List<Evaluation> evaluations,
    required List<Subject> subjects,
    required NotificationSettings settings,
    DateTime? now,
  }) async {
    final permission = await gateway.permissionStatus();
    final pending = await gateway.pendingIds();
    final academicPending = pending.where(NotificationIdGenerator.isAcademic);
    for (final id in academicPending) {
      await gateway.cancel(id);
    }
    if (!settings.enabled ||
        permission != NotificationPermissionState.granted) {
      return;
    }

    final subjectById = {for (final subject in subjects) subject.id: subject};
    final current = now ?? DateTime.now();
    for (final evaluation in evaluations) {
      final subject = subjectById[evaluation.subjectId];
      if (subject == null) continue;
      final plans = planner.plan(
        evaluation: evaluation,
        settings: settings,
        now: current,
      );
      for (final plan in plans) {
        final message = ReminderMessageBuilder.build(
          evaluation: evaluation,
          subjectName: subject.name,
          triggerAt: plan.triggerAt,
        );
        await gateway.schedule(
          id: plan.notificationId,
          triggerAt: plan.triggerAt,
          title: message.title,
          body: message.body,
          payload: NotificationPayload(
            evaluationId: evaluation.id,
            subjectId: evaluation.subjectId,
          ).encode(),
        );
      }
    }
  }
}
