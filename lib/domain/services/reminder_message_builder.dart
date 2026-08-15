import '../entities/evaluation.dart';

class ReminderMessage {
  const ReminderMessage(this.title, this.body);
  final String title;
  final String body;
}

abstract final class ReminderMessageBuilder {
  static ReminderMessage build({
    required Evaluation evaluation,
    required String subjectName,
    required DateTime triggerAt,
  }) {
    final difference = evaluation.date.difference(triggerAt);
    final suffix = switch (difference.inMinutes) {
      0 => 'ahora',
      15 => 'en 15 minutos',
      30 => 'en 30 minutos',
      60 => 'en 1 hora',
      120 => 'en 2 horas',
      1440 => 'mañana',
      _ => '${evaluation.date.day}/${evaluation.date.month} '
          '${evaluation.date.hour.toString().padLeft(2, '0')}:'
          '${evaluation.date.minute.toString().padLeft(2, '0')}',
    };
    return ReminderMessage(
      'Evaluación próxima',
      '$subjectName · ${evaluation.name} $suffix.',
    );
  }
}
