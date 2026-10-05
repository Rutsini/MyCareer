import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/subject_schedule_block.dart';
import 'package:my_career/features/subjects/presentation/widgets/subject_schedule_editor.dart';

void main() {
  testWidgets('agrega, edita y elimina un horario', (tester) async {
    var blocks = <SubjectScheduleBlock>[];
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          update = setState;
          return SubjectScheduleEditor(
            blocks: blocks,
            onChanged: (value) => update(() => blocks = value),
          );
        }),
      ),
    ));

    await tester.tap(find.byKey(const Key('add-schedule-block')));
    await tester.pumpAndSettle();
    expect(find.text('Lunes'), findsWidgets);
    expect(find.text('17:00'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-schedule-block')));
    await tester.pumpAndSettle();

    expect(blocks, hasLength(1));
    expect(blocks.single.weekday, DateTime.monday);
    expect(blocks.single.startMinutes, 17 * 60);
    expect(blocks.single.endMinutes, 19 * 60);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-weekday')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Martes').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-schedule-block')));
    await tester.tap(find.byKey(const Key('save-schedule-block')));
    await tester.pumpAndSettle();

    expect(blocks.single.weekday, DateTime.tuesday);
    final id = blocks.single.id;

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(blocks, isEmpty);
    expect(id, isNotEmpty);
  });
}
