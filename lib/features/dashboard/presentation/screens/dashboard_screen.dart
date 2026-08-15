import 'package:flutter/material.dart';

import '../../../../core/widgets/content_page.dart';
import '../../../../core/widgets/empty_state_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const ContentPage(
        title: 'Inicio',
        child: EmptyStateCard(
          icon: Icons.waving_hand_outlined,
          title: 'Bienvenido',
          message: 'Tu información académica aparecerá acá cuando cargues tus materias.',
        ),
      );
}
