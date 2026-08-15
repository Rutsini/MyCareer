enum NotificationPermissionState { unknown, granted, denied, notSupported }

abstract interface class LocalNotificationGateway {
  Future<void> initialize({void Function(String payload)? onTap});
  Future<NotificationPermissionState> permissionStatus();
  Future<bool> requestPermission();
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
  Future<void> schedule({
    required int id,
    required DateTime triggerAt,
    required String title,
    required String body,
    String? payload,
  });
  Future<void> cancel(int id);
  Future<List<int>> pendingIds();
  Future<void> cancelAll();
  String? takeInitialPayload();
  Future<bool> refreshTimeZone();
}
