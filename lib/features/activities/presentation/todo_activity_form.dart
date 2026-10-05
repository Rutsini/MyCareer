import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../domain/entities/todo_activity.dart';
import '../../subjects/application/subject_controller.dart';
import '../application/todo_activity_controller.dart';

Future<bool?> showTodoActivityForm(
  BuildContext context, {
  DateTime? day,
  TodoActivity? activity,
}) {
  final form = TodoActivityForm(day: day, activity: activity);
  if (MediaQuery.sizeOf(context).width < 700) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: form,
      ),
    );
  }
  return showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: form,
      ),
    ),
  );
}

class TodoActivityForm extends ConsumerStatefulWidget {
  const TodoActivityForm({this.day, this.activity, super.key});

  final DateTime? day;
  final TodoActivity? activity;

  @override
  ConsumerState<TodoActivityForm> createState() => _TodoActivityFormState();
}

class _TodoActivityFormState extends ConsumerState<TodoActivityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _day;
  String? _subjectId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    _title = TextEditingController(text: activity?.title);
    _description = TextEditingController(text: activity?.description);
    final initialDay = activity?.day ?? widget.day ?? DateTime.now();
    _day = DateTime(initialDay.year, initialDay.month, initialDay.day);
    _subjectId = activity?.subjectId;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _selectDay() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (selected != null && mounted) {
      final subjects = ref.read(subjectsProvider).valueOrNull ?? const [];
      setState(() {
        _day = DateTime(selected.year, selected.month, selected.day);
        if (!subjects.any((subject) =>
            subject.id == _subjectId && subject.academicYear == _day.year)) {
          _subjectId = null;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.activity;
    final subjects = ref.read(subjectsProvider).valueOrNull ?? const [];
    final subjectId = subjects.any((subject) =>
            subject.id == _subjectId && subject.academicYear == _day.year)
        ? _subjectId
        : null;
    final activity = TodoActivity(
      id: existing?.id ?? '',
      title: _title.text,
      description: _description.text.trim().isEmpty ? null : _description.text,
      day: _day,
      subjectId: subjectId,
      isCompleted: existing?.isCompleted ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final id =
        await ref.read(todoActivityControllerProvider.notifier).save(activity);
    if (!mounted) return;
    if (id != null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final controller = ref.watch(todoActivityControllerProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.activity == null ? 'Nueva actividad' : 'Editar actividad',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              autofocus: true,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                return length < 2 || length > 100
                    ? 'Ingresá entre 2 y 100 caracteres.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration:
                  const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectDay,
              icon: const Icon(Icons.calendar_today),
              label: Text(_formatDay(_day)),
            ),
            const SizedBox(height: 12),
            subjects.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('No pudimos cargar las materias.'),
              data: (items) {
                final yearSubjects = items
                    .where((subject) => subject.academicYear == _day.year)
                    .toList();
                final selectedSubjectId =
                    yearSubjects.any((subject) => subject.id == _subjectId)
                        ? _subjectId
                        : null;
                return DropdownButtonFormField<String?>(
                  key: ValueKey(
                      'todo-subject-${_day.year}-${selectedSubjectId ?? 'none'}'),
                  initialValue: selectedSubjectId,
                  decoration: InputDecoration(
                      labelText: 'Materia de ${_day.year} (opcional)',
                      helperText: yearSubjects.isEmpty
                          ? 'No hay materias cargadas para este año.'
                          : null),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin materia'),
                    ),
                    ...yearSubjects.map((subject) => DropdownMenuItem<String?>(
                          value: subject.id,
                          child: Text(subject.name),
                        )),
                  ],
                  onChanged: (value) => setState(() => _subjectId = value),
                );
              },
            ),
            if (controller.hasError) ...[
              const SizedBox(height: 12),
              Text(
                controller.error is AppException
                    ? (controller.error! as AppException).message
                    : 'No pudimos guardar la actividad.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Guardando...' : 'Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDay(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
