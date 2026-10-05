import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/repositories/todo_activity_repository.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/entities/todo_activity.dart';
import 'package:my_career/features/activities/application/todo_activity_controller.dart';
import 'package:my_career/features/activities/presentation/todo_activity_form.dart';
import 'package:my_career/features/subjects/application/subject_controller.dart';

class _TodoActivityRepository implements TodoActivityRepository {
  @override
  Future<String> createActivity(TodoActivity activity) async => 'new';

  @override
  Future<void> deleteActivity(String id) async {}

  @override
  Future<void> updateActivity(TodoActivity activity) async {}

  @override
  Stream<List<TodoActivity>> watchActivities() => const Stream.empty();
}

Subject _subject(String id, String name, int year) => Subject(
      id: id,
      academicYearId: 'year-$year',
      academicYear: year,
      trackingMode: TrackingMode.tracked,
      name: name,
      subjectType: SubjectType.mandatory,
      duration: SubjectDuration.annual,
      courseStatus: CourseStatus.active,
      gradeMin: 0,
      gradeMax: 10,
      createdAt: DateTime(year),
      updatedAt: DateTime(year),
    );

void main() {
  testWidgets('filtra las materias por el año de la actividad', (tester) async {
    final repository = _TodoActivityRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        subjectsProvider.overrideWith((ref) => Stream.value([
              _subject('current', 'Álgebra 2026', 2026),
              _subject('previous', 'Álgebra 2025', 2025),
            ])),
        todoActivityControllerProvider
            .overrideWith((ref) => TodoActivityController(repository)),
      ],
      child: MaterialApp(
        home: Scaffold(body: TodoActivityForm(day: DateTime(2026, 10, 5))),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Materia de 2026 (opcional)'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();

    expect(find.text('Álgebra 2026'), findsOneWidget);
    expect(find.text('Álgebra 2025'), findsNothing);
  });
}
