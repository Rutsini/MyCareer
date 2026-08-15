import 'package:flutter/material.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../core/widgets/empty_state_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) => const ContentPage(
        title: 'Progreso académico',
        child: EmptyStateCard(icon: Icons.insights_outlined, title: 'Tu avance', message: 'Cuando cargues materias aprobadas podrás ver acá el avance de tu carrera.'),
      );
}
