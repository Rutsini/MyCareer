import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/dashboard_data.dart';
import '../../../domain/services/dashboard_calculator.dart';
import '../../evaluations/application/evaluation_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../subjects/application/academic_controller.dart';
import '../../subjects/application/academic_year_controller.dart';
import '../../subjects/application/subject_controller.dart';

final dashboardYearIdProvider = StateProvider<String?>((ref) => null);
final dashboardNowProvider = Provider<DateTime>((ref) => DateTime.now());
final dashboardCalculatorProvider = Provider(
  (ref) => DashboardCalculator(
    academicEngine: ref.watch(academicEngineProvider),
  ),
);

final dashboardDataProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final years = ref.watch(academicYearsProvider);
  final subjects = ref.watch(subjectsProvider);
  final evaluations = ref.watch(evaluationsProvider);
  final profile = ref.watch(userProfileProvider);

  if (years.hasError) return AsyncError(years.error!, years.stackTrace!);
  if (subjects.hasError) {
    return AsyncError(subjects.error!, subjects.stackTrace!);
  }
  if (evaluations.hasError) {
    return AsyncError(evaluations.error!, evaluations.stackTrace!);
  }
  if (years.isLoading || subjects.isLoading || evaluations.isLoading) {
    return const AsyncLoading();
  }

  return AsyncData(ref.watch(dashboardCalculatorProvider).calculate(
        subjects: subjects.requireValue,
        evaluations: evaluations.requireValue,
        academicYears: years.requireValue,
        profile: profile.valueOrNull,
        now: ref.watch(dashboardNowProvider),
        selectedYearId: ref.watch(dashboardYearIdProvider),
      ));
});
