import 'app_exception.dart';

class AcademicYearAlreadyExistsException extends AppException {
  AcademicYearAlreadyExistsException(int year)
      : super('El año académico $year ya existe.');
}
