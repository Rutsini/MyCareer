import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/mappers/todo_activity_mapper.dart';
import 'package:my_career/domain/entities/todo_activity.dart';

void main() {
  test('persiste el día sin incorporar una hora', () {
    final value = TodoActivity(
      id: '',
      title: 'Leer capítulo',
      description: ' ',
      day: DateTime(2026, 10, 5, 23, 45),
      isCompleted: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final map = TodoActivityMapper.toMap(value, creating: true);

    expect(map['day'], '2026-10-05');
    expect(map['description'], isNull);
    expect(map['schemaVersion'], 1);
    expect(map, contains('createdAt'));
  });
}
