import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/mappers/subject_schedule_block_mapper.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/entities/subject_schedule_block.dart';

void main() {
  test('una materia antigua mantiene los horarios vacíos', () {
    expect(_subject().scheduleBlocks, isEmpty);
    expect(SubjectScheduleBlockMapper.fromValue(null), isEmpty);
  });

  test('serializa y deserializa bloques y modalidad', () {
    const blocks = [
      SubjectScheduleBlock(
        id: 'mon',
        weekday: DateTime.monday,
        startMinutes: 17 * 60,
        endMinutes: 19 * 60,
        location: 'Aula 105',
      ),
      SubjectScheduleBlock(
        id: 'thu',
        weekday: DateTime.thursday,
        startMinutes: 17 * 60,
        endMinutes: 19 * 60,
        modality: ClassModality.hybrid,
        virtualLink: 'https://class.test',
      ),
    ];

    final encoded = SubjectScheduleBlockMapper.toList(blocks);
    final decoded = SubjectScheduleBlockMapper.fromValue(encoded);

    expect(decoded, hasLength(2));
    expect(decoded.first.location, 'Aula 105');
    expect(decoded.last.modality, ClassModality.hybrid);
    expect(decoded.last.virtualLink, 'https://class.test');
  });

  test('descarta bloques corruptos al leer datos antiguos', () {
    final decoded = SubjectScheduleBlockMapper.fromValue([
      {
        'id': 'invalid',
        'weekday': 12,
        'startMinutes': 1200,
        'endMinutes': 1100,
      },
    ]);

    expect(decoded, isEmpty);
  });

  test('rechaza fin igual o anterior al inicio', () {
    const equal = SubjectScheduleBlock(
      id: 'x',
      weekday: DateTime.monday,
      startMinutes: 18 * 60,
      endMinutes: 18 * 60,
    );
    const earlier = SubjectScheduleBlock(
      id: 'y',
      weekday: DateTime.monday,
      startMinutes: 18 * 60,
      endMinutes: 17 * 60,
    );

    expect(equal.validate(), contains('posterior'));
    expect(earlier.validate(), contains('posterior'));
  });

  test('la materia rechaza identificadores de horario duplicados', () {
    const block = SubjectScheduleBlock(
      id: 'same',
      weekday: DateTime.monday,
      startMinutes: 17 * 60,
      endMinutes: 19 * 60,
    );

    expect(
      _subject(scheduleBlocks: const [block, block]).validate(),
      contains('identificador diferente'),
    );
  });
}

Subject _subject({List<SubjectScheduleBlock> scheduleBlocks = const []}) =>
    Subject(
      id: 'subject-a',
      academicYearId: '2026',
      academicYear: 2026,
      trackingMode: TrackingMode.tracked,
      name: 'Redes',
      subjectType: SubjectType.mandatory,
      duration: SubjectDuration.annual,
      courseStatus: CourseStatus.active,
      gradeMin: 0,
      gradeMax: 10,
      scheduleBlocks: scheduleBlocks,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
