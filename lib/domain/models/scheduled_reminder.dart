class ScheduledReminder {
  const ScheduledReminder({
    required this.notificationId,
    required this.reminderId,
    required this.evaluationId,
    required this.subjectId,
    required this.triggerAt,
  });

  final int notificationId;
  final String reminderId;
  final String evaluationId;
  final String subjectId;
  final DateTime triggerAt;
}
