import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/entities/subject_schedule_block.dart';
import 'package:my_career/features/dashboard/presentation/widgets/dashboard_today_schedule.dart';

void main() {
  testWidgets('ordena las clases de hoy por hora de inicio', (tester) async {
    final monday = DateTime(2026, 8, 24, 16);
    final subjects = [
      _subject('asi', 'Administración de Sistemas', 1240, 1385),
      _subject('redes', 'Redes de Datos', 1040, 1140),
      _subject('io', 'Investigación Operativa', 1140, 1240),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DashboardTodaySchedule(subjects: subjects, now: monday),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Redes de Datos')).dy,
      lessThan(tester.getTopLeft(find.text('Investigación Operativa')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Investigación Operativa')).dy,
      lessThan(
        tester.getTopLeft(find.text('Administración de Sistemas')).dy,
      ),
    );
  });
}

Subject _subject(String id, String name, int start, int end) => Subject(
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
      scheduleBlocks: [
        SubjectScheduleBlock(
          id: id,
          weekday: DateTime.monday,
          startMinutes: start,
          endMinutes: end,
        ),
      ],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
