import '../../domain/entities/academic_year.dart';
import '../firebase/academic_year_service.dart';
import '../mappers/academic_year_mapper.dart';

abstract interface class AcademicYearRepository {
  Stream<List<AcademicYear>> watchYears();
  Future<void> createYear(int year, {bool isCurrent});
  Future<void> setCurrent(String id);
  Future<bool> deleteIfEmpty(String id);
}

class FirebaseAcademicYearRepository implements AcademicYearRepository {
  FirebaseAcademicYearRepository(this._service);
  final AcademicYearService _service;
  @override
  Stream<List<AcademicYear>> watchYears() => _service
      .watchYears()
      .map((s) => s.docs.map(AcademicYearMapper.fromDocument).toList());
  @override
  Future<void> createYear(int year, {bool isCurrent = false}) =>
      _service.createYear(year, isCurrent: isCurrent);
  @override
  Future<void> setCurrent(String id) => _service.setCurrent(id);
  @override
  Future<bool> deleteIfEmpty(String id) => _service.deleteIfEmpty(id);
}
