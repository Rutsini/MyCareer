import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/domain/entities/academic_rule.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/services/academic_engine.dart';

void main() {
  const engine = AcademicEngine();
  AcademicRule rule(AcademicRuleConfig c,
          {String id = 'r', bool enabled = true}) =>
      AcademicRule(
          id: id,
          type: switch (c) {
            MinimumAverageConfig() => AcademicRuleType.minimumAverage,
            MinimumGradeByTypeConfig() => AcademicRuleType.minimumGradeByType,
            MinimumApprovedPercentageConfig() =>
              AcademicRuleType.minimumApprovedPercentage,
            MinimumApprovedCountConfig() =>
              AcademicRuleType.minimumApprovedCount,
            AllEvaluationsApprovedConfig() =>
              AcademicRuleType.allEvaluationsApproved,
            RequiredEvaluationConfig() => AcademicRuleType.requiredEvaluation
          },
          name: 'Regla válida',
          enabled: enabled,
          order: 0,
          config: c);
  Subject subject(
          {List<AcademicRule> promotion = const [],
          List<AcademicRule> regularity = const [],
          CourseStatus status = CourseStatus.active,
          TrackingMode mode = TrackingMode.tracked,
          RecoveryPolicy policy = RecoveryPolicy.highestGrade}) =>
      Subject(
          id: 's',
          academicYearId: 'y',
          academicYear: 2026,
          trackingMode: mode,
          name: 'Materia',
          subjectType: SubjectType.mandatory,
          duration: SubjectDuration.annual,
          courseStatus: status,
          currentCondition:
              mode == TrackingMode.tracked ? AcademicCondition.noData : null,
          gradeMin: 0,
          gradeMax: 10,
          recoveryPolicy: policy,
          promotionRules: promotion,
          regularityRules: regularity,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026));
  Evaluation evaluation(String id,
          {double? grade,
          EvaluationStatus status = EvaluationStatus.pending,
          EvaluationType type = EvaluationType.partial,
          double weight = 1,
          bool recovery = false,
          String? recoveryOf}) =>
      Evaluation(
          id: id,
          subjectId: 's',
          academicYear: 2026,
          name: 'Evaluación $id',
          type: recovery ? EvaluationType.recovery : type,
          date: DateTime(2026),
          allDay: true,
          mandatory: true,
          countsTowardAverage: true,
          grade: grade,
          maxGrade: 10,
          weight: weight,
          status: status,
          isRecovery: recovery,
          recoveryOfEvaluationId: recoveryOf,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026));
  AcademicRuleResult result(Subject s, List<Evaluation> e) =>
      engine.evaluate(subject: s, evaluations: e).promotionResults.single;

  test(
      'sin reglas es noData',
      () => expect(
          engine.evaluate(subject: subject(), evaluations: []).condition,
          AcademicCondition.noData));
  test('promedio met, unmet y pending', () {
    final r = rule(const MinimumAverageConfig(7));
    expect(
        result(subject(promotion: [r]), [
          evaluation('1', grade: 8, status: EvaluationStatus.approved)
        ]).status,
        RuleResultStatus.met);
    expect(
        result(subject(promotion: [r]), [
          evaluation('1', grade: 6, status: EvaluationStatus.failed)
        ]).status,
        RuleResultStatus.unmet);
    expect(
        result(subject(promotion: [r]), []).status, RuleResultStatus.pending);
  });
  test('nota mínima por tipo', () {
    final r = rule(const MinimumGradeByTypeConfig(EvaluationType.partial, 6));
    expect(
        result(subject(promotion: [r]), [
          evaluation('1', grade: 8, status: EvaluationStatus.approved),
          evaluation('2', grade: 7, status: EvaluationStatus.approved)
        ]).status,
        RuleResultStatus.met);
    expect(
        result(subject(promotion: [r]), [
          evaluation('1', grade: 4, status: EvaluationStatus.failed)
        ]).status,
        RuleResultStatus.unmet);
  });
  test('cantidad informa faltante', () {
    final r = rule(const MinimumApprovedCountConfig(3));
    final x = result(subject(promotion: [r]), [
      evaluation('1', status: EvaluationStatus.approved),
      evaluation('2', status: EvaluationStatus.approved)
    ]);
    expect(x.currentValue, 2);
    expect(x.actions.single, contains('1'));
  });
  test('porcentaje 3 de 4', () {
    final values = [
      for (var i = 0; i < 4; i++)
        evaluation('$i',
            status: i < 3 ? EvaluationStatus.approved : EvaluationStatus.failed)
    ];
    expect(
        result(
                subject(promotion: [
                  rule(const MinimumApprovedPercentageConfig(75))
                ]),
                values)
            .status,
        RuleResultStatus.met);
    expect(
        result(
                subject(promotion: [
                  rule(const MinimumApprovedPercentageConfig(80))
                ]),
                values)
            .status,
        RuleResultStatus.unmet);
  });
  test('todas aprobadas distingue pending y failed', () {
    final r = rule(const AllEvaluationsApprovedConfig());
    expect(
        result(subject(promotion: [r]), [
          evaluation('1', status: EvaluationStatus.approved),
          evaluation('2')
        ]).status,
        RuleResultStatus.pending);
    expect(
        result(subject(promotion: [r]),
            [evaluation('1', status: EvaluationStatus.failed)]).status,
        RuleResultStatus.unmet);
  });
  test('evaluación requerida y referencia eliminada', () {
    final r = rule(const RequiredEvaluationConfig('2'));
    expect(result(subject(promotion: [r]), [evaluation('2')]).status,
        RuleResultStatus.pending);
    expect(
        result(subject(promotion: [r]),
            [evaluation('2', status: EvaluationStatus.approved)]).status,
        RuleResultStatus.met);
    expect(
        result(subject(promotion: [r]), []).message, contains('ya no existe'));
  });
  test('recuperatorio approvalOnly no cuenta doble', () {
    final r = rule(const MinimumApprovedCountConfig(1));
    final values = [
      evaluation('1', grade: 4, status: EvaluationStatus.failed),
      evaluation('rec',
          grade: 8,
          status: EvaluationStatus.recovered,
          recovery: true,
          recoveryOf: '1')
    ];
    final x = result(
        subject(promotion: [r], policy: RecoveryPolicy.approvalOnly), values);
    expect(x.status, RuleResultStatus.met);
    expect(x.currentValue, 1);
  });
  test('algoritmo de condición', () {
    final met = rule(const MinimumApprovedCountConfig(1));
    final unmet = rule(const MinimumApprovedCountConfig(2));
    final one = [evaluation('1', status: EvaluationStatus.approved)];
    expect(
        engine
            .evaluate(subject: subject(promotion: [met]), evaluations: one)
            .condition,
        AcademicCondition.promoting);
    expect(
        engine
            .evaluate(
                subject: subject(promotion: [unmet], regularity: [met]),
                evaluations: one)
            .condition,
        AcademicCondition.regular);
    expect(
        engine
            .evaluate(subject: subject(regularity: [unmet]), evaluations: one)
            .condition,
        AcademicCondition.atRisk);
    expect(
        engine
            .evaluate(
                subject:
                    subject(regularity: [unmet], status: CourseStatus.finished),
                evaluations: one)
            .condition,
        AcademicCondition.failed);
  });
  test('met más pending en regularidad es noData', () {
    final rules = [
      rule(const MinimumApprovedCountConfig(1), id: 'a'),
      rule(const RequiredEvaluationConfig('2'), id: 'b')
    ];
    expect(
        engine.evaluate(subject: subject(regularity: rules), evaluations: [
          evaluation('1', status: EvaluationStatus.approved),
          evaluation('2')
        ]).condition,
        AcademicCondition.noData);
  });
  test('solo promoción no cumplida es noData', () {
    expect(
        engine.evaluate(
            subject:
                subject(promotion: [rule(const MinimumApprovedCountConfig(2))]),
            evaluations: [
              evaluation('1', status: EvaluationStatus.approved)
            ]).condition,
        AcademicCondition.noData);
  });
  test('historical devuelve condición null', () {
    expect(
        engine.evaluate(
            subject: subject(mode: TrackingMode.historical),
            evaluations: []).condition,
        isNull);
  });
  test('disabled no participa', () {
    expect(
        engine.evaluate(
            subject: subject(regularity: [
              rule(const MinimumApprovedCountConfig(2), enabled: false)
            ]),
            evaluations: []).condition,
        AcademicCondition.noData);
  });
  test('nota exacta única y caso imposible', () {
    final r = rule(const MinimumAverageConfig(8));
    var x = result(subject(promotion: [r]), [
      evaluation('1', grade: 7, status: EvaluationStatus.approved),
      evaluation('2')
    ]);
    expect(x.actions.single, contains('9'));
    x = result(subject(promotion: [rule(const MinimumAverageConfig(10))]), [
      evaluation('1', grade: 1, status: EvaluationStatus.failed, weight: 2),
      evaluation('2')
    ]);
    expect(x.actions.single, contains('no alcanza'));
  });
}
