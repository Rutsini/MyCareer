import '../../domain/entities/subject.dart';
import '../firebase/subject_service.dart';
import '../mappers/subject_mapper.dart';

abstract interface class SubjectRepository {
  Stream<List<Subject>> watchSubjects();
  Stream<Subject?> watchSubject(String id);
  Future<String> createSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> deleteSubject(String id);
}

class FirebaseSubjectRepository implements SubjectRepository {
  FirebaseSubjectRepository(this._service);
  final SubjectService _service;
  @override
  Stream<List<Subject>> watchSubjects() => _service.watchSubjects().map((s) {
        final items = s.docs.map(SubjectMapper.fromDocument).toList();
        items.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return items;
      });
  @override
  Stream<Subject?> watchSubject(String id) => _service
      .watchSubject(id)
      .map((d) => d.exists ? SubjectMapper.fromDocument(d) : null);
  @override
  Future<String> createSubject(Subject subject) =>
      _service.createSubject(subject);
  @override
  Future<void> updateSubject(Subject subject) =>
      _service.updateSubject(subject);
  @override
  Future<void> deleteSubject(String id) => _service.deleteSubject(id);
}
