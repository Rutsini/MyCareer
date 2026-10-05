import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../../domain/entities/subject.dart';
import '../../../../domain/entities/todo_activity.dart';
import '../../../activities/application/todo_activity_controller.dart';
import '../../../activities/presentation/todo_activity_form.dart';
import '../../../evaluations/application/evaluation_controller.dart';
import '../../../subjects/application/subject_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final evaluations = ref.watch(evaluationsProvider);
    final activities = ref.watch(todoActivitiesProvider);
    final subjects = ref.watch(subjectsProvider);
    return ContentPage(
      title: 'Calendario',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DefaultTabController(
            length: 3,
            initialIndex: _tabIndex,
            child: TabBar(
              onTap: (index) => setState(() => _tabIndex = index),
              tabs: const [
                Tab(text: 'Calendario'),
                Tab(text: 'Lista'),
                Tab(text: 'Actividades'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTab(evaluations, activities, subjects),
        ],
      ),
    );
  }

  Widget _buildTab(
    AsyncValue<List<Evaluation>> evaluations,
    AsyncValue<List<TodoActivity>> activities,
    AsyncValue<List<Subject>> subjects,
  ) {
    if (evaluations.isLoading || activities.isLoading || subjects.isLoading) {
      return const LinearProgressIndicator();
    }
    if (evaluations.hasError || activities.hasError || subjects.hasError) {
      return const Text('No pudimos cargar tu agenda.');
    }
    final evaluationItems = evaluations.valueOrNull ?? const [];
    final activityItems = activities.valueOrNull ?? const [];
    final subjectItems = subjects.valueOrNull ?? const [];
    return switch (_tabIndex) {
      0 => _buildCalendar(evaluationItems, activityItems, subjectItems),
      1 => _buildEvaluationList(evaluationItems, subjectItems),
      _ => _buildActivityList(activityItems, subjectItems),
    };
  }

  Widget _buildCalendar(
    List<Evaluation> evaluations,
    List<TodoActivity> activities,
    List<Subject> subjects,
  ) {
    final monthlyEvaluations = evaluations
        .where((item) =>
            item.date.year == month.year && item.date.month == month.month)
        .toList();
    final monthlyActivities = activities
        .where((item) =>
            !item.isCompleted &&
            item.day.year == month.year &&
            item.day.month == month.month)
        .toList();
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mes anterior',
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${_months[month.month - 1]} ${month.year}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Mes siguiente',
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final day in const [
              'Lun',
              'Mar',
              'Mié',
              'Jue',
              'Vie',
              'Sáb',
              'Dom'
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(day, textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
        LayoutBuilder(builder: (context, constraints) {
          final firstOffset = DateTime(month.year, month.month, 1).weekday - 1;
          final days = DateTime(month.year, month.month + 1, 0).day;
          final rows = ((firstOffset + days) / 7).ceil();
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: constraints.maxWidth < 600 ? .82 : 1.15,
            ),
            itemCount: rows * 7,
            itemBuilder: (_, index) {
              final day = index - firstOffset + 1;
              if (day < 1 || day > days) return const SizedBox();
              final date = DateTime(month.year, month.month, day);
              final hasEvaluations = monthlyEvaluations
                  .any((evaluation) => _sameDay(evaluation.date, date));
              final hasActivities = monthlyActivities
                  .any((activity) => _sameDay(activity.day, date));
              final today = _sameDay(DateTime.now(), date);
              return Card(
                key: ValueKey(
                    'calendar-day-${date.toIso8601String().substring(0, 10)}'),
                margin: const EdgeInsets.all(2),
                color: today
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  onTap: () => _showDay(
                    date,
                    evaluations,
                    activities,
                    subjects,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day'),
                        if (hasEvaluations || hasActivities) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasEvaluations)
                                _Dot(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              if (hasEvaluations && hasActivities)
                                const SizedBox(width: 4),
                              if (hasActivities)
                                _Dot(
                                    key: ValueKey(
                                        'calendar-activity-dot-${date.toIso8601String().substring(0, 10)}'),
                                    color:
                                        Theme.of(context).colorScheme.tertiary),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _Legend(
              color: Theme.of(context).colorScheme.primary,
              label: 'Evaluaciones',
            ),
            _Legend(
              color: Theme.of(context).colorScheme.tertiary,
              label: 'Actividades',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvaluationList(
      List<Evaluation> evaluations, List<Subject> subjects) {
    if (evaluations.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_note_outlined,
        message: 'Todavía no hay evaluaciones.',
      );
    }
    return Column(
      children: evaluations.map((evaluation) {
        final subject = _subject(subjects, evaluation.subjectId);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(evaluation.name),
            subtitle: Text(
              '${subject?.name ?? 'Materia'} · ${_formatDay(evaluation.date)}',
            ),
            trailing: Text(_status(evaluation.status)),
            onTap: () => context.push(AppRoutes.editEvaluation(evaluation.id)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityList(
      List<TodoActivity> activities, List<Subject> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => showTodoActivityForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva actividad'),
          ),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          const _EmptyState(
            icon: Icons.checklist_outlined,
            message: 'Todavía no hay actividades.',
          )
        else
          ...activities.map(
              (activity) => _activityCard(activity, subjects, showDate: true)),
      ],
    );
  }

  Widget _activityCard(
    TodoActivity activity,
    List<Subject> subjects, {
    required bool showDate,
  }) {
    final subject = _subject(subjects, activity.subjectId);
    final details = [
      if (showDate) _formatDay(activity.day),
      if (subject != null) subject.name,
      if (activity.description?.trim().isNotEmpty == true)
        activity.description!.trim(),
    ];
    var displayedCompleted = activity.isCompleted;
    var savingCompletion = false;
    return StatefulBuilder(builder: (cardContext, setCardState) {
      Future<void> setCompleted(bool completed) async {
        final previous = displayedCompleted;
        setCardState(() {
          displayedCompleted = completed;
          savingCompletion = true;
        });
        final saved = await ref
            .read(todoActivityControllerProvider.notifier)
            .setCompleted(activity, completed);
        if (!cardContext.mounted) return;
        setCardState(() {
          savingCompletion = false;
          if (!saved) displayedCompleted = previous;
        });
        if (!saved) {
          ScaffoldMessenger.of(cardContext).showSnackBar(
            const SnackBar(
                content: Text('No pudimos actualizar la actividad.')),
          );
        }
      }

      return Card(
        child: ListTile(
          leading: Checkbox(
            value: displayedCompleted,
            onChanged: savingCompletion
                ? null
                : (value) => setCompleted(value ?? false),
          ),
          title: Text(
            activity.title,
            style: displayedCompleted
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: details.isEmpty ? null : Text(details.join(' · ')),
          onTap: () => showTodoActivityForm(
            context,
            activity: activity.copyWith(isCompleted: displayedCompleted),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                showTodoActivityForm(
                  context,
                  activity: activity.copyWith(isCompleted: displayedCompleted),
                );
              } else if (value == 'delete') {
                _deleteActivity(activity);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _deleteActivity(TodoActivity activity) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminar actividad'),
            content: Text('¿Querés eliminar “${activity.title}”?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    final deleted = await ref
        .read(todoActivityControllerProvider.notifier)
        .delete(activity.id);
    if (mounted && !deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos eliminar la actividad.')),
      );
    }
  }

  Future<void> _showDay(
    DateTime date,
    List<Evaluation> allEvaluations,
    List<TodoActivity> allActivities,
    List<Subject> subjects,
  ) async {
    final evaluations =
        allEvaluations.where((item) => _sameDay(item.date, date)).toList();
    final activities =
        allActivities.where((item) => _sameDay(item.day, date)).toList();
    final total = evaluations.length + activities.length;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${date.day} de ${_months[date.month - 1].toLowerCase()} de ${date.year}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text('$total ${total == 1 ? 'elemento' : 'elementos'}'),
        const SizedBox(height: 12),
        Expanded(
          child: total == 0
              ? const Center(child: Text('No hay nada para este día.'))
              : ListView(
                  children: [
                    ...evaluations.map((evaluation) {
                      final subject = _subject(subjects, evaluation.subjectId);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.school_outlined),
                          title: Text(evaluation.name),
                          subtitle: Text(subject?.name ?? 'Materia'),
                          trailing: Text(_status(evaluation.status)),
                          onTap: () {
                            Navigator.pop(context);
                            context
                                .push(AppRoutes.editEvaluation(evaluation.id));
                          },
                        ),
                      );
                    }),
                    ...activities.map((activity) =>
                        _activityCard(activity, subjects, showDate: false)),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final day = date.toIso8601String().substring(0, 10);
                context.push('${AppRoutes.newEvaluation}?date=$day');
              },
              icon: const Icon(Icons.school_outlined),
              label: const Text('Agregar evaluación'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await showTodoActivityForm(context, day: date);
              },
              icon: const Icon(Icons.checklist_outlined),
              label: const Text('Agregar actividad'),
            ),
          ],
        ),
      ],
    );
    if (!mounted) return;
    if (MediaQuery.sizeOf(context).width < 700) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: SizedBox(
            width: 520,
            height: 560,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: content,
            ),
          ),
        ),
      );
    }
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      );
}

Subject? _subject(List<Subject> subjects, String? id) => id == null
    ? null
    : subjects.where((subject) => subject.id == id).firstOrNull;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatDay(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

const _months = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre'
];

String _status(EvaluationStatus value) => switch (value) {
      EvaluationStatus.pending => 'Pendiente',
      EvaluationStatus.submitted => 'Presentada',
      EvaluationStatus.approved => 'Aprobada',
      EvaluationStatus.failed => 'Desaprobada',
      EvaluationStatus.absent => 'Ausente',
      EvaluationStatus.recovered => 'Recuperada',
    };
