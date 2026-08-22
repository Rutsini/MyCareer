import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:go_router/go_router.dart';
import 'package:my_career/app/theme/app_theme.dart';
import 'package:my_career/data/repositories/evaluation_repository.dart';
import 'package:my_career/data/repositories/subject_repository.dart';
import 'package:my_career/domain/entities/academic_year.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/domain/entities/user_profile.dart';
import 'package:my_career/features/evaluations/application/evaluation_controller.dart';
import 'package:my_career/features/profile/application/profile_controller.dart';
import 'package:my_career/features/subjects/application/academic_year_controller.dart';
import 'package:my_career/features/subjects/application/subject_controller.dart';
import 'package:my_career/features/subjects/presentation/screens/subject_detail_screen.dart';
import 'package:my_career/features/subjects/presentation/screens/subject_form_screen.dart';

class _SubjectRepository implements SubjectRepository {
  final subjects = <String, Subject>{};
  var createCalls = 0;

  @override
  Future<String> createSubject(Subject subject) async {
    createCalls++;
    const id = 'created-subject';
    subjects[id] = subject.copyWith(id: id);
    return id;
  }

  @override
  Stream<Subject?> watchSubject(String id) async* {
    yield subjects[id];
  }

  @override
  Stream<List<Subject>> watchSubjects() async* {
    yield subjects.values.toList();
  }

  @override
  Future<void> deleteSubject(String id) async => subjects.remove(id);

  @override
  Future<void> updateSubject(Subject subject) async {
    subjects[subject.id] = subject;
  }
}

class _EvaluationRepository implements EvaluationRepository {
  @override
  Stream<List<Evaluation>> watchEvaluations() async* {
    yield const <Evaluation>[];
  }

  @override
  Stream<Evaluation?> watchEvaluation(String id) async* {
    yield null;
  }

  @override
  Future<String> createEvaluation(Evaluation evaluation) async => '';

  @override
  Future<void> deleteEvaluation(String id) async {}

  @override
  Future<void> deleteEvaluationsBySubject(String subjectId) async {}

  @override
  Future<void> updateEvaluation(Evaluation evaluation) async {}
}

void main() {
  testWidgets('crear materia navega y renderiza el detalle en mobile',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final subjects = _SubjectRepository();
    final evaluations = _EvaluationRepository();
    final router = GoRouter(
      initialLocation: '/new',
      routes: [
        GoRoute(
          path: '/new',
          builder: (_, __) => const Scaffold(
            body: SubjectFormScreen(mode: TrackingMode.tracked),
          ),
        ),
        GoRoute(
          path: '/subjects/:subjectId',
          builder: (_, state) => Scaffold(
            body: SubjectDetailScreen(
              subjectId: state.pathParameters['subjectId']!,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        academicYearsProvider.overrideWith((_) => Stream.value([
              AcademicYear(
                id: '2026',
                year: 2026,
                isCurrent: true,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ])),
        userProfileProvider.overrideWith((_) => Stream.value(const UserProfile(
              id: 'user',
              email: 'test@example.com',
            ))),
        subjectRepositoryProvider.overrideWithValue(subjects),
        evaluationRepositoryProvider.overrideWithValue(evaluations),
        subjectControllerProvider.overrideWith(
          (_) => SubjectController(subjects, evaluations),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nombre *'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Redes de Datos');
    await tester.tap(find.text('Continuar').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Duración'), findsOneWidget);
    await tester.tap(find.text('Opciones avanzadas'));
    await tester.pumpAndSettle();
    expect(find.text('Nota mínima'), findsOneWidget);
    expect(find.text('Nota máxima'), findsOneWidget);
    expect(find.text('Política de recuperatorios'), findsOneWidget);

    await tester.tap(find.text('Continuar').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Crear materia').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Crear materia').hitTestable());
    await tester.pumpAndSettle();

    expect(subjects.createCalls, 1);
    expect(router.routeInformationProvider.value.uri.path,
        '/subjects/created-subject');
    expect(find.text('Redes de Datos'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Evaluación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
