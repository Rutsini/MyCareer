import '../entities/academic_year.dart';
import '../entities/evaluation.dart';
import '../entities/subject.dart';
import '../services/academic_engine.dart';
import 'career_progress_summary.dart';

enum DashboardAttentionSeverity { critical, warning, info }

class DashboardSubjectItem {
  const DashboardSubjectItem({
    required this.subject,
    required this.academicResult,
    required this.currentAverage,
    required this.nextEvaluation,
  });

  final Subject subject;
  final AcademicSubjectResult academicResult;
  final double? currentAverage;
  final Evaluation? nextEvaluation;
}

class UpcomingEvaluationItem {
  const UpcomingEvaluationItem({
    required this.evaluation,
    required this.subjectId,
    required this.subjectName,
    required this.subjectShortName,
    required this.daysUntil,
    required this.isToday,
    required this.isTomorrow,
  });

  final Evaluation evaluation;
  final String subjectId;
  final String subjectName;
  final String? subjectShortName;
  final int daysUntil;
  final bool isToday;
  final bool isTomorrow;
}

class DashboardAttentionItem {
  const DashboardAttentionItem({
    required this.subjectId,
    required this.subjectName,
    required this.severity,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.evaluationId,
    this.date,
  });

  final String subjectId;
  final String subjectName;
  final DashboardAttentionSeverity severity;
  final String title;
  final String message;
  final String actionLabel;
  final String? evaluationId;
  final DateTime? date;
}

class DashboardData {
  const DashboardData({
    required this.selectedYear,
    required this.hasAcademicYears,
    required this.hasCurrentYear,
    required this.yearSubjects,
    required this.subjectItems,
    required this.totalSubjects,
    required this.activeSubjectsCount,
    required this.promotingCount,
    required this.regularCount,
    required this.atRiskCount,
    required this.noDataCount,
    required this.failedCount,
    required this.upcomingEvaluations,
    required this.totalUpcomingEvaluations,
    required this.attentionItems,
    required this.totalAttentionItems,
    required this.progress,
    required this.promotionRulesMet,
    required this.promotionRulesTotal,
    required this.regularityRulesMet,
    required this.regularityRulesTotal,
  });

  final AcademicYear? selectedYear;
  final bool hasAcademicYears;
  final bool hasCurrentYear;
  final List<Subject> yearSubjects;
  final List<DashboardSubjectItem> subjectItems;
  final int totalSubjects;
  final int activeSubjectsCount;
  final int promotingCount;
  final int regularCount;
  final int atRiskCount;
  final int noDataCount;
  final int failedCount;
  final List<UpcomingEvaluationItem> upcomingEvaluations;
  final int totalUpcomingEvaluations;
  final List<DashboardAttentionItem> attentionItems;
  final int totalAttentionItems;
  final CareerProgressSummary progress;
  final int promotionRulesMet;
  final int promotionRulesTotal;
  final int regularityRulesMet;
  final int regularityRulesTotal;
}
