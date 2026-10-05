import 'package:flutter/material.dart';

import '../../../../core/formatters/subject_schedule_formatter.dart';
import '../../../../domain/entities/subject_schedule_block.dart';

class SubjectScheduleEditor extends StatelessWidget {
  const SubjectScheduleEditor({
    required this.blocks,
    required this.onChanged,
    super.key,
  });

  final List<SubjectScheduleBlock> blocks;
  final ValueChanged<List<SubjectScheduleBlock>> onChanged;

  Future<void> _edit(BuildContext context,
      [SubjectScheduleBlock? block]) async {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    SubjectScheduleBlock? result;
    if (mobile) {
      result = await showModalBottomSheet<SubjectScheduleBlock>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _ScheduleBlockForm(existing: block),
      );
    } else {
      result = await showDialog<SubjectScheduleBlock>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
            child: _ScheduleBlockForm(existing: block),
          ),
        ),
      );
    }
    final savedBlock = result;
    if (savedBlock == null) return;
    final updated = [...blocks];
    final index = updated.indexWhere((item) => item.id == savedBlock.id);
    if (index < 0) {
      updated.add(savedBlock);
    } else {
      updated[index] = savedBlock;
    }
    updated.sort((a, b) {
      final day = a.weekday.compareTo(b.weekday);
      return day != 0 ? day : a.startMinutes.compareTo(b.startMinutes);
    });
    onChanged(List.unmodifiable(updated));
  }

  @override
  Widget build(BuildContext context) => Column(
        key: const Key('subject-schedule-editor'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (blocks.isEmpty)
            const Text('Sin horarios cargados')
          else
            for (final block in blocks)
              Card(
                child: ListTile(
                  title: Text(scheduleWeekdayLabel(block.weekday)),
                  subtitle: Text([
                    formatScheduleRange(block),
                    if (block.location?.isNotEmpty == true) block.location!,
                    classModalityLabel(block.modality),
                  ].join(' · ')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') _edit(context, block);
                      if (action == 'delete') {
                        onChanged(List.unmodifiable(blocks
                            .where((item) => item.id != block.id)
                            .toList()));
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('add-schedule-block'),
              onPressed: blocks.length >= maxSubjectScheduleBlocks
                  ? null
                  : () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar horario'),
            ),
          ),
          if (blocks.length >= maxSubjectScheduleBlocks)
            Text(
              'Alcanzaste el máximo de $maxSubjectScheduleBlocks horarios.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      );
}

class _ScheduleBlockForm extends StatefulWidget {
  const _ScheduleBlockForm({this.existing});

  final SubjectScheduleBlock? existing;

  @override
  State<_ScheduleBlockForm> createState() => _ScheduleBlockFormState();
}

class _ScheduleBlockFormState extends State<_ScheduleBlockForm> {
  final _form = GlobalKey<FormState>();
  final _location = TextEditingController();
  final _link = TextEditingController();
  late int _weekday;
  late int _start;
  late int _end;
  late ClassModality _modality;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _weekday = existing?.weekday ?? DateTime.monday;
    _start = existing?.startMinutes ?? 17 * 60;
    _end = existing?.endMinutes ?? 19 * 60;
    _modality = existing?.modality ?? ClassModality.presential;
    _location.text = existing?.location ?? '';
    _link.text = existing?.virtualLink ?? '';
  }

  @override
  void dispose() {
    _location.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final value = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60),
    );
    if (picked != null) {
      setState(() {
        final minutes = picked.hour * 60 + picked.minute;
        if (start) {
          _start = minutes;
        } else {
          _end = minutes;
        }
        _timeError = null;
      });
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final block = SubjectScheduleBlock(
      id: widget.existing?.id ??
          '${DateTime.now().microsecondsSinceEpoch}-$_weekday-$_start',
      weekday: _weekday,
      startMinutes: _start,
      endMinutes: _end,
      location: _optional(_location.text),
      modality: _modality,
      virtualLink: _optional(_link.text),
    );
    final error = block.validate();
    if (error != null) {
      setState(() => _timeError = error);
      return;
    }
    Navigator.pop(context, block);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _form,
            child: Column(
              key: const Key('schedule-block-form'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existing == null
                      ? 'Agregar horario'
                      : 'Editar horario',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  key: const Key('schedule-weekday'),
                  initialValue: _weekday,
                  decoration: const InputDecoration(labelText: 'Día'),
                  items: [
                    for (var day = 1; day <= 7; day++)
                      DropdownMenuItem(
                        value: day,
                        child: Text(scheduleWeekdayLabel(day)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _weekday = value!),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Desde',
                      minutes: _start,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: 'Hasta',
                      minutes: _end,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ]),
                if (_timeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _timeError!,
                    key: const Key('schedule-time-error'),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<ClassModality>(
                  key: const Key('schedule-modality'),
                  initialValue: _modality,
                  decoration: const InputDecoration(labelText: 'Modalidad'),
                  items: ClassModality.values
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(classModalityLabel(value)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _modality = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _location,
                  maxLength: 200,
                  decoration:
                      const InputDecoration(labelText: 'Aula / ubicación'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _link,
                  maxLength: 2048,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Enlace'),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      key: const Key('save-schedule-block'),
                      onPressed: _save,
                      child: const Text('Guardar horario'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        key: Key('schedule-time-${label.toLowerCase()}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(formatScheduleMinutes(minutes)),
        ),
      );
}

String? _optional(String value) => value.trim().isEmpty ? null : value.trim();
