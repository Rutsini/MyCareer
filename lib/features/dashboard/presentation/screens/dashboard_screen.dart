import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/academic_year.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../../domain/entities/subject.dart';
import '../../../../domain/models/dashboard_data.dart';
import '../../../evaluations/application/evaluation_controller.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../subjects/application/academic_year_controller.dart';
import '../../../subjects/application/subject_controller.dart';
import '../../application/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ContentPage(
        title: 'Inicio',
        child: ref.watch(dashboardDataProvider).when(
              loading: () => const _Loading(),
              error: (_, __) => _Empty(
                'No pudimos cargar tu resumen académico.',
                icon: Icons.cloud_off_outlined,
                action: 'Reintentar',
                onAction: () {
                  ref.invalidate(academicYearsProvider);
                  ref.invalidate(subjectsProvider);
                  ref.invalidate(evaluationsProvider);
                  ref.invalidate(userProfileProvider);
                },
              ),
              data: (data) => _Dashboard(
                data: data,
                years: ref.watch(academicYearsProvider).valueOrNull ?? const [],
                name: ref.watch(userProfileProvider).valueOrNull?.displayName,
                career: ref.watch(userProfileProvider).valueOrNull?.career.name,
                onYear: (id) =>
                    ref.read(dashboardYearIdProvider.notifier).state = id,
              ),
            ),
      );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.data,
    required this.years,
    required this.name,
    required this.career,
    required this.onYear,
  });
  final DashboardData data;
  final List<AcademicYear> years;
  final String? name, career;
  final ValueChanged<String?> onYear;

  @override
  Widget build(BuildContext context) {
    final cleanName = name?.trim() ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(cleanName.isEmpty ? 'Hola' : 'Hola, $cleanName',
          style: Theme.of(context).textTheme.headlineSmall),
      Text(data.selectedYear == null
          ? 'Tu resumen académico'
          : 'Resumen académico · ${data.selectedYear!.year}'),
      if (career?.trim().isNotEmpty == true) Text(career!),
      const SizedBox(height: 16),
      if (!data.hasAcademicYears)
        _Empty(
          'Empezá configurando tu año académico.',
          icon: Icons.school_outlined,
          action: 'Configurar año',
          onAction: () => context.go(AppRoutes.profile),
        )
      else ...[
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButton<String>(
            value: years.any((year) => year.id == data.selectedYear?.id)
                ? data.selectedYear?.id
                : null,
            hint: const Text('Seleccionar año'),
            items: years
                .map((year) => DropdownMenuItem(
                      value: year.id,
                      child: Text(
                          '${year.year}${year.isCurrent ? ' · Actual' : ''}'),
                    ))
                .toList(),
            onChanged: onYear,
          ),
        ),
        if (!data.hasCurrentYear)
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title:
                  const Text('No tenés un año académico actual configurado.'),
              trailing: TextButton(
                onPressed: () => context.go(AppRoutes.profile),
                child: const Text('Configurar año académico'),
              ),
            ),
          ),
        if (data.selectedYear != null) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _Metric('Materias activas', data.activeSubjectsCount,
                Icons.menu_book_outlined),
            _Metric('Promocionando', data.promotingCount,
                Icons.workspace_premium_outlined),
            _Metric('Regulares', data.regularCount, Icons.check_circle_outline),
            _Metric('En riesgo', data.atRiskCount, Icons.warning_amber_rounded,
                warning: data.atRiskCount > 0),
          ]),
          if (data.attentionItems.isNotEmpty) ...[
            const _Heading('Requiere tu atención'),
            ...data.attentionItems.map((item) => _Attention(item)),
          ],
          _Heading('Próximas evaluaciones',
              action: 'Ver calendario',
              onAction: () => context.go(AppRoutes.calendar)),
          if (data.upcomingEvaluations.isEmpty)
            const _Empty('No tenés evaluaciones próximas para este año.')
          else
            Card(
              child: Column(
                children: data.upcomingEvaluations
                    .map((item) => ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(item.evaluation.name),
                          subtitle: Text(item.evaluation.reminders
                                  .where((reminder) => reminder.enabled)
                                  .isEmpty
                              ? item.subjectName
                              : '${item.subjectName} · 🔔 ${item.evaluation.reminders.where((reminder) => reminder.enabled).length} recordatorio${item.evaluation.reminders.where((reminder) => reminder.enabled).length == 1 ? '' : 's'}'),
                          trailing: Text(_friendlyDate(item)),
                          onTap: () => context
                              .go(AppRoutes.editEvaluation(item.evaluation.id)),
                        ))
                    .toList(),
              ),
            ),
          _Heading('Mis materias',
              action: data.subjectItems.length > 6 ? 'Ver todas' : null,
              onAction: () => context.go(AppRoutes.subjects)),
          _SubjectGrid(data.subjectItems.take(6).toList()),
          const SizedBox(height: 24),
          _Summaries(data),
        ],
      ],
      const _Heading('Accesos rápidos'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(
          onPressed: data.selectedYear == null
              ? null
              : () => context.go(AppRoutes.newSubject),
          icon: const Icon(Icons.add),
          label: const Text('Nueva materia'),
        ),
        OutlinedButton.icon(
          onPressed: data.selectedYear == null
              ? null
              : () => context.go(AppRoutes.newEvaluation),
          icon: const Icon(Icons.post_add_outlined),
          label: const Text('Nueva evaluación'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.calendar),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Calendario'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.progress),
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Progreso'),
        ),
      ]),
    ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, {this.warning = false});
  final String label;
  final int value;
  final IconData icon;
  final bool warning;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        child: Card(
          color: warning ? Theme.of(context).colorScheme.errorContainer : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(icon),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$value',
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(label),
              ]),
            ]),
          ),
        ),
      );
}

