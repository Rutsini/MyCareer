import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/repositories/academic_year_repository.dart';
import 'package:my_career/domain/entities/academic_year.dart';
import 'package:my_career/features/subjects/application/academic_year_controller.dart';

class _Years implements AcademicYearRepository {
  final years = <AcademicYear>[
    AcademicYear(
        id: '2025',
        year: 2025,
        isCurrent: true,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025)),
  ];
  @override
  Stream<List<AcademicYear>> watchYears() => Stream.value(years);
  @override
  Future<void> createYear(int year, {bool isCurrent = false}) async {
    if (isCurrent) {
      for (var i = 0; i < years.length; i++) {
        years[i] = AcademicYear(
            id: years[i].id,
            year: years[i].year,
            isCurrent: false,
            createdAt: years[i].createdAt,
            updatedAt: DateTime.now());
      }
    }
    years.add(AcademicYear(
        id: '$year',
        year: year,
        isCurrent: isCurrent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now()));
  }

  @override
  Future<void> setCurrent(String id) async {
    for (var i = 0; i < years.length; i++) {
      final item = years[i];
      years[i] = AcademicYear(
          id: item.id,
          year: item.year,
          isCurrent: item.id == id,
          createdAt: item.createdAt,
          updatedAt: DateTime.now());
    }
  }

  @override
  Future<bool> deleteIfEmpty(String id) async => false;
}

void main() {
  test('crear 2026 como actual desmarca 2025', () async {
    final repository = _Years();
    final controller = AcademicYearController(repository);
    expect(await controller.create(2026, current: true), isTrue);
    expect(
        repository.years.singleWhere((y) => y.id == '2025').isCurrent, isFalse);
    expect(
        repository.years.singleWhere((y) => y.id == '2026').isCurrent, isTrue);
    expect(repository.years.where((y) => y.isCurrent), hasLength(1));
  });

  test('setCurrent deja exactamente un año actual', () async {
    final repository = _Years();
    await repository.createYear(2026);
    final controller = AcademicYearController(repository);
    expect(await controller.setCurrent('2026'), isTrue);
    expect(repository.years.where((y) => y.isCurrent).single.id, '2026');
  });
}
