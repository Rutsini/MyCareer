import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/domain/entities/academic_rule.dart';
import 'package:my_career/domain/entities/academic_year.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/models/dashboard_data.dart';
import 'package:my_career/domain/services/dashboard_calculator.dart';

const calculator = DashboardCalculator();
final now = DateTime(2026, 8, 15, 12);
AcademicYear year(String id, int value, {bool current = false}) => AcademicYear(
      id: id,
      year: value,
      isCurrent: current,
      createdAt: DateTime(value),
      updatedAt: DateTime(value),
    );
AcademicRule minimumCount(int count) => AcademicRule(
      id: 'rule-$count',
      type: AcademicRuleType.minimumApprovedCount,
      name: 'Cantidad mínima',
      order: 0,
      config: MinimumApprovedCountConfig(count),
    );
Subject subject(
  String id, {
  String yearId = 'current',
  TrackingMode mode = TrackingMode.tracked,
  CourseStatus status = CourseStatus.active,
  List<AcademicRule> promotion = const [],
  List<AcademicRule> regularity = const [],
}) =>
    Subject(
      id: id,
      academicYearId: yearId,
      academicYear: 2026,
      trackingMode: mode,
      name: 'Materia $id',
      subjectType: SubjectType.mandatory,
      duration: SubjectDuration.annual,
      courseStatus: status,
      gradeMin: 0,
      gradeMax: 10,
      promotionRules: promotion,
      regularityRules: regularity,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
Evaluation evaluation(
  String id,
  String subjectId,
  DateTime date, {
  EvaluationStatus status = EvaluationStatus.pending,
  bool allDay = true,
  double? grade,
}) =>
    Evaluation(
      id: id,
      subjectId: subjectId,
      academicYear: 2026,
      name: 'Evaluación $id',
      type: EvaluationType.partial,
      date: date,
      allDay: allDay,
      mandatory: true,
      countsTowardAverage: true,
      grade: grade,
      maxGrade: 10,
      weight: 1,
      status: status,
      isRecovery: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('selecciona año actual y no inventa uno si no existe', () {
    var data = calculator.calculate(
      subjects: const [],
      evaluations: const [],
      academicYears: [year('old', 2025), year('current', 2026, current: true)],
      profile: null,
      now: now,
    );
    expect(data.selectedYear?.id, 'current');
    data = calculator.calculate(
      subjects: const [],
      evaluations: const [],
      academicYears: [year('old', 2025)],
      profile: null,
      now: now,
    );
    expect(data.selectedYear, isNull);
    expect(data.hasCurrentYear, isFalse);
  });

  test('selector permite revisar otro año sin cambiar current', () {
    final data = calculator.calculate(
      subjects: [subject('old-subject', yearId: 'old')],
      evaluations: const [],
      academicYears: [year('old', 2025), year('current', 2026, current: true)],
      profile: null,
      now: now,
      selectedYearId: 'old',
    );
    expect(data.selectedYear?.id, 'old');
    expect(data.yearSubjects.single.id, 'old-subject');
    expect(data.hasCurrentYear, isTrue);
  });

  test('filtra año, cuenta activas y excluye historical de condición', () {
    final data = calculator.calculate(
      subjects: [
        subject('active'),
        subject('pending', status: CourseStatus.pending),
        subject('history', mode: TrackingMode.historical),
        subject('other', yearId: 'old'),
      ],
      evaluations: const [],
      academicYears: [year('current', 2026, current: true)],
      profile: null,
      now: now,
    );
    expect(data.totalSubjects, 3);
    expect(data.activeSubjectsCount, 1);
    expect(data.noDataCount, 2);
    expect(data.subjectItems, hasLength(2));
  });

  test('cuenta promoting, regular, atRisk y failed con AcademicEngine', () {
    final one = minimumCount(1);
    final two = minimumCount(2);
    final subjects = [
      subject('promoting', promotion: [one]),
      subject('regular', promotion: [two], regularity: [one]),
      subject('risk', regularity: [two]),
      subject('failed', status: CourseStatus.finished, regularity: [two]),
    ];
    final evaluations = [
      for (final item in subjects)
        evaluation('e-${item.id}', item.id, now,
            status: EvaluationStatus.approved, grade: 8),
    ];
    final data = calculator.calculate(
      subjects: subjects,
      evaluations: evaluations,
      academicYears: [year('current', 2026, current: true)],
      profile: null,
      now: now,
    );
    expect(data.promotingCount, 1);
    expect(data.regularCount, 1);
    expect(data.atRiskCount, 1);
    expect(data.failedCount, 1);
    expect(data.attentionItems.first.severity,
        DashboardAttentionSeverity.critical);
    expect(data.attentionItems.where((item) => item.title == 'En riesgo'),
        hasLength(1));
  });

  test('upcoming filtra estado, pasado, huérfanas, ordena y limita a cinco',
      () {
    final dates = List.generate(7, (i) => now.add(Duration(days: 6 - i)));
    final data = calculator.calculate(
      subjects: [subject('s')],
      evaluations: [
        ...dates.map((date) => evaluation('${date.day}', 's', date)),
        evaluation('approved', 's', now.add(const Duration(days: 1)),
            status: EvaluationStatus.approved),
        evaluation('failed', 's', now.add(const Duration(days: 1)),
            status: EvaluationStatus.failed),
        evaluation('past', 's', now.subtract(const Duration(days: 1))),
        evaluation('orphan', 'missing', now.add(const Duration(days: 1))),
      ],
      academicYears: [year('current', 2026, current: true)],
      profile: null,
      now: now,
    );
    expect(data.totalUpcomingEvaluations, 7);
    expect(data.upcomingEvaluations, hasLength(5));
    expect(data.upcomingEvaluations.first.isToday, isTrue);
    expect(data.upcomingEvaluations[1].isTomorrow, isTrue);
    expect(data.upcomingEvaluations.map((item) => item.evaluation.date),
        orderedEquals(dates.reversed.take(5)));
  });

  test('overdue respeta día completo de hoy y estados resueltos', () {
    final data = calculator.calculate(
      subjects: [subject('s')],
      evaluations: [
        evaluation('yesterday', 's', now.subtract(const Duration(days: 1))),
        evaluation('today', 's', DateTime(2026, 8, 15)),
        evaluation(
            'approved-yesterday', 's', now.subtract(const Duration(days: 1)),
            status: EvaluationStatus.approved),
      ],
      academicYears: [year('current', 2026, current: true)],
      profile: null,
      now: now,
    );
    expect(
        data.attentionItems.where((item) => item.evaluationId == 'yesterday'),
        hasLength(1));
    expect(data.attentionItems.where((item) => item.evaluationId == 'today'),
        isEmpty);
    expect(
        data.upcomingEvaluations.where((item) => item.evaluation.id == 'today'),
        hasLength(1));
  });

  test('subject item coincide con calculadores compartidos', () {
    final itemSubject = subject('s', promotion: [minimumCount(1)]);
    final future = evaluation('future', 's', now.add(const Duration(days: 2)));
    final graded = evaluation('graded', 's', now,
        status: EvaluationStatus.approved, grade: 8);
    final data = calculator.calculate(
      subjects: [itemSubject],
      evaluations: [future, graded],
      academicYears: [year('current', 2026, current: true)],
      profile: null,
      now: now,
    );
    expect(data.subjectItems.single.currentAverage, 8);
    expect(data.subjectItems.single.nextEvaluation?.id, 'future');
    expect(data.subjectItems.single.academicResult.condition,
        AcademicCondition.promoting);
  });
}
