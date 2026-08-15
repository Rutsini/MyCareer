import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/repositories/evaluation_repository.dart';
import 'package:my_career/data/repositories/subject_repository.dart';
import 'package:my_career/domain/entities/academic_rule.dart';
import 'package:my_career/domain/entities/evaluation.dart' as domain;
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/services/academic_engine.dart';
import 'package:my_career/features/subjects/application/academic_controller.dart';

void main() {
  Subject makeSubject(
          {AcademicCondition condition = AcademicCondition.noData}) =>
      Subject(
          id: 's',
          academicYearId: 'y',
          academicYear: 2026,
          trackingMode: TrackingMode.tracked,
          name: 'Materia',
          subjectType: SubjectType.mandatory,
          duration: SubjectDuration.annual,
          courseStatus: CourseStatus.active,
          currentCondition: condition,
          gradeMin: 0,
          gradeMax: 10,
          promotionRules: const [
            AcademicRule(
                id: 'r',
                type: AcademicRuleType.minimumApprovedCount,
                name: 'Aprobar una',
                order: 0,
                config: MinimumApprovedCountConfig(1))
          ],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026));
  domain.Evaluation evaluation() => domain.Evaluation(
      id: 'e',
      subjectId: 's',
      academicYear: 2026,
      name: 'Parcial',
      type: domain.EvaluationType.partial,
      date: DateTime(2026),
      allDay: true,
      mandatory: true,
      countsTowardAverage: true,
      maxGrade: 10,
      weight: 1,
      status: domain.EvaluationStatus.approved,
      isRecovery: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026));
  test('cambiar nota recalcula y actualiza condición', () async {
    final subjects = _Subjects(makeSubject());
    final sync = AcademicConditionSynchronizer(
        subjects, _Evaluations([evaluation()]), const AcademicEngine());
    await sync.synchronize('s');
    expect(subjects.updated?.currentCondition, AcademicCondition.promoting);
  });
  test('evita escritura si condición no cambia', () async {
    final subjects =
        _Subjects(makeSubject(condition: AcademicCondition.promoting));
    final sync = AcademicConditionSynchronizer(
        subjects, _Evaluations([evaluation()]), const AcademicEngine());
    await sync.synchronize('s');
    expect(subjects.updated, isNull);
  });
  test('cambiar regla persiste y solicita recálculo', () async {
    final subjects = _Subjects(makeSubject());
    final controller = AcademicRuleController(
        subjects,
        AcademicConditionSynchronizer(
            subjects, _Evaluations([evaluation()]), const AcademicEngine()));
    final ok = await controller.saveRules(subjects.value, promotion: const []);
    expect(ok, isTrue);
    expect(subjects.updated, isNotNull);
  });
}

class _Subjects implements SubjectRepository {
  _Subjects(this.value);
  Subject value;
  Subject? updated;
  @override
  Stream<Subject?> watchSubject(String id) => Stream.value(value);
  @override
  Future<void> updateSubject(Subject s) async {
    updated = s;
    value = s;
  }

  @override
  Future<String> createSubject(Subject s) => throw UnimplementedError();
  @override
  Future<void> deleteSubject(String id) => throw UnimplementedError();
  @override
  Stream<List<Subject>> watchSubjects() => throw UnimplementedError();
}

class _Evaluations implements EvaluationRepository {
  _Evaluations(this.values);
  final List<domain.Evaluation> values;
  @override
  Stream<List<domain.Evaluation>> watchEvaluations() => Stream.value(values);
  @override
  Stream<domain.Evaluation?> watchEvaluation(String id) =>
      Stream.value(values.where((e) => e.id == id).firstOrNull);
  @override
  Future<String> createEvaluation(domain.Evaluation e) =>
      throw UnimplementedError();
  @override
  Future<void> updateEvaluation(domain.Evaluation e) =>
      throw UnimplementedError();
  @override
  Future<void> deleteEvaluation(String id) => throw UnimplementedError();
  @override
  Future<void> deleteEvaluationsBySubject(String id) =>
      throw UnimplementedError();
}
