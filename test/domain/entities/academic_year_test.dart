import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/academic_year.dart';

void main() {
  AcademicYear year(int value, {bool current = false}) => AcademicYear(
      id: '$value',
      year: value,
      isCurrent: current,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026));
  test('acepta un año académico válido',
      () => expect(year(2026, current: true).validate(), isNull));
  test('rechaza un año fuera del rango válido',
      () => expect(year(1800).validate(), isNotNull));
  test('conserva el indicador de año actual',
      () => expect(year(2026, current: true).isCurrent, isTrue));
}
