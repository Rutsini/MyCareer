import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/repositories/todo_activity_repository.dart';
import 'package:my_career/domain/entities/todo_activity.dart';
import 'package:my_career/features/activities/application/todo_activity_controller.dart';
import 'package:my_career/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:my_career/features/evaluations/application/evaluation_controller.dart';
import 'package:my_career/features/subjects/application/subject_controller.dart';

class _DelayedTodoActivityRepository implements TodoActivityRepository {
  final updateCompleter = Completer<void>();

  @override
  Future<String> createActivity(TodoActivity activity) async => activity.id;

  @override
  Future<void> deleteActivity(String id) async {}

  @override
  Future<void> updateActivity(TodoActivity activity) => updateCompleter.future;

  @override
  Stream<List<TodoActivity>> watchActivities() => const Stream.empty();
}

void main() {
  testWidgets('muestra las tres pestañas y el detalle diario', (tester) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final activity = TodoActivity(
      id: 'activity-a',
      title: 'Leer capítulo 4',
      day: day,
      isCompleted: false,
      createdAt: day,
      updatedAt: day,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        evaluationsProvider.overrideWith((ref) => Stream.value(const [])),
        todoActivitiesProvider.overrideWith((ref) => Stream.value([activity])),
        subjectsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: const MaterialApp(home: Scaffold(body: CalendarScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Tab, 'Calendario'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Lista'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Actividades'), findsOneWidget);

    final dayKey = 'calendar-day-${day.toIso8601String().substring(0, 10)}';
    await tester.tap(find.byKey(ValueKey(dayKey)));
    await tester.pumpAndSettle();
    expect(find.text('Leer capítulo 4'), findsOneWidget);
    expect(find.text('Agregar evaluación'), findsOneWidget);
    expect(find.text('Agregar actividad'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Actividades'));
    await tester.pumpAndSettle();
    expect(find.text('Leer capítulo 4'), findsOneWidget);
    expect(find.text('Nueva actividad'), findsOneWidget);
  });

  testWidgets('actualiza el check del detalle diario sin cerrar el diálogo',
      (tester) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final activity = TodoActivity(
      id: 'activity-a',
      title: 'Leer capítulo 4',
      day: day,
      isCompleted: false,
      createdAt: day,
      updatedAt: day,
    );
    final repository = _DelayedTodoActivityRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        evaluationsProvider.overrideWith((ref) => Stream.value(const [])),
        todoActivitiesProvider.overrideWith((ref) => Stream.value([activity])),
        todoActivityControllerProvider
            .overrideWith((ref) => TodoActivityController(repository)),
        subjectsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: const MaterialApp(home: Scaffold(body: CalendarScreen())),
    ));
    await tester.pumpAndSettle();

    final dayKey = 'calendar-day-${day.toIso8601String().substring(0, 10)}';
    await tester.tap(find.byKey(ValueKey(dayKey)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    final title = tester.widget<Text>(find.text('Leer capítulo 4'));
    expect(title.style?.decoration, TextDecoration.lineThrough);

    repository.updateCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('una actividad completada no muestra punto en el calendario',
      (tester) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final activity = TodoActivity(
      id: 'activity-completed',
      title: 'Actividad terminada',
      day: day,
      isCompleted: true,
      createdAt: day,
      updatedAt: day,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        evaluationsProvider.overrideWith((ref) => Stream.value(const [])),
        todoActivitiesProvider.overrideWith((ref) => Stream.value([activity])),
        subjectsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: const MaterialApp(home: Scaffold(body: CalendarScreen())),
    ));
    await tester.pumpAndSettle();

    final date = day.toIso8601String().substring(0, 10);
    expect(find.byKey(ValueKey('calendar-activity-dot-$date')), findsNothing);
  });
}
