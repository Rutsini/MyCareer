class TodoActivity {
  const TodoActivity({
    required this.id,
    required this.title,
    this.description,
    required this.day,
    this.subjectId,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime day;
  final String? subjectId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? validate() {
    final normalizedTitle = title.trim();
    if (normalizedTitle.length < 2 || normalizedTitle.length > 100) {
      return 'El título debe tener entre 2 y 100 caracteres.';
    }
    if ((description?.trim().length ?? 0) > 1000) {
      return 'La descripción puede tener hasta 1000 caracteres.';
    }
    if (subjectId != null && subjectId!.trim().isEmpty) {
      return 'La materia seleccionada no es válida.';
    }
    return null;
  }

  TodoActivity copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? day,
    String? subjectId,
    bool clearSubject = false,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TodoActivity(
        id: id ?? this.id,
        title: title ?? this.title,
        description: clearDescription ? null : description ?? this.description,
        day: day ?? this.day,
        subjectId: clearSubject ? null : subjectId ?? this.subjectId,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
