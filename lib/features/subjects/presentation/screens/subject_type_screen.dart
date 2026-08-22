import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/content_page.dart';

class SubjectTypeScreen extends StatelessWidget {
  const SubjectTypeScreen({super.key});
  @override
  Widget build(BuildContext context) => ContentPage(
      title: '¿Qué querés agregar?',
      showBackButton: true,
      backFallback: () => context.go(AppRoutes.subjects),
      child: Wrap(spacing: 16, runSpacing: 16, children: [
        _Choice(
            icon: Icons.menu_book,
            title: 'Materia en cursado',
            description: 'Seguimiento académico completo.',
            onTap: () => context.go(AppRoutes.newCurrentSubject)),
        _Choice(
            icon: Icons.task_alt,
            title: 'Materia ya cursada',
            description: 'Cargala directamente con su resultado final.',
            onTap: () => context.go(AppRoutes.newHistoricalSubject)),
      ]));
}

class _Choice extends StatelessWidget {
  const _Choice(
      {required this.icon,
      required this.title,
      required this.description,
      required this.onTap});
  final IconData icon;
  final String title, description;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 360,
      child: Card(
          child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(title,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(description)
                      ])))));
}
