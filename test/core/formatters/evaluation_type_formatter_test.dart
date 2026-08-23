import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/core/formatters/evaluation_type_formatter.dart';
import 'package:my_career/domain/entities/evaluation.dart';

void main() {
  test('traduce los tipos de evaluación para la UI', () {
    expect(evaluationTypeLabel(EvaluationType.partial), 'Parcial');
    expect(
        evaluationTypeLabel(EvaluationType.practicalWork), 'Trabajo práctico');
    expect(evaluationTypeLabel(EvaluationType.finalExam), 'Examen final');
    final labels = EvaluationType.values.map(evaluationTypeLabel).join(' ');
    expect(labels, isNot(contains('partial')));
    expect(labels, isNot(contains('practicalWork')));
    expect(labels, isNot(contains('finalExam')));
  });
}
