import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/evaluation_reminder.dart';
import 'package:my_career/domain/entities/notification_settings.dart';
import 'package:my_career/domain/services/notification_id_generator.dart';
import 'package:my_career/domain/services/reminder_planner.dart';
import 'package:my_career/domain/services/reminder_trigger_calculator.dart';

Evaluation fixture({
  DateTime? date,
  bool allDay = false,
  EvaluationStatus status = EvaluationStatus.pending,
  List<EvaluationReminder>? reminders,
}) =>
    Evaluation(
      id: 'evaluation-1',
      subjectId: 'subject-1',
      academicYear: 2026,
      name: 'Segundo parcial',
      type: EvaluationType.partial,
      date: date ?? DateTime(2026, 8, 20, 18),
      allDay: allDay,
      mandatory: true,
      countsTowardAverage: true,
      maxGrade: 10,
      weight: 1,
      status: status,
      isRecovery: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      reminders: reminders ??
          const [
            EvaluationReminder(id: 'r1', offsetMinutes: 120),
          ],
    );

void main() {
  const calculator = ReminderTriggerCalculator();
  const settings = NotificationSettings(enabled: true);

  test('timed: resta minutos a la fecha y hora', () {
    final result = calculator.calculate(
      evaluation: fixture(),
      reminder: const EvaluationReminder(id: 'r1', offsetMinutes: 120),
      settings: settings,
    );
    expect(result, DateTime(2026, 8, 20, 16));
  });

  test('all day usa hora configurada un día antes', () {
    final result = calculator.calculate(
      evaluation: fixture(allDay: true),
      reminder: const EvaluationReminder(id: 'r1', offsetMinutes: 1440),
      settings: settings,
    );
    expect(result, DateTime(2026, 8, 19, 9));
  });

  test('all day offset cero usa el mismo día', () {
    final result = calculator.calculate(
      evaluation: fixture(allDay: true),
      reminder: const EvaluationReminder(id: 'r1', offsetMinutes: 0),
      settings: settings,
    );
    expect(result, DateTime(2026, 8, 20, 9));
  });

  test('planner excluye triggers pasados', () {
    final plan = const ReminderPlanner().plan(
      evaluation: fixture(),
      settings: settings,
      now: DateTime(2026, 8, 21),
    );
    expect(plan, isEmpty);
  });

  test('planner solo programa pending', () {
    for (final status in [
      EvaluationStatus.approved,
      EvaluationStatus.failed,
      EvaluationStatus.absent,
    ]) {
      expect(
        const ReminderPlanner().plan(
          evaluation: fixture(status: status),
          settings: settings,
          now: DateTime(2026, 8),
        ),
        isEmpty,
      );
    }
    expect(
      const ReminderPlanner().plan(
        evaluation: fixture(),
        settings: settings,
        now: DateTime(2026, 8),
      ),
      hasLength(1),
    );
  });

  test('planner respeta desactivación global y por reminder', () {
    expect(
      const ReminderPlanner().plan(
        evaluation: fixture(),
        settings: const NotificationSettings(enabled: false),
        now: DateTime(2026, 8),
      ),
      isEmpty,
    );
    expect(
      const ReminderPlanner().plan(
        evaluation: fixture(reminders: const [
          EvaluationReminder(id: 'r1', offsetMinutes: 120, enabled: false),
        ]),
        settings: settings,
        now: DateTime(2026, 8),
      ),
      isEmpty,
    );
  });

  test('ID de notificación es estable y positivo', () {
    final first = NotificationIdGenerator.generate('evaluation-1', 'r1');
    final second = NotificationIdGenerator.generate('evaluation-1', 'r1');
    expect(first, second);
    expect(first, greaterThan(0));
    expect(
        NotificationIdGenerator.generate('evaluation-1', 'r2'), isNot(first));
  });
}
