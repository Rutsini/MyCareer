// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/academic_year.dart';
import '../../../../domain/entities/subject.dart';
import '../../../../domain/services/evaluation_calculator.dart';
import '../../../evaluations/application/evaluation_controller.dart';
import '../../application/academic_year_controller.dart';
import '../../application/subject_controller.dart';

enum _Filter { all, annual, first, second, elective }

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});
  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  String _search = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    return ContentPage(
      title: 'Materias',
      child: yearsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('No pudimos cargar los años académicos.'),
        data: (years) {
          if (years.isEmpty)
            return _NoYears(onCreate: () => _createYear(context));
          var selected = ref.watch(selectedYearIdProvider);
          if (!years.any((year) => year.id == selected)) {
            selected = (years.where((year) => year.isCurrent).firstOrNull ??
                    years.first)
                .id;
            Future.microtask(() =>
                ref.read(selectedYearIdProvider.notifier).state = selected);
          }
          final selectedId = selected;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  DropdownButton<String>(
                    value: selectedId,
                    items: years
                        .map((year) => DropdownMenuItem(
                            value: year.id,
                            child: Text(
                                'Año ${year.year}${year.isCurrent ? ' · Actual' : ''}')))
                        .toList(),
                    onChanged: (value) =>
                        ref.read(selectedYearIdProvider.notifier).state = value,
                  ),
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                        onPressed: () => _manageYears(context, years),
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Gestionar años')),
                    FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.newSubject),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva materia')),
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar materia...'),
                  onChanged: (value) =>
                      setState(() => _search = value.trim().toLowerCase())),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 8,
                  children: _Filter.values
                      .map((filter) => FilterChip(
                          label: Text(_filterLabel(filter)),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter)))
                      .toList()),
              const SizedBox(height: 16),
              subjectsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('No pudimos cargar tus materias.'),
                data: (all) {
                  final items = all
                      .where((subject) => subject.academicYearId == selectedId)
                      .where(_matches)
                      .toList();
                  if (items.isEmpty)
                    return _empty(
                        years.firstWhere((year) => year.id == selectedId).year);
                  return LayoutBuilder(
                      builder: (context, constraints) => GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        constraints.maxWidth > 700 ? 2 : 1,
                                    childAspectRatio:
                                        constraints.maxWidth > 700 ? 1.65 : 1.9,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12),
                            itemCount: items.length,
                            itemBuilder: (_, index) => _SubjectCard(
                                subject: items[index],
                                onDelete: () => _delete(context, items[index])),
                          ));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(int year) => Card(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Icon(Icons.menu_book_outlined, size: 40),
            const SizedBox(height: 12),
            Text(_search.isEmpty && _filter == _Filter.all
                ? 'Todavía no tenés materias en $year.'
                : 'No encontramos materias con esos filtros.'),
            const SizedBox(height: 8),
            const Text('Cargá tu primera materia para comenzar.'),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: () => context.go(AppRoutes.newSubject),
                icon: const Icon(Icons.add),
                label: const Text('Nueva materia'))
          ])));
  bool _matches(Subject subject) {
    final text =
        '${subject.name} ${subject.shortName ?? ''} ${subject.code ?? ''} ${subject.commission ?? ''}'
            .toLowerCase();
    if (!text.contains(_search)) return false;
    return switch (_filter) {
      _Filter.all => true,
      _Filter.annual => subject.duration == SubjectDuration.annual,
      _Filter.first => subject.semester == Semester.first,
      _Filter.second => subject.semester == Semester.second,
      _Filter.elective => subject.subjectType == SubjectType.elective
    };
  }

  String _filterLabel(_Filter filter) => switch (filter) {
        _Filter.all => 'Todas',
        _Filter.annual => 'Anuales',
        _Filter.first => '1°C',
        _Filter.second => '2°C',
        _Filter.elective => 'Electivas'
      };

  Future<void> _createYear(BuildContext context) async {
    final input = TextEditingController();
    final year = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Crear año académico'),
                content: TextField(
                    controller: input,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Año')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(
                          dialogContext, int.tryParse(input.text)),
                      child: const Text('Crear'))
                ]));
    input.dispose();
    if (year != null && year >= 1900 && year <= 2200)
      await ref
          .read(academicYearControllerProvider.notifier)
          .create(year, current: true);
  }

  Future<void> _manageYears(BuildContext context, List<AcademicYear> years) =>
      showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: const Text('Años académicos'),
                content: SizedBox(
                    width: 420,
                    child: ListView(
                        shrinkWrap: true,
                        children: years
                            .map((year) => ListTile(
                                  leading: Icon(year.isCurrent
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off),
                                  title: Text('${year.year}'),
                                  subtitle: Text(
                                      year.isCurrent ? 'Año actual' : year.id),
                                  onTap: () async {
                                    await ref
                                        .read(academicYearControllerProvider
                                            .notifier)
                                        .setCurrent(year.id);
                                    if (dialogContext.mounted)
                                      Navigator.pop(dialogContext);
                                  },
                                  trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        final deleted = await ref
                                            .read(academicYearControllerProvider
                                                .notifier)
                                            .delete(year.id);
                                        if (dialogContext.mounted &&
                                            deleted == true)
                                          Navigator.pop(dialogContext);
                                        if (context.mounted && deleted == null)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'No podés eliminar un año que tiene materias.')));
                                      }),
                                ))
                            .toList())),
                actions: [
                  TextButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _createYear(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear año')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cerrar'))
                ],
              ));
  Future<void> _delete(BuildContext context, Subject subject) async {
    final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
                    title: Text('¿Eliminar "${subject.name}"?'),
                    content: Text(
                        'También se eliminarán sus evaluaciones asociadas.\n\nEsta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Eliminar'))
                    ])) ??
        false;
    if (confirmed)
      await ref.read(subjectControllerProvider.notifier).delete(subject.id);
  }
}

