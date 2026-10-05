import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:go_router/go_router.dart';
import 'package:my_career/data/repositories/evaluation_repository.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/features/evaluations/application/evaluation_controller.dart';
import 'package:my_career/features/evaluations/presentation/widgets/evaluation_activity_sheet.dart';

class _Repository implements EvaluationRepository {
  Evaluation? saved;
  int saves = 0;

  @override
  Future<String> createEvaluation(Evaluation evaluation) async => evaluation.id;

  @override
  Future<void> deleteEvaluation(String id) async {}

  @override
  Future<void> updateEvaluation(Evaluation evaluation) async {
    saves++;
    saved = evaluation;
  }

  @override
  Stream<Evaluation?> watchEvaluation(String id) => Stream.value(saved);

  @override
  Stream<List<Evaluation>> watchEvaluations() =>
      Stream.value(saved == null ? const [] : [saved!]);
}

void main() {
  testWidgets('guarda una evaluación pendiente con nota y estado final',
      (tester) async {
    final repository = _Repository();
    await _pumpLauncher(tester, _pending(), repository);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('result-grade-field')), '8,0');
    await tester.ensureVisible(find.byKey(const Key('save-evaluation-result')));
    await tester.tap(find.byKey(const Key('save-evaluation-result')));
    await tester.pumpAndSettle();

    expect(repository.saves, 1);
    expect(repository.saved?.grade, 8);
    expect(repository.saved?.status, EvaluationStatus.approved);
    expect(find.text('Resultado guardado.'), findsOneWidget);
  });

  testWidgets('ausente finaliza sin nota', (tester) async {
    final repository = _Repository();
    await _pumpLauncher(tester, _pending(), repository);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('result-grade-field')), '7');
    await tester.tap(find.text('Aprobada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausente').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-evaluation-result')));
    await tester.tap(find.byKey(const Key('save-evaluation-result')));
    await tester.pumpAndSettle();

    expect(repository.saved?.status, EvaluationStatus.absent);
    expect(repository.saved?.grade, isNull);
  });

  testWidgets('una evaluación realizada muestra detalle de solo lectura',
      (tester) async {
    final repository = _Repository();
    await _pumpLauncher(
      tester,
      _pending().copyWith(status: EvaluationStatus.failed),
      repository,
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('evaluation-read-only-detail')), findsOneWidget);
    expect(find.text('Desaprobada'), findsOneWidget);
    expect(find.byKey(const Key('save-evaluation-result')), findsNothing);
  });

  testWidgets('el detalle navega a la pestaña evaluaciones de la materia',
      (tester) async {
    final repository = _Repository();
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => _Launcher(
          evaluation: _pending().copyWith(
            status: EvaluationStatus.approved,
            grade: 8,
          ),
        ),
      ),
      GoRoute(
        path: '/subjects/:id',
        builder: (_, state) => Scaffold(
          body: Text('tab=${state.uri.queryParameters['tab']}'),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          evaluationControllerProvider
              .overrideWith((_) => EvaluationController(repository)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver evaluaciones de la materia'));
    await tester.tap(find.text('Ver evaluaciones de la materia'));
    await tester.pumpAndSettle();

    expect(find.text('tab=evaluations'), findsOneWidget);
  });

  testWidgets('el panel se adapta a una pantalla móvil', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await _pumpLauncher(tester, _pending(), repository);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('evaluation-result-form')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester,
  Evaluation evaluation,
  _Repository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        evaluationControllerProvider
            .overrideWith((_) => EvaluationController(repository)),
      ],
      child: MaterialApp(home: _Launcher(evaluation: evaluation)),
    ),
  );
  await tester.pumpAndSettle();
}

class _Launcher extends ConsumerWidget {
  const _Launcher({required this.evaluation});

  final Evaluation evaluation;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => openEvaluationActivity(
              context,
              ref,
              evaluation: evaluation,
              subjectName: 'Redes de Datos',
            ),
            child: const Text('Abrir'),
          ),
        ),
      );
}

Evaluation _pending() => Evaluation(
      id: 'evaluation-1',
      subjectId: 'subject-1',
      academicYear: 2026,
      name: 'Parcial 2',
      type: EvaluationType.partial,
      date: DateTime(2026, 8, 28, 18),
      allDay: false,
      mandatory: true,
      countsTowardAverage: true,
      maxGrade: 10,
      weight: 1,
      status: EvaluationStatus.pending,
      isRecovery: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