class _Attention extends StatelessWidget {
  const _Attention(this.item);
  final DashboardAttentionItem item;
  @override
  Widget build(BuildContext context) {
    final critical = item.severity == DashboardAttentionSeverity.critical;
    return Card(
      child: ListTile(
        leading: Icon(
          critical ? Icons.error_outline : Icons.warning_amber_rounded,
          color: critical ? Theme.of(context).colorScheme.error : null,
        ),
        title: Text('${item.subjectName} · ${item.title}'),
        subtitle: Text(item.message),
        trailing: TextButton(
          onPressed: () => item.evaluationId == null
              ? context.go(AppRoutes.subject(item.subjectId))
              : context.go(AppRoutes.editEvaluation(item.evaluationId!)),
          child: Text(item.actionLabel),
        ),
      ),
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid(this.items);
  final List<DashboardSubjectItem> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _Empty(
        'Todavía no tenés materias para este año.',
        action: 'Nueva materia',
        onAction: () => context.go(AppRoutes.newSubject),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 850
          ? 3
          : constraints.maxWidth >= 560
              ? 2
              : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 190,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (_, index) => _SubjectCard(items[index]),
      );
    });
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard(this.item);
  final DashboardSubjectItem item;
  @override
  Widget build(BuildContext context) {
    final subject = item.subject;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.subject(subject.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(subject.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium),
            Text([
              if (subject.commission != null) subject.commission!,
              _duration(subject),
            ].join(' · ')),
            const SizedBox(height: 6),
            Chip(label: Text(_condition(item.academicResult.condition))),
            const Spacer(),
            Row(children: [
              Expanded(
                  child: Text('Promedio\n${_decimal(item.currentAverage)}')),
              Expanded(
                child: Text(
                  item.nextEvaluation == null
                      ? 'Próxima\n—'
                      : 'Próxima\n${_shortDate(item.nextEvaluation!)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Summaries extends StatelessWidget {
  const _Summaries(this.data);
  final DashboardData data;
  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _Summary('Progreso académico', [
        _Row('Promedio general', _decimal(data.progress.generalAverage)),
        _Row('Electivos obtenidos', _number(data.progress.electiveObtained)),
        _Row('Electivos en curso', _number(data.progress.electiveInProgress)),
        _Row(
            'Requeridos',
            data.progress.electiveRequired == null
                ? 'Sin configurar'
                : _number(data.progress.electiveRequired!)),
        TextButton(
            onPressed: () => context.go(AppRoutes.progress),
            child: const Text('Ver progreso')),
      ]),
      _Summary('Estado del cursado', [
        _Row('En promoción', '${data.promotingCount}'),
        _Row('Regular', '${data.regularCount}'),
        _Row('En riesgo', '${data.atRiskCount}'),
        _Row('No regularizó', '${data.failedCount}'),
        _Row('Sin datos suficientes', '${data.noDataCount}'),
        const Divider(),
        const Text('Requisitos configurados'),
        _Row('Promoción',
            '${data.promotionRulesMet} de ${data.promotionRulesTotal}'),
        _Row('Regularidad',
            '${data.regularityRulesMet} de ${data.regularityRulesTotal}'),
      ]),
    ];
    return LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 700
            ? Column(children: [cards[0], const SizedBox(height: 12), cards[1]])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ]));
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.title, this.children);
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...children,
          ]),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Expanded(child: Text(label)), Text(value)]),
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: Row(children: [
          Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message, {this.icon, this.action, this.onAction});
  final String message;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            if (icon != null) ...[
              Icon(icon, size: 40),
              const SizedBox(height: 8),
            ],
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ]),
        ),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Column(children: [
        LinearProgressIndicator(),
        SizedBox(height: 16),
        Card(child: SizedBox(height: 120)),
        SizedBox(height: 12),
        Card(child: SizedBox(height: 180)),
      ]);
}

String _friendlyDate(UpcomingEvaluationItem item) {
  if (item.isToday) {
    return 'Hoy${item.evaluation.allDay ? '' : ' · ${_time(item.evaluation.date)}'}';
  }
  if (item.isTomorrow) {
    return 'Mañana${item.evaluation.allDay ? '' : ' · ${_time(item.evaluation.date)}'}';
  }
  return _shortDate(item.evaluation);
}

String _shortDate(Evaluation evaluation) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic'
  ];
  final date = '${evaluation.date.day} ${months[evaluation.date.month - 1]}';
  return evaluation.allDay
      ? '$date · ${evaluation.name}'
      : '$date ${_time(evaluation.date)} · ${evaluation.name}';
}

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String _decimal(double? value) =>
    value == null ? '—' : value.toStringAsFixed(2).replaceAll('.', ',');
String _number(double value) => value == value.roundToDouble()
    ? '${value.toInt()}'
    : value.toStringAsFixed(1).replaceAll('.', ',');
String _duration(Subject subject) => subject.duration == SubjectDuration.annual
    ? 'Anual'
    : subject.semester == Semester.first
        ? '1°C'
        : '2°C';
String _condition(AcademicCondition? value) => switch (value) {
      AcademicCondition.promoting => 'En promoción',
      AcademicCondition.regular => 'Regular',
      AcademicCondition.atRisk => 'En riesgo',
      AcademicCondition.failed => 'No regularizó',
      AcademicCondition.noData || null => 'Sin datos suficientes',
    };