class _NoYears extends StatelessWidget {
  const _NoYears({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Text('Todavía no tenés años académicos.'),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Crear año académico'))
          ])));
}

class _SubjectCard extends ConsumerWidget {
  const _SubjectCard({required this.subject, required this.onDelete});
  final Subject subject;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historical = subject.trackingMode == TrackingMode.historical;
    final evaluations =
        ref.watch(subjectEvaluationsProvider(subject.id)).valueOrNull ??
            const [];
    final average = historical
        ? null
        : EvaluationCalculator.currentAverage(subject, evaluations);
    final next = historical
        ? null
        : EvaluationCalculator.nextEvaluation(evaluations,
            subjectId: subject.id);
    return Card(
        child: InkWell(
            onTap: () => context.go(AppRoutes.subject(subject.id)),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(subject.name.toUpperCase(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'open')
                                context.go(AppRoutes.subject(subject.id));
                              if (value == 'edit')
                                context.go(AppRoutes.editSubject(subject.id));
                              if (value == 'delete') onDelete();
                            },
                            itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'open', child: Text('Abrir')),
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Editar')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Eliminar'))
                                ])
                      ]),
                      if (subject.shortName != null) Text(subject.shortName!),
                      const SizedBox(height: 8),
                      Text(
                          '${historical ? '${subject.academicYear} · ' : ''}${_duration(subject)} · ${subject.subjectType == SubjectType.mandatory ? 'Obligatoria' : 'Electiva'}'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Icon(historical ? Icons.circle : Icons.circle_outlined,
                            size: 14,
                            color: historical ? Colors.blue : Colors.grey),
                        const SizedBox(width: 6),
                        Text(historical
                            ? _outcome(subject.finalOutcome)
                            : 'Sin datos')
                      ]),
                      const Spacer(),
                      Text(historical ? 'Nota final' : 'Promedio actual',
                          style: Theme.of(context).textTheme.labelMedium),
                      Text(
                          historical
                              ? (subject.finalGrade?.toString() ?? '—')
                              : (average
                                      ?.toStringAsFixed(2)
                                      .replaceAll('.', ',') ??
                                  '—'),
                          style: Theme.of(context).textTheme.titleLarge),
                      if (!historical)
                        Text(next == null
                            ? 'Próxima evaluación  —'
                            : 'Próxima evaluación  ${next.date.day}/${next.date.month} · ${next.name}')
                    ]))));
  }

  String _duration(Subject subject) =>
      subject.duration == SubjectDuration.annual
          ? 'Anual'
          : subject.semester == Semester.first
              ? '1°C'
              : '2°C';
  String _outcome(FinalOutcome? value) => switch (value) {
        FinalOutcome.approved => 'Aprobada',
        FinalOutcome.promoted => 'Promocionada',
        FinalOutcome.regularized => 'Regularizada',
        FinalOutcome.failed => 'Desaprobada',
        FinalOutcome.abandoned => 'Abandonada',
        null => 'Sin resultado'
      };
}
