import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/core/errors/academic_year_exception.dart';
import 'package:my_career/data/firebase/academic_year_service.dart';

void main() {
  test('no permite crear dos veces el mismo año académico', () {
    expect(
      () => ensureAcademicYearDoesNotExist(exists: true, year: 2026),
      throwsA(
        isA<AcademicYearAlreadyExistsException>().having(
          (error) => error.message,
          'message',
          'El año académico 2026 ya existe.',
        ),
      ),
    );
  });

  test('permite crear un año académico inexistente', () {
    expect(
      () => ensureAcademicYearDoesNotExist(exists: false, year: 2026),
      returnsNormally,
    );
  });
}
