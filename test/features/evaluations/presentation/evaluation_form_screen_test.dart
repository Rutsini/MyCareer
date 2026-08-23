import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:go_router/go_router.dart';
import 'package:my_career/app/theme/app_theme.dart';
import 'package:my_career/data/repositories/evaluation_repository.dart';
import 'package:my_career/data/repositories/subject_repository.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/entities/user_profile.dart';
import 'package:my_career/features/evaluations/application/evaluation_controller.dart';
import 'package:my_career/features/evaluations/presentation/screens/evaluation_form_screen.dart';
import 'package:my_career/features/profile/application/profile_controller.dart';
import 'package:my_career/features/subjects/application/subject_controller.dart';

class _Subjects implements SubjectRepository {
  final subject = Subject(
      id: 'subject-1',
      academicYearId: '2026',
      academicYear: 2026,
      trackingMode: TrackingMode.tracked,
      name: 'Redes',
      subjectType: SubjectType.mandatory,
      duration: SubjectDuration.annual,
      courseStatus: CourseStatus.active,
      currentCondition: AcademicCondition.noData,
      gradeMin: 0,
      gradeMax: 10,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026));
  @override
  Stream<List<Subject>> watchSubjects() => Stream.value([subject]);
  @override
  Stream<Subject?> watchSubject(String id) => Stream.value(subject);
  @override
  Future<String> createSubject(Subject subject) async => '';
  @override
  Future<void> updateSubject(Subject subject) async {}
  @override
  Future<void> deleteSubject(String id) async {}
}

class _Evaluations implements EvaluationRepository {
  _Evaluations({this.existing, this.delay = Duration.zero});
  final Evaluation? existing;
  final Duration delay;
  int createCalls = 0;
  int updateCalls = 0;
  @override
  Stream<List<Evaluation>> watchEvaluations() => Stream.value(const []);
  @override
  Stream<Evaluation?> watchEvaluation(String id) => Stream.value(existing);
  @override
  Future<String> createEvaluation(Evaluation evaluation) async {
    createCalls++;
    await Future<void>.delayed(delay);
    return 'evaluation-1';
  }

  @override
  Future<void> updateEvaluation(Evaluation evaluation) async {
    updateCalls++;
  }

  @override
  Future<void> deleteEvaluation(String id) async {}
  @override
  Future<void> deleteEvaluationsBySubject(String subjectId) async {}
}

void main() {
  testWidgets(
      '/evaluations/new tiene Material y selector interactivo en mobile',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final subjects = _Subjects();
    final evaluations = _Evaluations();
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    final router = GoRouter(initialLocation: '/evaluations/new', routes: [
      GoRoute(
          path: '/evaluations/new',
          builder: (_, __) => const EvaluationFormScreen()),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(overrides: [
      subjectRepositoryProvider.overrideWithValue(subjects),
      evaluationRepositoryProvider.overrideWithValue(evaluations),
      userProfileProvider.overrideWith(
          (_) => Stream.value(const UserProfile(id: 'u', email: 'u@test.com'))),
    ], child: MaterialApp.router(theme: AppTheme.light, routerConfig: router)));
    await tester.pumpAndSettle();

    expect(find.text('Nueva evaluación'), findsOneWidget);
    expect(find.text('Materia *'), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Redes'), findsOneWidget);
    expect(
        errors.where(
            (e) => e.exceptionAsString().contains('No Material widget found')),
        isEmpty);
    expect(errors.where((e) => e.exceptionAsString().contains('overflowed')),
        isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ruta directa guarda una vez y navega al detalle de materia',
      (tester) async {
    final repository = _Evaluations(delay: const Duration(milliseconds: 50));
    final router = _router('/evaluations/new?subjectId=subject-1');
    addTearDown(router.dispose);
    await _pump(tester, router, repository);

    await tester.enterText(find.byType(TextFormField).first, 'Parcial 1');
    final save = find.widgetWithText(FilledButton, 'Guardar');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(
        router.routeInformationProvider.value.uri.path, '/subjects/subject-1');
    expect(find.text('Detalle: subject-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ruta directa sin origen usa la materia seleccionada al guardar',
      (tester) async {
    final repository = _Evaluations();
    final router = _router('/evaluations/new');
    addTearDown(router.dispose);
    await _pump(tester, router, repository);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redes').last);
    await tester.enterText(find.byType(TextFormField).first, 'Parcial 1');
    final save = find.widgetWithText(FilledButton, 'Guardar');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(
        router.routeInformationProvider.value.uri.path, '/subjects/subject-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('edición directa sin stack navega al detalle de materia',
      (tester) async {
    final existing = Evaluation(
        id: 'evaluation-1',
        subjectId: 'subject-1',
        academicYear: 2026,
        name: 'Parcial 1',
        type: EvaluationType.partial,
        date: DateTime(2026, 8, 23),
        allDay: true,
        mandatory: true,
        countsTowardAverage: true,
        maxGrade: 10,
        weight: 1,
        status: EvaluationStatus.pending,
        isRecovery: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
    final repository = _Evaluations(existing: existing);
    final router = _router('/evaluations/evaluation-1/edit');
    addTearDown(router.dispose);
    await _pump(tester, router, repository);

    final save = find.widgetWithText(FilledButton, 'Guardar');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(
        router.routeInformationProvider.value.uri.path, '/subjects/subject-1');
    expect(tester.takeException(), isNull);
  });
}

GoRouter _router(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/evaluations/new',
          builder: (_, state) => EvaluationFormScreen(
            subjectId: state.uri.queryParameters['subjectId'],
          ),
        ),
        GoRoute(
          path: '/evaluations/:id/edit',
          builder: (_, state) => EvaluationFormScreen(
            evaluationId: state.pathParameters['id'],
          ),
        ),
        GoRoute(
          path: '/subjects/:id',
          builder: (_, state) => Scaffold(
            body: Text('Detalle: ${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: '/calendar',
          builder: (_, __) => const Scaffold(body: Text('Calendario')),
        ),
      ],
    );

Future<void> _pump(
    WidgetTester tester, GoRouter router, _Evaluations evaluations) async {
  final subjects = _Subjects();
  await tester.pumpWidget(ProviderScope(overrides: [
    subjectRepositoryProvider.overrideWithValue(subjects),
    evaluationRepositoryProvider.overrideWithValue(evaluations),
    evaluationControllerProvider
        .overrideWith((_) => EvaluationController(evaluations)),
    userProfileProvider.overrideWith(
        (_) => Stream.value(const UserProfile(id: 'u', email: 'u@test.com'))),
  ], child: MaterialApp.router(theme: AppTheme.light, routerConfig: router)));
  await tester.pumpAndSettle();
}
