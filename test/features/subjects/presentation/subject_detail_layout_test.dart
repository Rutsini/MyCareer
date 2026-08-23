import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:my_career/data/repositories/evaluation_repository.dart';
import 'package:my_career/data/repositories/subject_repository.dart';
import 'package:my_career/domain/entities/academic_rule.dart';
import 'package:my_career/domain/entities/evaluation.dart';
import 'package:my_career/domain/entities/subject.dart';
import 'package:my_career/features/evaluations/application/evaluation_controller.dart';
import 'package:my_career/features/subjects/application/subject_controller.dart';
import 'package:my_career/features/subjects/presentation/screens/subject_detail_screen.dart';

class _Subjects implements SubjectRepository {
  _Subjects(this.subject);
  Subject subject;
  @override
  Stream<List<Subject>> watchSubjects() => Stream.value([subject]);
  @override
  Stream<Subject?> watchSubject(String id) => Stream.value(subject);
  @override
  Future<String> createSubject(Subject subject) async => subject.id;
  @override
  Future<void> updateSubject(Subject value) async => subject = value;
  @override
  Future<void> deleteSubject(String id) async {}
}

class _Evaluations implements EvaluationRepository {
  _Evaluations([this.items = const []]);
  final List<Evaluation> items;
  @override
  Stream<List<Evaluation>> watchEvaluations() => Stream.value(items);
  @override
  Stream<Evaluation?> watchEvaluation(String id) => Stream.value(null);
  @override
  Future<String> createEvaluation(Evaluation evaluation) async => '';
  @override
  Future<void> updateEvaluation(Evaluation evaluation) async {}
  @override
  Future<void> deleteEvaluation(String id) async {}
  @override
  Future<void> deleteEvaluationsBySubject(String subjectId) async {}
}

AcademicRule _rule(String id, int order) => AcademicRule(
    id: id,
    type: AcademicRuleType.minimumApprovedCount,
    name: id,
    order: order,
    config: const MinimumApprovedCountConfig(1));

void main() {
  testWidgets('condiciones largas usan el scroll principal sin altura fija',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final subject = Subject(
        id: 's',
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
        promotionRules: [_rule('Promoción 1', 0), _rule('Promoción 2', 1)],
        regularityRules:
            List.generate(6, (i) => _rule('Regularidad ${i + 1}', i)),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
    final subjects = _Subjects(subject);
    final evaluations = _Evaluations();
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(ProviderScope(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(subjects),
          evaluationRepositoryProvider.overrideWithValue(evaluations),
        ],
        child: const MaterialApp(
            home: Scaffold(body: SubjectDetailScreen(subjectId: 's')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Condiciones'));
    await tester.pumpAndSettle();

    expect(find.byType(TabBarView), findsNothing);
    expect(find.byType(ListView), findsNothing);
    await tester.scrollUntilVisible(find.text('Regularidad 6'), 350,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Regularidad 6').hitTestable(), findsOneWidget);
    expect(errors.where((e) => e.exceptionAsString().contains('overflowed')),
        isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('evaluaciones largas usan el mismo scroll principal',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final subject = Subject(
        id: 's',
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
    final evaluations = _Evaluations(List.generate(
        8,
        (index) => Evaluation(
            id: 'e$index',
            subjectId: 's',
            academicYear: 2026,
            name: 'Evaluación ${index + 1}',
            type: EvaluationType.partial,
            date: DateTime(2026, 1, index + 1),
            allDay: true,
            mandatory: true,
            countsTowardAverage: true,
            grade: 8,
            maxGrade: 10,
            weight: 1,
            status: EvaluationStatus.approved,
            isRecovery: false,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026))));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(_Subjects(subject)),
          evaluationRepositoryProvider.overrideWithValue(evaluations),
        ],
        child: const MaterialApp(
            home: Scaffold(body: SubjectDetailScreen(subjectId: 's')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evaluaciones'));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
    await tester.scrollUntilVisible(find.text('Evaluación 1'), 350,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Evaluación 1').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
