import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/entities/subject_schedule_block.dart';
import 'package:my_career/features/schedule/presentation/screens/schedule_screen.dart';

void main() {
  testWidgets(
      'semana muestra bloques proporcionales, conflictos y días dinámicos',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final entries = scheduleEntries([
      _subject('redes', 'Redes', [_block('r', 1, 1040, 1140)]),
      _subject('io', 'IO', [_block('i', 1, 1080, 1240)]),
      _subject('asi', 'ASI', [_block('a', 3, 1040, 1240)]),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: WeeklyScheduleGrid(entries: entries),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Redes'), findsOneWidget);
    expect(find.text('IO'), findsOneWidget);
    expect(find.text('ASI'), findsOneWidget);
    expect(find.text('Hay horarios superpuestos'), findsOneWidget);
    expect(find.byKey(const Key('schedule-day-6')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra sábado y domingo solamente cuando tienen clases',
      (tester) async {
    final entries = scheduleEntries([
      _subject('weekend', 'Taller', [
        _block('sat', DateTime.saturday, 600, 720),
        _block('sun', DateTime.sunday, 800, 900),
      ]),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: WeeklyScheduleGrid(entries: entries),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('schedule-day-6')), findsOneWidget);
    expect(find.byKey(const Key('schedule-day-7')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('detecta superposición pero no confunde bloques consecutivos', () {
    final first = _block('first', DateTime.monday, 600, 720);
    final overlapping = _block('overlap', DateTime.monday, 700, 780);
    final following = _block('following', DateTime.monday, 720, 840);

    expect(schedulesConflict(first, overlapping), isTrue);
    expect(schedulesConflict(first, following), isFalse);
  });
}

SubjectScheduleBlock _block(String id, int day, int start, int end) =>
    SubjectScheduleBlock(
      id: id,
      weekday: day,
      startMinutes: start,
      endMinutes: end,
    );

Subject _subject(
  String id,
  String name,
  List<SubjectScheduleBlock> blocks,
) =>
    Subject(
      id: id,
      academicYearId: '2026',
      academicYear: 2026,
      trackingMode: TrackingMode.tracked,
      name: name,
      subjectType: SubjectType.mandatory,
      duration: SubjectDuration.annual,
      courseStatus: CourseStatus.active,
      gradeMin: 0,
      gradeMax: 10,
      scheduleBlocks: blocks,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
