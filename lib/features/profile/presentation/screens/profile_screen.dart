// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/profile_controller.dart';

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
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Datos personales',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    const SizedBox(height: 16),
                                    Text(
                                        'Nombre: ${p.displayName ?? 'Sin nombre'}'),
                                    const SizedBox(height: 8),
                                    SelectableText('Email: ${p.email}')
                                  ]))),
                      const SizedBox(height: 16),
                      _CareerForm(profile: p),
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

class _CareerForm extends ConsumerStatefulWidget {
  const _CareerForm({required this.profile});
  final UserProfile profile;
  @override
  ConsumerState<_CareerForm> createState() => _CareerFormState();
}

class _CareerFormState extends ConsumerState<_CareerForm> {
  late final TextEditingController name, current, total, points;
  @override
  void initState() {
    super.initState();
    final c = widget.profile.career;
    name = TextEditingController(text: c.name);
    current = TextEditingController(text: c.currentYear?.toString());
    total = TextEditingController(text: c.totalSubjects?.toString());
    points = TextEditingController(text: c.requiredElectivePoints?.toString());
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
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Configuración académica',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Carrera')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: current,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Año actual')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: total,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Total de materias')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: points,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Puntos electivos requeridos')),
                  if (state.hasError) ...[
                    const SizedBox(height: 12),
                    Text((state.error as AppException).message,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))
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
                              if (ok && mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Perfil guardado.')));
                            },
                      child: const Text('Guardar'))
                ])));
  }
}
