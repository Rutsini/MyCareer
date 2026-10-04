import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/data/repositories/evaluation_repository.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/features/evaluations/application/evaluation_controller.dart';

class FakeRepository implements EvaluationRepository {
  String? operation;
  @override
  Future<String> createEvaluation(Evaluation e) async {
    operation = 'create';
    return 'new';
  }

  @override
  Future<void> updateEvaluation(Evaluation e) async {
    operation = 'update';
  }

  @override
  Future<void> deleteEvaluation(String id) async {
    operation = 'delete';
  }

  @override
  Stream<Evaluation?> watchEvaluation(String id) => const Stream.empty();
  @override
  Stream<List<Evaluation>> watchEvaluations() => const Stream.empty();
}

Evaluation value(String id) => Evaluation(
    id: id,
    subjectId: 's',
    academicYear: 2026,
    name: 'Parcial',
    type: EvaluationType.partial,
    date: DateTime(2026),
    allDay: true,
    mandatory: true,
    countsTowardAverage: true,
    maxGrade: 10,
    weight: 1,
    status: EvaluationStatus.pending,
    isRecovery: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026));
void main() {
  test('createEvaluation', () async {
    final r = FakeRepository();
    expect(await EvaluationController(r).save(value('')), 'new');
    expect(r.operation, 'create');
  });
  test('updateEvaluation', () async {
    final r = FakeRepository();
    expect(await EvaluationController(r).save(value('e')), 'e');
    expect(r.operation, 'update');
  });
  test('deleteEvaluation', () async {
    final r = FakeRepository();
    expect(await EvaluationController(r).delete('e'), isTrue);
    expect(r.operation, 'delete');
  });
}
