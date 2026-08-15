import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final operation = ref.watch(authControllerProvider);
    return ContentPage(
      title: 'Perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos personales', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  _ProfileRow(label: 'Nombre', value: user?.displayName?.trim().isNotEmpty == true ? user!.displayName! : 'Sin nombre'),
                  const SizedBox(height: 12),
                  _ProfileRow(label: 'Email', value: user?.email ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configuración académica', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('La configuración de carrera estará disponible en una próxima versión.'),
                ],
              ),
            ),
          ),
          if (operation.hasError) ...[
            const SizedBox(height: 16),
            Text((operation.error as AppException).message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: operation.isLoading ? null : () => ref.read(authControllerProvider.notifier).signOut(),
              icon: operation.isLoading
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      );
}
