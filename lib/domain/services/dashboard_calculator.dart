import '../entities/academic_year.dart';
import '../entities/evaluation.dart';
import '../entities/subject.dart';
import '../entities/user_profile.dart';
import '../models/dashboard_data.dart';
import 'academic_engine.dart';
import 'career_progress_calculator.dart';
import 'evaluation_calculator.dart';

class DashboardCalculator {
  const DashboardCalculator({this.academicEngine = const AcademicEngine()});

  final AcademicEngine academicEngine;

  DashboardData calculate({
    required List<Subject> subjects,
    required List<Evaluation> evaluations,
    required List<AcademicYear> academicYears,
    required UserProfile? profile,
    required DateTime now,
    String? selectedYearId,
  }) {
    final currentYears = academicYears.where((year) => year.isCurrent).toList();
    final currentYear = currentYears.isEmpty ? null : currentYears.first;
    AcademicYear? selectedYear;
    if (selectedYearId != null) {
      selectedYear =
          academicYears.where((year) => year.id == selectedYearId).firstOrNull;
    } else {
      selectedYear = currentYear;
    }

    final progress =
        CareerProgressCalculator.calculate(subjects, profile: profile);
    if (selectedYear == null) {
      return DashboardData(
        selectedYear: null,
        hasAcademicYears: academicYears.isNotEmpty,
        hasCurrentYear: currentYear != null,
        yearSubjects: const [],
        subjectItems: const [],
        totalSubjects: 0,
        activeSubjectsCount: 0,
        promotingCount: 0,
        regularCount: 0,
        atRiskCount: 0,
        noDataCount: 0,
        failedCount: 0,
        upcomingEvaluations: const [],
        totalUpcomingEvaluations: 0,
        attentionItems: const [],
        totalAttentionItems: 0,
        progress: progress,
        promotionRulesMet: 0,
        promotionRulesTotal: 0,
        regularityRulesMet: 0,
        regularityRulesTotal: 0,
      );
    }

    final yearSubjects = subjects
        .where((subject) => subject.academicYearId == selectedYear!.id)
        .toList();
    final subjectById = {
      for (final subject in yearSubjects) subject.id: subject
    };
    final evaluationsBySubject = <String, List<Evaluation>>{};
    for (final evaluation in evaluations) {
      if (!subjectById.containsKey(evaluation.subjectId)) continue;
      evaluationsBySubject
          .putIfAbsent(evaluation.subjectId, () => [])
          .add(evaluation);
    }

    final tracked = yearSubjects
        .where((subject) => subject.trackingMode == TrackingMode.tracked)
        .toList();
    final items = tracked.map((subject) {
      final subjectEvaluations = evaluationsBySubject[subject.id] ?? const [];
      return DashboardSubjectItem(
        subject: subject,
        academicResult: academicEngine.evaluate(
          subject: subject,
          evaluations: subjectEvaluations,
        ),
        currentAverage:
            EvaluationCalculator.currentAverage(subject, subjectEvaluations),
        nextEvaluation: EvaluationCalculator.nextEvaluation(
          subjectEvaluations,
          subjectId: subject.id,
          now: startOfDay(now),
        ),
      );
    }).toList();

    int count(AcademicCondition condition) => items
        .where((item) => item.academicResult.condition == condition)
        .length;
    final activeItems = items
        .where((item) => item.subject.courseStatus == CourseStatus.active)
        .toList();

    final allUpcoming = <UpcomingEvaluationItem>[];
    final attention = <DashboardAttentionItem>[];
    for (final item in items) {
      final condition = item.academicResult.condition;
      if (condition == AcademicCondition.atRisk ||
          condition == AcademicCondition.failed) {
        final results = [
          ...item.academicResult.regularityResults,
          ...item.academicResult.promotionResults,
        ];
        final issue = results
            .where((result) => result.status == RuleResultStatus.unmet)
            .firstOrNull;
        attention.add(DashboardAttentionItem(
          subjectId: item.subject.id,
          subjectName: item.subject.name,
          severity: condition == AcademicCondition.failed
              ? DashboardAttentionSeverity.critical
              : DashboardAttentionSeverity.warning,
          title: condition == AcademicCondition.failed
              ? 'No regularizó'
              : 'En riesgo',
          message: issue?.message ?? item.academicResult.summary,
          actionLabel: 'Ver condiciones',
        ));
      } else if (condition == AcademicCondition.noData &&
          item.subject.courseStatus == CourseStatus.active &&
          !item.academicResult.promotionConfigured &&
          !item.academicResult.regularityConfigured) {
        attention.add(DashboardAttentionItem(
          subjectId: item.subject.id,
          subjectName: item.subject.name,
          severity: DashboardAttentionSeverity.info,
          title: 'Condiciones sin configurar',
          message: 'Configurá las reglas para calcular tu condición académica.',
          actionLabel: 'Configurar reglas',
        ));
      }

      for (final evaluation
          in evaluationsBySubject[item.subject.id] ?? const []) {
        if (evaluation.status != EvaluationStatus.pending) continue;
        if (isOverdue(evaluation, now)) {
          attention.add(DashboardAttentionItem(
            subjectId: item.subject.id,
            subjectName: item.subject.name,
            severity: DashboardAttentionSeverity.warning,
            title: evaluation.name,
            message: 'Esta evaluación ya pasó y todavía figura como pendiente.',
            actionLabel: 'Actualizar evaluación',
            evaluationId: evaluation.id,
            date: evaluation.date,
          ));
        } else if (!evaluation.date.isBefore(startOfDay(now))) {
          final days = daysUntil(evaluation.date, now);
          allUpcoming.add(UpcomingEvaluationItem(
            evaluation: evaluation,
            subjectId: item.subject.id,
            subjectName: item.subject.name,
            subjectShortName: item.subject.shortName,
            daysUntil: days,
            isToday: days == 0,
            isTomorrow: days == 1,
          ));
        }
      }
    }

    allUpcoming.sort((a, b) {
      final date = a.evaluation.date.compareTo(b.evaluation.date);
      return date != 0 ? date : a.evaluation.id.compareTo(b.evaluation.id);
    });
    attention.sort((a, b) {
      final severity = a.severity.index.compareTo(b.severity.index);
      if (severity != 0) return severity;
      final aDate = a.date ?? DateTime(9999);
      final bDate = b.date ?? DateTime(9999);
      final date = aDate.compareTo(bDate);
      return date != 0 ? date : a.subjectName.compareTo(b.subjectName);
    });
    const conditionOrder = {
      AcademicCondition.atRisk: 0,
      AcademicCondition.failed: 1,
      AcademicCondition.promoting: 2,
      AcademicCondition.regular: 3,
      AcademicCondition.noData: 4,
    };
    items.sort((a, b) {
      final condition = (conditionOrder[a.academicResult.condition] ?? 5)
          .compareTo(conditionOrder[b.academicResult.condition] ?? 5);
      return condition != 0
          ? condition
          : a.subject.name.compareTo(b.subject.name);
    });

    final promotionResults = activeItems
        .expand((item) => item.academicResult.promotionResults)
        .toList();
    final regularityResults = activeItems
        .expand((item) => item.academicResult.regularityResults)
        .toList();

    return DashboardData(
      selectedYear: selectedYear,
      hasAcademicYears: true,
      hasCurrentYear: currentYear != null,
      yearSubjects: List.unmodifiable(yearSubjects),
      subjectItems: List.unmodifiable(items),
      totalSubjects: yearSubjects.length,
      activeSubjectsCount: activeItems.length,
      promotingCount: count(AcademicCondition.promoting),
      regularCount: count(AcademicCondition.regular),
      atRiskCount: count(AcademicCondition.atRisk),
      noDataCount: count(AcademicCondition.noData),
      failedCount: count(AcademicCondition.failed),
      upcomingEvaluations: List.unmodifiable(allUpcoming.take(5)),
      totalUpcomingEvaluations: allUpcoming.length,
      attentionItems: List.unmodifiable(attention.take(6)),
      totalAttentionItems: attention.length,
      progress: progress,
      promotionRulesMet: promotionResults
          .where((result) => result.status == RuleResultStatus.met)
          .length,
      promotionRulesTotal: promotionResults.length,
      regularityRulesMet: regularityResults
          .where((result) => result.status == RuleResultStatus.met)
          .length,
      regularityRulesTotal: regularityResults.length,
    );
  }

  static DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int daysUntil(DateTime date, DateTime now) =>
      startOfDay(date).difference(startOfDay(now)).inDays;

  static bool isToday(DateTime date, DateTime now) => daysUntil(date, now) == 0;

  static bool isTomorrow(DateTime date, DateTime now) =>
      daysUntil(date, now) == 1;

  static bool isOverdue(Evaluation evaluation, DateTime now) =>
      evaluation.allDay
          ? evaluation.date.isBefore(startOfDay(now))
          : evaluation.date.isBefore(now);
}
