import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/repositories/subject_repository.dart';
import 'package:my_career/domain/entities/academic_rule.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/features/subjects/application/academic_controller.dart';

void main() {
  Subject makeSubject() => Subject(
        id: 's',
        academicYearId: 'y',
        academicYear: 2026,
        trackingMode: TrackingMode.tracked,
        name: 'Materia',
        subjectType: SubjectType.mandatory,
        duration: SubjectDuration.annual,
        courseStatus: CourseStatus.active,
        gradeMin: 0,
        gradeMax: 10,
        promotionRules: const [
          AcademicRule(
            id: 'r',
            type: AcademicRuleType.minimumApprovedCount,
            name: 'Aprobar una',
            order: 0,
            config: MinimumApprovedCountConfig(1),
          ),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  test('cambiar reglas persiste sin guardar una condición derivada', () async {
    final subjects = _Subjects(makeSubject());
    final controller = AcademicRuleController(subjects);

    final ok = await controller.saveRules(subjects.value, promotion: const []);

    expect(ok, isTrue);
    expect(subjects.updated?.promotionRules, isEmpty);
  });

  test('una regla inválida no modifica la materia', () async {
    final subjects = _Subjects(makeSubject());
    final controller = AcademicRuleController(subjects);
    const invalid = AcademicRule(
      id: 'invalid',
      type: AcademicRuleType.minimumApprovedCount,
      name: 'Inválida',
      order: 0,
      config: MinimumApprovedCountConfig(0),
    );

    final ok =
        await controller.saveRules(subjects.value, promotion: const [invalid]);

    expect(ok, isFalse);
    expect(subjects.updated, isNull);
    expect(controller.state.hasError, isTrue);
  });
}

class _Subjects implements SubjectRepository {
  _Subjects(this.value);

  Subject value;
  Subject? updated;

  @override
  Stream<Subject?> watchSubject(String id) => Stream.value(value);

  @override
  Future<void> updateSubject(Subject subject) async {
    updated = subject;
    value = subject;
  }

  @override
  Future<String> createSubject(Subject subject) => throw UnimplementedError();

  @override
  Future<void> deleteSubject(String id) => throw UnimplementedError();

  @override
  Stream<List<Subject>> watchSubjects() => throw UnimplementedError();
}
