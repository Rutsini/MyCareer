import '../../domain/entities/subject_schedule_block.dart';

String formatScheduleMinutes(int value) =>
    '${(value ~/ 60).toString().padLeft(2, '0')}:'
    '${(value % 60).toString().padLeft(2, '0')}';

String formatScheduleRange(SubjectScheduleBlock block) =>
    '${formatScheduleMinutes(block.startMinutes)}–'
    '${formatScheduleMinutes(block.endMinutes)}';

String scheduleWeekdayLabel(int day) => const [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ][day - 1];

String classModalityLabel(ClassModality value) => switch (value) {
      ClassModality.presential => 'Presencial',
      ClassModality.virtual => 'Virtual',
      ClassModality.hybrid => 'Híbrida',
    };
