import 'package:flutter/material.dart';

import '../../../../core/formatters/academic_rule_type_formatter.dart';
import '../../../../domain/entities/academic_rule.dart';

class AcademicRuleTypeHelpButton extends StatelessWidget {
  const AcademicRuleTypeHelpButton({required this.type, super.key});
  final AcademicRuleType type;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.info_outline),
        tooltip: 'Ayuda sobre ${academicRuleTypeLabel(type)}',
        visualDensity: VisualDensity.compact,
        onPressed: () => showAcademicRuleTypeHelp(context, type),
      );
}

Future<void> showAcademicRuleTypeHelp(
    BuildContext context, AcademicRuleType type) {
  final title = academicRuleTypeLabel(type);
  final description = academicRuleTypeDescription(type);
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleLarge)),
          ]),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: Text(description)),
        ]),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.info_outline),
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'))
      ],
    ),
  );
}
