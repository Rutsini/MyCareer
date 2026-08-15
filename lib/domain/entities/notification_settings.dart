class NotificationSettings {
  const NotificationSettings({
    this.enabled = false,
    this.defaultReminderOffsetsMinutes = const [1440],
    this.allDayReminderHour = 9,
    this.allDayReminderMinute = 0,
  });

  final bool enabled;
  final List<int> defaultReminderOffsetsMinutes;
  final int allDayReminderHour;
  final int allDayReminderMinute;

  NotificationSettings copyWith({
    bool? enabled,
    List<int>? defaultReminderOffsetsMinutes,
    int? allDayReminderHour,
    int? allDayReminderMinute,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        defaultReminderOffsetsMinutes: List.unmodifiable(
          defaultReminderOffsetsMinutes ?? this.defaultReminderOffsetsMinutes,
        ),
        allDayReminderHour: allDayReminderHour ?? this.allDayReminderHour,
        allDayReminderMinute: allDayReminderMinute ?? this.allDayReminderMinute,
      );
}
