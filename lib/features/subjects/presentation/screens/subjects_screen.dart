import 'package:flutter/material.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../core/widgets/empty_state_card.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ContentPage(
        title: 'Materias',
        child: EmptyStateCard(icon: Icons.menu_book_outlined, title: 'Sin materias', message: 'Todavía no tenés materias cargadas.'),
      );
}
