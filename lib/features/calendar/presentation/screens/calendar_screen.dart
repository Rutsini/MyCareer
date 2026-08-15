import 'package:flutter/material.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../core/widgets/empty_state_card.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context) => const ContentPage(
        title: 'Calendario',
        child: EmptyStateCard(icon: Icons.calendar_month_outlined, title: 'Próximamente', message: 'Tus parciales y entregas aparecerán acá.'),
      );
}
