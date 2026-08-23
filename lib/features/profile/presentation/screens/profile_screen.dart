// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/entities/notification_settings.dart';
import '../../../../core/notifications/local_notification_gateway.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/profile_controller.dart';
import '../../../notifications/application/notification_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return ContentPage(
        title: 'Perfil',
        child: profile.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('No pudimos cargar tu perfil.'),
            data: (p) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Datos personales',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    const SizedBox(height: 8),
                                    Text(p.displayName ?? 'Sin nombre'),
                                    const SizedBox(height: 4),
                                    SelectableText(p.email)
                                  ]))),
                      const SizedBox(height: 16),
                      _CareerForm(profile: p),
                      const SizedBox(height: 16),
                      _NotificationSettingsCard(
                          settings: p.settings.notifications),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                          onPressed: ref.watch(authControllerProvider).isLoading
                              ? null
                              : () => ref
                                  .read(authControllerProvider.notifier)
                                  .signOut(),
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'))
                    ])));
  }
}

class _NotificationSettingsCard extends ConsumerStatefulWidget {
  const _NotificationSettingsCard({required this.settings});
  final NotificationSettings settings;

  @override
  ConsumerState<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState
    extends ConsumerState<_NotificationSettingsCard> {
  static const choices = <int, String>{
    1440: '1 día antes',
    2880: '2 días antes',
    10080: '1 semana antes',
  };

  String _permissionLabel(NotificationPermissionState state) => switch (state) {
        NotificationPermissionState.granted => 'Permitido',
        NotificationPermissionState.denied => 'Denegado',
        NotificationPermissionState.unknown => 'Sin solicitar',
        NotificationPermissionState.notSupported => 'No disponible',
      };

  @override
  Widget build(BuildContext context) {
    final permission = ref.watch(notificationPermissionProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final loading = ref.watch(profileControllerProvider).isLoading;
    final settings = widget.settings;
    final offsets = settings.defaultReminderOffsetsMinutes.toSet();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        maintainState: true,
        title: const Text('Notificaciones y recordatorios'),
        subtitle: Text(_summary(settings, permission)),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
                'Notificaciones: ${settings.enabled ? 'Activadas' : 'Desactivadas'}'),
            Text('Permiso: ${_permissionLabel(permission)}'),
            const SizedBox(height: 8),
            Text(kIsWeb
                ? 'En Web, los recordatorios funcionan mientras MyCareer esté abierto.'
                : 'Android puede mostrar recordatorios aunque cierres MyCareer.'),
            const Divider(height: 28),
            Text('Recordatorios por defecto',
                style: Theme.of(context).textTheme.titleSmall),
            ...choices.entries.map((choice) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(choice.value),
                  value: offsets.contains(choice.key),
                  onChanged: loading
                      ? null
                      : (selected) {
                          final next = {...offsets};
                          selected == true
                              ? next.add(choice.key)
                              : next.remove(choice.key);
                          controller.saveNotifications(settings.copyWith(
                            defaultReminderOffsetsMinutes: next.toList()
                              ..sort(),
                          ));
                        },
                )),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hora para evaluaciones sin horario'),
              subtitle: Text(
                '${settings.allDayReminderHour.toString().padLeft(2, '0')}:'
                '${settings.allDayReminderMinute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.schedule),
              onTap: loading
                  ? null
                  : () async {
                      final value = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: settings.allDayReminderHour,
                          minute: settings.allDayReminderMinute,
                        ),
                      );
                      if (value != null) {
                        await controller.saveNotifications(settings.copyWith(
                          allDayReminderHour: value.hour,
                          allDayReminderMinute: value.minute,
                        ));
                      }
                    },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: loading
                  ? null
                  : () async {
                      if (settings.enabled) {
                        await controller.saveNotifications(
                          settings.copyWith(enabled: false),
                        );
                      } else {
                        await controller.enableNotifications(settings);
                      }
                      ref.read(notificationPermissionProvider.notifier).state =
                          await ref
                              .read(notificationCoordinatorProvider)
                              .permissionStatus();
                    },
              icon: Icon(settings.enabled
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined),
              label: Text(settings.enabled
                  ? 'Desactivar notificaciones'
                  : 'Activar notificaciones'),
            ),
            if (permission == NotificationPermissionState.granted) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(notificationCoordinatorProvider).showTest(),
                icon: const Icon(Icons.notification_add_outlined),
                label: const Text('Enviar notificación de prueba'),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  String _summary(
      NotificationSettings settings, NotificationPermissionState permission) {
    if (!settings.enabled) {
      return permission == NotificationPermissionState.denied
          ? 'Desactivadas · Permiso denegado'
          : 'Desactivadas';
    }
    final reminders = settings.defaultReminderOffsetsMinutes
        .map((offset) => choices[offset])
        .whereType<String>()
        .join(', ');
    final enabled = reminders.isEmpty ? 'Activadas' : 'Activadas · $reminders';
    return permission == NotificationPermissionState.denied
        ? '$enabled · Permiso denegado'
        : enabled;
  }
}

