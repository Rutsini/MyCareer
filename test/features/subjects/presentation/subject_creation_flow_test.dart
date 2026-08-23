import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:go_router/go_router.dart';
import 'package:my_career/app/theme/app_theme.dart';
import 'package:my_career/data/repositories/evaluation_repository.dart';
import 'package:my_career/data/repositories/subject_repository.dart';
import 'package:my_career/domain/entities/academic_year.dart';
import 'package:my_career/domain/entities/academic_rule.dart';
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
  _EvaluationRepository(this.items);
  final List<Evaluation> items;

  @override
  Stream<List<Evaluation>> watchEvaluations() async* {
    yield items;
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
    final evaluations = _EvaluationRepository([
      Evaluation(
        id: 'evaluation-1',
        subjectId: 'created-subject',
        academicYear: 2026,
        name: 'Parcial 1',
        type: EvaluationType.partial,
        date: DateTime(2026, 8, 20),
        allDay: true,
        mandatory: true,
        countsTowardAverage: true,
        grade: 10,
        maxGrade: 10,
        weight: 1,
        status: EvaluationStatus.approved,
        isRecovery: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);
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
    expect(find.text('Condiciones de promoción'), findsOneWidget);
    expect(find.text('Condiciones de regularidad'), findsOneWidget);
    await tester.tap(find.text('Agregar condición').first);
    await tester.pumpAndSettle();
    expect(find.text('Tipo de condición'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Descripción (opcional)'), findsOneWidget);
    expect(find.text('Promedio requerido'), findsOneWidget);
    expect(find.text('Habilitada'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Exige alcanzar un promedio mínimo entre las evaluaciones consideradas.'),
        findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '7');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Promedio mínimo'), findsWidgets);
    await tester.dragUntilVisible(find.text('Revisión'),
        find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.tap(find.text('Revisión').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Crear materia').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Crear materia').hitTestable());
    await tester.pumpAndSettle();

    expect(subjects.createCalls, 1);
    final saved = subjects.subjects['created-subject']!;
    expect(saved.promotionRules, hasLength(1));
    expect(saved.promotionRules.single.config, isA<MinimumAverageConfig>());
    expect(
        (saved.promotionRules.single.config as MinimumAverageConfig)
            .minimumAverage,
        7);
    expect(saved.regularityRules, isEmpty);
    expect(router.routeInformationProvider.value.uri.path,
        '/subjects/created-subject');
    expect(find.text('Redes de Datos'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Evaluación'), findsOneWidget);
    await tester.tap(find.text('Evaluaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Nota: 10 / 10'), findsOneWidget);
    expect(find.text('10 / 10'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
