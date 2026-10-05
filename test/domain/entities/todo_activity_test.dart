import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/todo_activity.dart';

TodoActivity activity({
  String title = 'Leer capítulo',
  String? description,
  String? subjectId,
}) =>
    TodoActivity(
      id: '',
      title: title,
      description: description,
      day: DateTime(2026, 10, 5),
      subjectId: subjectId,
      isCompleted: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('acepta una actividad válida sin materia', () {
    expect(activity().validate(), isNull);
  });

  test('rechaza un título demasiado corto', () {
    expect(activity(title: 'x').validate(), isNotNull);
  });

  test('rechaza una descripción demasiado extensa', () {
    expect(
      activity(description: List.filled(1001, 'x').join()).validate(),
      isNotNull,
    );
  });

  test('rechaza un identificador de materia vacío', () {
    expect(activity(subjectId: ' ').validate(), isNotNull);
  });
}
