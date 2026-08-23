import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/domain/entities/academic_year.dart';
import 'package:my_career/domain/entities/user_profile.dart';
import 'package:my_career/domain/models/career_progress_summary.dart';
import 'package:my_career/domain/models/dashboard_data.dart';
import 'package:my_career/features/dashboard/application/dashboard_controller.dart';
import 'package:my_career/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:my_career/features/profile/application/profile_controller.dart';
import 'package:my_career/features/subjects/application/academic_year_controller.dart';

void main() {
  testWidgets('acciones rápidas aparecen arriba y no duplican navegación',
      (tester) async {
    final year = AcademicYear(
        id: '2026',
        year: 2026,
        isCurrent: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
    final data = DashboardData(
        selectedYear: year,
        hasAcademicYears: true,
        hasCurrentYear: true,
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
        progress: const CareerProgressSummary(
            generalAverage: null,
            electiveObtained: 0,
            electiveInProgress: 0,
            electiveRequired: null),
        promotionRulesMet: 0,
        promotionRulesTotal: 0,
        regularityRulesMet: 0,
        regularityRulesTotal: 0);
    await tester.pumpWidget(ProviderScope(overrides: [
      dashboardDataProvider.overrideWithValue(AsyncData(data)),
      academicYearsProvider.overrideWith((_) => Stream.value([year])),
      userProfileProvider.overrideWith((_) => Stream.value(const UserProfile(
          id: 'u', email: 'u@test.com', displayName: 'Maximo'))),
    ], child: const MaterialApp(home: Scaffold(body: DashboardScreen()))));
    await tester.pumpAndSettle();

    expect(find.text('Acciones rápidas'), findsOneWidget);
    expect(find.text('Nueva materia'), findsWidgets);
    expect(find.text('Nueva evaluación'), findsOneWidget);
    final quick = find.byKey(const Key('quick-actions'));
    expect(find.descendant(of: quick, matching: find.text('Calendario')),
        findsNothing);
    expect(find.descendant(of: quick, matching: find.text('Progreso')),
        findsNothing);
    expect(tester.getTopLeft(find.text('Acciones rápidas')).dy,
        lessThan(tester.getTopLeft(find.text('Próximas evaluaciones')).dy));
  });
}
