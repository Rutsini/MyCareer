import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/domain/entities/evaluation.dart';

Evaluation evaluation(
        {String name = 'Parcial',
        double? grade,
        double max = 10,
        double weight = 1,
        double? minimum,
        bool recovery = false,
        String? recoveryOf,
        EvaluationType? type}) =>
    Evaluation(
        id: 'e1',
        subjectId: 's1',
        academicYear: 2026,
        name: name,
        type: type ??
            (recovery ? EvaluationType.recovery : EvaluationType.partial),
        date: DateTime(2026),
        allDay: true,
        mandatory: true,
        countsTowardAverage: true,
        grade: grade,
        maxGrade: max,
        minimumPassingGradeOverride: minimum,
        weight: weight,
        status: EvaluationStatus.pending,
        isRecovery: recovery,
        recoveryOfEvaluationId: recoveryOf,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));

void main() {
  test('nombre obligatorio',
      () => expect(evaluation(name: '').validate(), isNotNull));
  test('grade null es válido', () => expect(evaluation().validate(), isNull));
  test('grade dentro del rango',
      () => expect(evaluation(grade: 8).validate(), isNull));
  test('grade fuera del rango',
      () => expect(evaluation(grade: 11).validate(), isNotNull));
  test('maxGrade debe ser positivo',
      () => expect(evaluation(max: 0).validate(), isNotNull));
  test('weight debe ser positivo',
      () => expect(evaluation(weight: 0).validate(), isNotNull));
  test('minimumPassingGradeOverride válido',
      () => expect(evaluation(minimum: 6).validate(), isNull));
  test('recuperatorio requiere original',
      () => expect(evaluation(recovery: true).validate(), isNotNull));
  test('evaluación normal no guarda recoveryOfEvaluationId',
      () => expect(evaluation(recoveryOf: 'e0').validate(), isNotNull));
}
