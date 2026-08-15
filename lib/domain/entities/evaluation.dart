enum EvaluationType {
  partial,
  recovery,
  practicalWork,
  deliverable,
  project,
  colloquium,
  finalExam,
  other,
}

enum EvaluationStatus {
  pending,
  submitted,
  approved,
  failed,
  absent,
  recovered
}

class Evaluation {
  const Evaluation({
    required this.id,
    required this.subjectId,
    required this.academicYear,
    required this.name,
    required this.type,
    required this.date,
    required this.allDay,
    required this.mandatory,
    required this.countsTowardAverage,
    this.grade,
    required this.maxGrade,
    this.minimumPassingGradeOverride,
    required this.weight,
    this.presented,
    required this.status,
    required this.isRecovery,
    this.recoveryOfEvaluationId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subjectId;
  final int academicYear;
  final String name;
  final EvaluationType type;
  final DateTime date;
  final bool allDay;
  final bool mandatory;
  final bool countsTowardAverage;
  final double? grade;
  final double maxGrade;
  final double? minimumPassingGradeOverride;
  final double weight;
  final bool? presented;
  final EvaluationStatus status;
  final bool isRecovery;
  final String? recoveryOfEvaluationId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? validate() {
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 100) {
      return 'El nombre debe tener entre 2 y 100 caracteres.';
    }
    if (subjectId.trim().isEmpty) return 'Seleccioná una materia.';
    if (maxGrade <= 0) return 'La nota máxima debe ser mayor a cero.';
    if (grade != null && (grade! < 0 || grade! > maxGrade)) {
      return 'La nota debe estar entre 0 y la nota máxima.';
    }
    if (weight <= 0) return 'El peso debe ser mayor a cero.';
    if (minimumPassingGradeOverride != null &&
        (minimumPassingGradeOverride! < 0 ||
            minimumPassingGradeOverride! > maxGrade)) {
      return 'La nota mínima de aprobación debe estar dentro de la escala.';
    }
    if (isRecovery) {
      if (type != EvaluationType.recovery) {
        return 'Un recuperatorio debe tener tipo Recuperatorio.';
      }
      if (recoveryOfEvaluationId == null || recoveryOfEvaluationId!.isEmpty) {
        return 'Seleccioná la evaluación que recupera.';
      }
      if (id.isNotEmpty && recoveryOfEvaluationId == id) {
        return 'Una evaluación no puede recuperarse a sí misma.';
      }
    } else if (recoveryOfEvaluationId != null) {
      return 'Una evaluación normal no puede vincular un recuperatorio.';
    }
    return null;
  }

  Evaluation copyWith({
    String? id,
    String? subjectId,
    int? academicYear,
    String? name,
    EvaluationType? type,
    DateTime? date,
    bool? allDay,
    bool? mandatory,
    bool? countsTowardAverage,
    double? grade,
    bool clearGrade = false,
    double? maxGrade,
    double? minimumPassingGradeOverride,
    bool clearMinimumPassingGradeOverride = false,
    double? weight,
    bool? presented,
    bool clearPresented = false,
    EvaluationStatus? status,
    bool? isRecovery,
    String? recoveryOfEvaluationId,
    bool clearRecoveryOfEvaluationId = false,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Evaluation(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        academicYear: academicYear ?? this.academicYear,
        name: name ?? this.name,
        type: type ?? this.type,
        date: date ?? this.date,
        allDay: allDay ?? this.allDay,
        mandatory: mandatory ?? this.mandatory,
        countsTowardAverage: countsTowardAverage ?? this.countsTowardAverage,
        grade: clearGrade ? null : grade ?? this.grade,
        maxGrade: maxGrade ?? this.maxGrade,
        minimumPassingGradeOverride: clearMinimumPassingGradeOverride
            ? null
            : minimumPassingGradeOverride ?? this.minimumPassingGradeOverride,
        weight: weight ?? this.weight,
        presented: clearPresented ? null : presented ?? this.presented,
        status: status ?? this.status,
        isRecovery: isRecovery ?? this.isRecovery,
        recoveryOfEvaluationId: clearRecoveryOfEvaluationId
            ? null
            : recoveryOfEvaluationId ?? this.recoveryOfEvaluationId,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
