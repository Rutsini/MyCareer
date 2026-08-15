import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/core/notifications/local_notification_gateway.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/evaluation_reminder.dart';
import 'package:my_career/domain/entities/notification_settings.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/features/notifications/application/notification_scheduler.dart';

class FakeGateway implements LocalNotificationGateway {
  FakeGateway(this.permission);
  NotificationPermissionState permission;
  final Map<int, DateTime> scheduled = {};
  final List<int> cancelled = [];

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();
  @override
  Future<void> initialize({void Function(String payload)? onTap}) async {}
  @override
  Future<List<int>> pendingIds() async => scheduled.keys.toList();
  @override
  Future<NotificationPermissionState> permissionStatus() async => permission;
  @override
  Future<bool> refreshTimeZone() async => false;
  @override
  Future<bool> requestPermission() async =>
      permission == NotificationPermissionState.granted;
  @override
  Future<void> schedule({
    required int id,
    required DateTime triggerAt,
    required String title,
    required String body,
    String? payload,
  }) async =>
      scheduled[id] = triggerAt;
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}
  @override
  String? takeInitialPayload() => null;
}

Evaluation evaluation({
  DateTime? date,
  EvaluationStatus status = EvaluationStatus.pending,
}) =>
    Evaluation(
      id: 'e1',
      subjectId: 's1',
      academicYear: 2026,
      name: 'Parcial',
      type: EvaluationType.partial,
      date: date ?? DateTime(2026, 8, 20, 18),
      allDay: false,
      mandatory: true,
      countsTowardAverage: true,
      maxGrade: 10,
      weight: 1,
      status: status,
      isRecovery: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      reminders: const [EvaluationReminder(id: 'r1', offsetMinutes: 120)],
    );

Subject subject() => Subject(
      id: 's1',
      academicYearId: '2026',
      academicYear: 2026,
      trackingMode: TrackingMode.tracked,
      name: 'Redes de Datos',
      subjectType: SubjectType.mandatory,
      duration: SubjectDuration.annual,
      courseStatus: CourseStatus.active,
      currentCondition: AcademicCondition.noData,
      gradeMin: 0,
      gradeMax: 10,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  const settings = NotificationSettings(enabled: true);

  test('permiso denegado no programa ni lanza error', () async {
    final gateway = FakeGateway(NotificationPermissionState.denied);
    await NotificationScheduler(gateway).synchronizeAll(
      evaluations: [evaluation()],
      subjects: [subject()],
      settings: settings,
      now: DateTime(2026, 8),
    );
    expect(gateway.scheduled, isEmpty);
  });

  test('cambio de fecha cancela y recrea el schedule', () async {
    final gateway = FakeGateway(NotificationPermissionState.granted);
    final scheduler = NotificationScheduler(gateway);
    await scheduler.synchronizeAll(
      evaluations: [evaluation()],
      subjects: [subject()],
      settings: settings,
      now: DateTime(2026, 8),
    );
    final oldDate = gateway.scheduled.values.single;
    await scheduler.synchronizeAll(
      evaluations: [evaluation(date: DateTime(2026, 8, 25, 18))],
      subjects: [subject()],
      settings: settings,
      now: DateTime(2026, 8),
    );
    expect(gateway.cancelled, isNotEmpty);
    expect(gateway.scheduled.values.single, isNot(oldDate));
  });

  test('resolver o eliminar evaluación quita schedules', () async {
    final gateway = FakeGateway(NotificationPermissionState.granted);
    final scheduler = NotificationScheduler(gateway);
    await scheduler.synchronizeAll(
      evaluations: [evaluation()],
      subjects: [subject()],
      settings: settings,
      now: DateTime(2026, 8),
    );
    await scheduler.synchronizeAll(
      evaluations: [evaluation(status: EvaluationStatus.approved)],
      subjects: [subject()],
      settings: settings,
      now: DateTime(2026, 8),
    );
    expect(gateway.scheduled, isEmpty);
    await scheduler.synchronizeAll(
      evaluations: const [],
      subjects: [subject()],
      settings: settings,
      now: DateTime(2026, 8),
    );
    expect(gateway.scheduled, isEmpty);
  });

  test('desactivar global cancela pero no modifica Evaluation', () async {
    final gateway = FakeGateway(NotificationPermissionState.granted);
    final item = evaluation();
    final scheduler = NotificationScheduler(gateway);
    await scheduler.synchronizeAll(
      evaluations: [item],
      subjects: [subject()],
      settings: settings,
      now: DateTime(2026, 8),
    );
    await scheduler.synchronizeAll(
      evaluations: [item],
      subjects: [subject()],
      settings: const NotificationSettings(enabled: false),
      now: DateTime(2026, 8),
    );
    expect(gateway.scheduled, isEmpty);
    expect(item.reminders, hasLength(1));
  });
}
