import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'local_notification_gateway.dart';

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  FlutterLocalNotificationGateway([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'academic_reminders';
  static const channelName = 'Recordatorios académicos';
  static const channelDescription = 'Avisos sobre evaluaciones próximas.';

  final FlutterLocalNotificationsPlugin _plugin;
  final Map<int, _WebSchedule> _webSchedules = {};
  Timer? _webTimer;
  String? _initialPayload;
  String? _timeZoneName;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  @override
  Future<void> initialize({void Function(String payload)? onTap}) async {
    await refreshTimeZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onTap?.call(payload);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _initialPayload = launch?.notificationResponse?.payload;
    }
  }

  @override
  Future<bool> refreshTimeZone() async {
    tz_data.initializeTimeZones();
    var name = 'UTC';
    try {
      name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
      name = 'UTC';
    }
    final changed = _timeZoneName != null && _timeZoneName != name;
    _timeZoneName = name;
    return changed;
  }

  @override
  Future<NotificationPermissionState> permissionStatus() async {
    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin>();
      if (web == null) return NotificationPermissionState.notSupported;
      return switch (web.permissionStatus) {
        WebNotificationPermission.granted =>
          NotificationPermissionState.granted,
        WebNotificationPermission.denied => NotificationPermissionState.denied,
        WebNotificationPermission.defaultPermissions =>
          NotificationPermissionState.unknown,
      };
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    return NotificationPermissionState.notSupported;
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin>();
      return await web?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) =>
      _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
        payload: payload,
      );

  @override
  Future<void> schedule({
    required int id,
    required DateTime triggerAt,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      _webSchedules[id] = _WebSchedule(triggerAt, title, body, payload);
      _armWebTimer();
      return;
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(triggerAt, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  void _armWebTimer() {
    _webTimer?.cancel();
    if (_webSchedules.isEmpty) return;
    final next = _webSchedules.entries.reduce(
      (a, b) => a.value.triggerAt.isBefore(b.value.triggerAt) ? a : b,
    );
    final delay = next.value.triggerAt.difference(DateTime.now());
    _webTimer = Timer(delay.isNegative ? Duration.zero : delay, () async {
      final schedule = _webSchedules.remove(next.key);
      if (schedule != null &&
          schedule.triggerAt
              .isAfter(DateTime.now().subtract(const Duration(minutes: 1)))) {
        await show(
          id: next.key,
          title: schedule.title,
          body: schedule.body,
          payload: schedule.payload,
        );
      }
      _armWebTimer();
    });
  }

  @override
  Future<void> cancel(int id) async {
    if (kIsWeb) {
      _webSchedules.remove(id);
      _armWebTimer();
      return;
    }
    await _plugin.cancel(id: id);
  }

  @override
  Future<List<int>> pendingIds() async {
    if (kIsWeb) return _webSchedules.keys.toList();
    return (await _plugin.pendingNotificationRequests())
        .map((request) => request.id)
        .toList();
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) {
      _webSchedules.clear();
      _webTimer?.cancel();
      return;
    }
    await _plugin.cancelAllPendingNotifications();
  }

  @override
  String? takeInitialPayload() {
    final value = _initialPayload;
    _initialPayload = null;
    return value;
  }
}

class _WebSchedule {
  const _WebSchedule(this.triggerAt, this.title, this.body, this.payload);
  final DateTime triggerAt;
  final String title;
  final String body;
  final String? payload;
}
