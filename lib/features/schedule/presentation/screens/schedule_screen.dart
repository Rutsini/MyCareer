import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/subject_schedule_formatter.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/academic_year.dart';
import '../../../../domain/entities/subject.dart';
import '../../../../domain/entities/subject_schedule_block.dart';
import '../../../subjects/application/academic_year_controller.dart';
import '../../../subjects/application/subject_controller.dart';

enum ScheduleViewMode { today, week }

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  ScheduleViewMode _mode = ScheduleViewMode.week;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final years = ref.watch(academicYearsProvider);
    return Scaffold(
      body: SafeArea(
        child: ContentPage(
          title: 'Horario',
          showBackButton: true,
          backFallback: () => context.go(AppRoutes.dashboard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ScheduleViewMode>(
                key: const Key('schedule-view-selector'),
                segments: const [
                  ButtonSegment(
                    value: ScheduleViewMode.today,
                    label: Text('Hoy'),
                  ),
                  ButtonSegment(
                    value: ScheduleViewMode.week,
                    label: Text('Semana'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) =>
                    setState(() => _mode = value.single),
              ),
              const SizedBox(height: 16),
              if (subjects.isLoading || years.isLoading)
                const LinearProgressIndicator()
              else if (subjects.hasError || years.hasError)
                const Text('No pudimos cargar el horario.')
              else
                _loaded(subjects.requireValue, years.requireValue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loaded(List<Subject> subjects, List<AcademicYear> years) {
    if (years.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Creá un año académico para organizar tu horario.'),
        ),
      );
    }
    var selectedId = ref.watch(selectedYearIdProvider);
    if (!years.any((year) => year.id == selectedId)) {
      selectedId = resolveSelectedAcademicYearId(years, selectedId);
      final resolved = selectedId;
      Future.microtask(
        () => ref.read(selectedYearIdProvider.notifier).state = resolved,
      );
    }
    final selectedSubjects = subjects
        .where((subject) =>
            subject.academicYearId == selectedId &&
            subject.trackingMode == TrackingMode.tracked &&
            subject.courseStatus == CourseStatus.active)
        .toList();
    final entries = scheduleEntries(selectedSubjects);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButton<String>(
            value: selectedId,
            items: years
                .map((year) => DropdownMenuItem(
                      value: year.id,
                      child: Text(
                        '${year.year}${year.isCurrent ? ' · Actual' : ''}',
                      ),
                    ))
                .toList(),
            onChanged: (value) =>
                ref.read(selectedYearIdProvider.notifier).state = value,
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          _EmptySchedule(onOpenSubjects: () => context.go(AppRoutes.subjects))
        else if (_mode == ScheduleViewMode.today)
          TodayScheduleView(entries: entries, date: DateTime.now())
        else
          WeeklyScheduleGrid(entries: entries),
      ],
    );
  }
}

class ScheduleEntry {
  const ScheduleEntry({required this.subject, required this.block});

  final Subject subject;
  final SubjectScheduleBlock block;
}

List<ScheduleEntry> scheduleEntries(List<Subject> subjects) => [
      for (final subject in subjects)
        for (final block in subject.scheduleBlocks)
          ScheduleEntry(subject: subject, block: block),
    ]..sort((a, b) {
        final day = a.block.weekday.compareTo(b.block.weekday);
        return day != 0
            ? day
            : a.block.startMinutes.compareTo(b.block.startMinutes);
      });

bool schedulesConflict(SubjectScheduleBlock a, SubjectScheduleBlock b) =>
    a.weekday == b.weekday &&
    a.startMinutes < b.endMinutes &&
    b.startMinutes < a.endMinutes;

class TodayScheduleView extends StatelessWidget {
  const TodayScheduleView({
    required this.entries,
    required this.date,
    super.key,
  });

  final List<ScheduleEntry> entries;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = entries
        .where((entry) => entry.block.weekday == date.weekday)
        .toList()
      ..sort((a, b) => a.block.startMinutes.compareTo(b.block.startMinutes));
    return Column(
      key: const Key('today-schedule-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${scheduleWeekdayLabel(date.weekday).toUpperCase()} '
          '${date.day} DE ${_month(date.month).toUpperCase()}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (today.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Hoy no tenés clases cargadas.'),
            ),
          )
        else
          for (final entry in today) _ScheduleListTile(entry: entry, now: date),
      ],
    );
  }
}