class _CareerForm extends ConsumerStatefulWidget {
  const _CareerForm({required this.profile});
  final UserProfile profile;
  @override
  ConsumerState<_CareerForm> createState() => _CareerFormState();
}

class _CareerFormState extends ConsumerState<_CareerForm> {
  late final TextEditingController name, current, total, points;
  late final ExpansibleController _expansionController;
  late bool _expanded;
  @override
  void initState() {
    super.initState();
    final c = widget.profile.career;
    name = TextEditingController(text: c.name);
    current = TextEditingController(text: c.currentYear?.toString());
    total = TextEditingController(text: c.totalSubjects?.toString());
    points = TextEditingController(text: c.requiredElectivePoints?.toString());
    _expansionController = ExpansibleController();
    _expanded = c.name?.trim().isEmpty ?? true;
  }

  @override
  void dispose() {
    for (final c in [name, current, total, points]) c.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c) =>
      c.text.trim().isEmpty ? null : int.tryParse(c.text);
  double? _double(TextEditingController c) => c.text.trim().isEmpty
      ? null
      : double.tryParse(c.text.replaceAll(',', '.'));
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    return Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
            controller: _expansionController,
            initiallyExpanded: _expanded,
            maintainState: true,
            onExpansionChanged: (expanded) => _expanded = expanded,
            title: const Text('Configuración académica'),
            subtitle: _careerSummary(context),
            childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 6),
                Text(
                  'Estos datos corresponden a tu carrera completa, salvo el año actual.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Carrera')),
                const SizedBox(height: 12),
                TextField(
                    controller: current,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Año de carrera actual',
                        helperText: 'Ej.: 4')),
                const SizedBox(height: 12),
                TextField(
                    controller: total,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Total de materias de la carrera',
                        helperText: 'Total requerido por tu plan de estudios')),
                const SizedBox(height: 12),
                TextField(
                    controller: points,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText:
                            'Puntos electivos requeridos para completar la carrera',
                        helperText: 'Total requerido por tu plan de estudios')),
                if (state.hasError) ...[
                  const SizedBox(height: 12),
                  Text((state.error as AppException).message,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error))
                ],
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final career = CareerSettings(
                                name: name.text.trim().isEmpty
                                    ? null
                                    : name.text.trim(),
                                currentYear: _int(current),
                                totalSubjects: _int(total),
                                requiredElectivePoints: _double(points));
                            final ok = await ref
                                .read(profileControllerProvider.notifier)
                                .save(career);
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Perfil guardado.')));
                              setState(() => _expanded = false);
                              _expansionController.collapse();
                            }
                          },
                    child: const Text('Guardar'))
              ])
            ]));
  }

  Widget _careerSummary(BuildContext context) {
    final lines = <String>[
      if (name.text.trim().isNotEmpty) name.text.trim(),
      if (_int(current) case final year?) 'Año de carrera: $year',
      if (_int(total) case final count?) 'Total de materias: $count',
      if (_double(points) case final required?)
        'Electivos requeridos: ${required == required.roundToDouble() ? required.toInt() : required}',
    ];
    if (lines.isEmpty) lines.add('Completá los datos de tu carrera');
    return Text(lines.join('\n'), style: Theme.of(context).textTheme.bodySmall);
  }
}
