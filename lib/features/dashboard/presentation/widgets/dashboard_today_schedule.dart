import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/subject_schedule_formatter.dart';
import '../../../../domain/entities/subject.dart';
import '../../../schedule/presentation/screens/schedule_screen.dart';

class DashboardTodaySchedule extends StatelessWidget {
  const DashboardTodaySchedule({required this.subjects, this.now, super.key});

  final List<Subject> subjects;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final date = now ?? DateTime.now();
    final entries = scheduleEntries(subjects
            .where((subject) =>
                subject.trackingMode == TrackingMode.tracked &&
                subject.courseStatus == CourseStatus.active)
            .toList())
        .where((entry) => entry.block.weekday == date.weekday)
        .toList()
      ..sort((a, b) => a.block.startMinutes.compareTo(b.block.startMinutes));
    return Column(
      key: const Key('dashboard-today-schedule'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(children: [
            Expanded(
              child: Text(
                'HOY · ${scheduleWeekdayLabel(date.weekday).toUpperCase()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.schedule),
              child: const Text('Ver horario completo'),
            ),
          ]),
        ),
        if (entries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Hoy no tenés clases cargadas.'),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final entry in entries)
                  ListTile(
                    leading: Text(formatScheduleRange(entry.block)),
                    title: Text(entry.subject.name),
                    subtitle: entry.block.location?.isNotEmpty == true
                        ? Text(entry.block.location!)
                        : null,
                    onTap: () => showScheduleBlockDetail(context, entry),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
