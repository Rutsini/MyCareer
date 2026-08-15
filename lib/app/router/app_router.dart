import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/subjects/presentation/screens/subjects_screen.dart';
import '../../features/subjects/presentation/screens/subject_detail_screen.dart';
import '../../features/subjects/presentation/screens/subject_form_screen.dart';
import '../../features/subjects/presentation/screens/subject_type_screen.dart';
import '../../domain/entities/subject.dart';
import 'app_routes.dart';
import 'router_refresh_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final refresh = RouterRefreshNotifier(repository.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authenticated = repository.currentUser != null;
      final authRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      if (!authenticated && !authRoute) return AppRoutes.login;
      if (authenticated && authRoute) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.subjects,
              builder: (context, state) => const SubjectsScreen(),
              routes: [
                GoRoute(
                    path: 'new',
                    builder: (context, state) => const SubjectTypeScreen(),
                    routes: [
                      GoRoute(
                          path: 'current',
                          builder: (context, state) => const SubjectFormScreen(
                              mode: TrackingMode.tracked)),
                      GoRoute(
                          path: 'historical',
                          builder: (context, state) => const SubjectFormScreen(
                              mode: TrackingMode.historical)),
                    ]),
                GoRoute(
                    path: ':subjectId',
                    builder: (context, state) => SubjectDetailScreen(
                        subjectId: state.pathParameters['subjectId']!),
                    routes: [
                      GoRoute(
                          path: 'edit',
                          builder: (context, state) => SubjectFormScreen(
                              subjectId: state.pathParameters['subjectId']!)),
                    ]),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, state) => const CalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, state) => const ProgressScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
