import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/data/repositories/subject_repository.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/features/subjects/application/subject_controller.dart';

class FakeSubjectRepository implements SubjectRepository {
  Subject? created;
  Subject? updated;
  String? deletedId;
  @override
  Future<String> createSubject(Subject subject) async {
    created = subject;
    return 'new-id';
  }

  @override
  Future<void> deleteSubject(String id) async => deletedId = id;
  @override
  Future<void> updateSubject(Subject subject) async => updated = subject;
  @override
  Stream<Subject?> watchSubject(String id) => const Stream.empty();
  @override
  Stream<List<Subject>> watchSubjects() => const Stream.empty();
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
        gradeMin: 0,
        gradeMax: 10,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
    expect(await controller.save(value), 'new-id');
    expect(repository.created?.name, 'Álgebra');
  });
  test('editar materia actualiza sus notificaciones locales', () async {
    final repository = FakeSubjectRepository();
    var notificationsSynchronized = false;
    final controller = SubjectController(
      repository,
      () async => notificationsSynchronized = true,
    );
    final value = Subject(
        id: 'subject-a',
        academicYearId: '2026',
        academicYear: 2026,
        trackingMode: TrackingMode.tracked,
        name: 'Álgebra II',
        subjectType: SubjectType.mandatory,
        duration: SubjectDuration.annual,
        courseStatus: CourseStatus.active,
        gradeMin: 0,
        gradeMax: 10,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));

    expect(await controller.save(value), 'subject-a');
    expect(repository.updated, value);
    expect(notificationsSynchronized, isTrue);
  });
  test('al eliminar materia delega la cascada atómica al repositorio',
      () async {
    final subjects = FakeSubjectRepository();
    var notificationsSynchronized = false;
    final controller = SubjectController(
      subjects,
      () async => notificationsSynchronized = true,
    );

    expect(await controller.delete('subject-a'), isTrue);
    expect(subjects.deletedId, 'subject-a');
    expect(notificationsSynchronized, isTrue);
  });
}
