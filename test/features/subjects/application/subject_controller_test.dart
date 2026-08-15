import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/data/repositories/subject_repository.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/features/subjects/application/subject_controller.dart';
import 'package:my_career/data/repositories/evaluation_repository.dart';
import 'package:my_career/domain/entities/evaluation.dart';

class FakeSubjectRepository implements SubjectRepository {
  Subject? created;
  @override
  Future<String> createSubject(Subject subject) async {
    created = subject;
    return 'new-id';
  }

  @override
  Future<void> deleteSubject(String id) async {}
  @override
  Future<void> updateSubject(Subject subject) async {}
  @override
  Stream<Subject?> watchSubject(String id) => const Stream.empty();
  @override
  Stream<List<Subject>> watchSubjects() => const Stream.empty();
}

class FakeEvaluationRepository implements EvaluationRepository {
  String? deletedSubject;
  @override
  Future<void> deleteEvaluationsBySubject(String id) async {
    deletedSubject = id;
  }

  @override
  Future<String> createEvaluation(Evaluation e) => throw UnimplementedError();
  @override
  Future<void> deleteEvaluation(String id) => throw UnimplementedError();
  @override
  Future<void> updateEvaluation(Evaluation e) => throw UnimplementedError();
  @override
  Stream<Evaluation?> watchEvaluation(String id) => const Stream.empty();
  @override
  Stream<List<Evaluation>> watchEvaluations() => const Stream.empty();
}

void main() {
  test('SubjectController delega la creación al repositorio fake', () async {
    final repository = FakeSubjectRepository();
    final controller = SubjectController(repository);
    final value = Subject(
        id: '',
        academicYearId: '2026',
        academicYear: 2026,
        trackingMode: TrackingMode.tracked,
        name: 'Álgebra',
        subjectType: SubjectType.mandatory,
        duration: SubjectDuration.annual,
        courseStatus: CourseStatus.active,
        currentCondition: AcademicCondition.noData,
        gradeMin: 0,
        gradeMax: 10,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
    expect(await controller.save(value), 'new-id');
    expect(repository.created?.name, 'Álgebra');
  });
  test('al eliminar materia procesa solo sus evaluaciones asociadas', () async {
    final subjects = FakeSubjectRepository();
    final evaluations = FakeEvaluationRepository();
    expect(await SubjectController(subjects, evaluations).delete('subject-a'),
        isTrue);
    expect(evaluations.deletedSubject, 'subject-a');
  });
}
