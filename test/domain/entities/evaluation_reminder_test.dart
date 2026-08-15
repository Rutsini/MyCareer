import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/evaluation_reminder.dart';

Evaluation fixture(List<EvaluationReminder> reminders, {bool allDay = false}) =>
    Evaluation(
      id: 'e',
      subjectId: 's',
      academicYear: 2026,
      name: 'Parcial',
      type: EvaluationType.partial,
      date: DateTime(2026, 8, 20, 18),
      allDay: allDay,
      mandatory: true,
      countsTowardAverage: true,
      maxGrade: 10,
      weight: 1,
      status: EvaluationStatus.pending,
      isRecovery: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      reminders: reminders,
    );

void main() {
  test('offset cero es válido', () {
    expect(
        const EvaluationReminder(id: 'r', offsetMinutes: 0).validate(), isNull);
  });
  test('offset negativo es inválido', () {
    expect(const EvaluationReminder(id: 'r', offsetMinutes: -1).validate(),
        isNotNull);
  });
  test('id vacío es inválido', () {
    expect(const EvaluationReminder(id: '', offsetMinutes: 1).validate(),
        isNotNull);
  });
  test('Evaluation rechaza offsets activos duplicados', () {
    expect(
      fixture(const [
        EvaluationReminder(id: 'a', offsetMinutes: 60),
        EvaluationReminder(id: 'b', offsetMinutes: 60),
      ]).validate(),
      isNotNull,
    );
  });
  test('Evaluation admite máximo cinco reminders', () {
    expect(
      fixture(List.generate(
              6, (i) => EvaluationReminder(id: 'r$i', offsetMinutes: i * 60)))
          .validate(),
      isNotNull,
    );
  });
  test('all day solo admite múltiplos de un día', () {
    expect(
      fixture(const [EvaluationReminder(id: 'r', offsetMinutes: 60)],
              allDay: true)
          .validate(),
      isNotNull,
    );
  });
}