class _ScheduleListTile extends StatelessWidget {
  const _ScheduleListTile({required this.entry, required this.now});

  final ScheduleEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final minute = now.hour * 60 + now.minute;
    final state = minute >= entry.block.endMinutes
        ? 'YA PASÓ'
        : minute >= entry.block.startMinutes
            ? 'AHORA'
            : 'PRÓXIMA';
    return Card(
      child: ListTile(
        leading: Icon(state == 'YA PASÓ'
            ? Icons.check_circle_outline
            : state == 'AHORA'
                ? Icons.radio_button_checked
                : Icons.schedule),
        title: Text(entry.subject.name),
        subtitle: Text([
          formatScheduleRange(entry.block),
          if (entry.subject.commission?.trim().isNotEmpty == true)
            entry.subject.commission!.trim(),
          if (entry.block.location?.isNotEmpty == true) entry.block.location!,
          classModalityLabel(entry.block.modality),
        ].join(' · ')),
        trailing: Text(state),
        onTap: () => showScheduleBlockDetail(context, entry),
      ),
    );
  }
}

class WeeklyScheduleGrid extends StatelessWidget {
  const WeeklyScheduleGrid({required this.entries, super.key});

  final List<ScheduleEntry> entries;

  @override
  Widget build(BuildContext context) {
    final days = [1, 2, 3, 4, 5];
    if (entries.any((entry) => entry.block.weekday == DateTime.saturday)) {
      days.add(DateTime.saturday);
    }
    if (entries.any((entry) => entry.block.weekday == DateTime.sunday)) {
      days.add(DateTime.sunday);
    }
    final first =
        (entries.map((entry) => entry.block.startMinutes).reduce(math.min) ~/
                60) *
            60;
    final lastRaw =
        entries.map((entry) => entry.block.endMinutes).reduce(math.max);
    final last = ((lastRaw + 59) ~/ 60) * 60;
    const pixelsPerMinute = .76;
    final height = math.max(360.0, (last - first) * pixelsPerMinute);
    const hourWidth = 64.0;
    const dayWidth = 148.0;
    final hasConflicts = entries.any((entry) => entries.any((other) =>
        !identical(entry, other) &&
        schedulesConflict(entry.block, other.block)));
    return Column(
      key: const Key('weekly-schedule-grid'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasConflicts)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: const ListTile(
              leading: Icon(Icons.warning_amber_rounded),
              title: Text('Hay horarios superpuestos'),
              subtitle:
                  Text('Los bloques en conflicto se muestran en paralelo.'),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: hourWidth + days.length * dayWidth,
            child: Column(children: [
              Row(children: [
                const SizedBox(width: hourWidth, height: 44),
                for (final day in days)
                  Container(
                    key: Key('schedule-day-$day'),
                    width: dayWidth,
                    height: 44,
                    alignment: Alignment.center,
                    child: Text(
                      scheduleWeekdayLabel(day).toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
              ]),
              SizedBox(
                height: height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: hourWidth,
                      height: height,
                      child: Stack(children: [
                        for (var minute = first; minute <= last; minute += 60)
                          Positioned(
                            top: (minute - first) * pixelsPerMinute,
                            right: 8,
                            child: Text(
                              formatScheduleMinutes(minute),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ]),
                    ),
                    for (final day in days)
                      _DayColumn(
                        entries: entries
                            .where((entry) => entry.block.weekday == day)
                            .toList(),
                        first: first,
                        height: height,
                        width: dayWidth,
                        pixelsPerMinute: pixelsPerMinute,
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SchedulePlacement {
  const _SchedulePlacement(this.entry, this.lane);

  final ScheduleEntry entry;
  final int lane;
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.entries,
    required this.first,
    required this.height,
    required this.width,
    required this.pixelsPerMinute,
  });

  final List<ScheduleEntry> entries;
  final int first;
  final double height;
  final double width;
  final double pixelsPerMinute;

  List<_SchedulePlacement> _placements() {
    final sorted = [...entries]
      ..sort((a, b) => a.block.startMinutes.compareTo(b.block.startMinutes));
    final laneEnds = <int>[];
    final placements = <_SchedulePlacement>[];
    for (final entry in sorted) {
      var lane = laneEnds.indexWhere(
        (endMinutes) => endMinutes <= entry.block.startMinutes,
      );
      if (lane < 0) {
        lane = laneEnds.length;
        laneEnds.add(entry.block.endMinutes);
      } else {
        laneEnds[lane] = entry.block.endMinutes;
      }
      placements.add(_SchedulePlacement(entry, lane));
    }
    return placements;
  }

  @override
  Widget build(BuildContext context) {
    final placements = _placements();
    final laneCount = placements.isEmpty
        ? 1
        : placements.map((placement) => placement.lane).reduce(math.max) + 1;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Stack(children: [
        for (final placement in placements)
          Positioned(
            key: Key(
              'schedule-block-${placement.entry.subject.id}-'
              '${placement.entry.block.id}',
            ),
            top: (placement.entry.block.startMinutes - first) * pixelsPerMinute,
            left: 4 + placement.lane * ((width - 8) / laneCount),
            width: (width - 8) / laneCount,
            height: math.max(
              42,
              (placement.entry.block.endMinutes -
                      placement.entry.block.startMinutes) *
                  pixelsPerMinute,
            ),
            child: _GridBlock(
              entry: placement.entry,
              compact: laneCount > 1,
            ),
          ),
      ]),
    );
  }
}

class _GridBlock extends StatelessWidget {
  const _GridBlock({required this.entry, required this.compact});

  final ScheduleEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = subjectScheduleColor(context, entry.subject.id);
    final semantics =
        '${entry.subject.name}, ${scheduleWeekdayLabel(entry.block.weekday)}, '
        '${formatScheduleMinutes(entry.block.startMinutes)} a '
        '${formatScheduleMinutes(entry.block.endMinutes)}'
        '${entry.block.location == null ? '' : ', ${entry.block.location}'}';
    return Semantics(
      label: semantics,
      button: true,
      child: Tooltip(
        message: semantics,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => showScheduleBlockDetail(context, entry),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compact)
                    const Icon(Icons.warning_amber_rounded, size: 14),
                  Text(
                    entry.subject.shortName ?? entry.subject.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (entry.subject.commission?.trim().isNotEmpty == true)
                    Text(
                      entry.subject.commission!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (!compact &&
                      entry.block.endMinutes - entry.block.startMinutes >= 60)
                    Text(
                      formatScheduleRange(entry.block),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (!compact && entry.block.location?.isNotEmpty == true)
                    Text(
                      entry.block.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showScheduleBlockDetail(
  BuildContext context,
  ScheduleEntry entry,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(entry.subject.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(scheduleWeekdayLabel(entry.block.weekday)),
          Text(formatScheduleRange(entry.block)),
          if (entry.subject.commission?.trim().isNotEmpty == true)
            Text('Comisión ${entry.subject.commission!.trim()}'),
          if (entry.block.location?.isNotEmpty == true)
            Text(entry.block.location!),
          Text(classModalityLabel(entry.block.modality)),
          if (entry.block.virtualLink?.isNotEmpty == true)
            SelectableText(entry.block.virtualLink!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.go(AppRoutes.subject(entry.subject.id));
          },
          child: const Text('Ver materia'),
        ),
      ],
    ),
  );
}

Color subjectScheduleColor(BuildContext context, String id) {
  final scheme = Theme.of(context).colorScheme;
  final palette = [
    scheme.primaryContainer,
    scheme.secondaryContainer,
    scheme.tertiaryContainer,
    scheme.surfaceContainerHighest,
  ];
  return palette[_stableSubjectHash(id) % palette.length];
}

int _stableSubjectHash(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }
  return hash;
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({required this.onOpenSubjects});

  final VoidCallback onOpenSubjects;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_view_week_outlined, size: 38),
              const SizedBox(height: 12),
              Text(
                'Todavía no cargaste horarios de cursado.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Podés agregarlos al crear o editar una materia.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onOpenSubjects,
                child: const Text('Ir a mis materias'),
              ),
            ],
          ),
        ),
      );
}

String _month(int month) => const [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ][month - 1];
