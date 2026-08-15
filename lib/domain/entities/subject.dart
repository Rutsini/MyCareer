// ignore_for_file: curly_braces_in_flow_control_structures
enum TrackingMode { tracked, historical }

enum SubjectType { mandatory, elective }

enum SubjectDuration { annual, semester }

enum Semester { first, second }

enum CourseStatus { pending, active, finished, abandoned }

enum AcademicCondition { noData, promoting, regular, atRisk, failed }

enum FinalOutcome { approved, promoted, regularized, failed, abandoned }

enum RecoveryPolicy { replaceGrade, highestGrade, approvalOnly }

class Subject {
  const Subject(
      {required this.id,
      required this.academicYearId,
      required this.academicYear,
      required this.trackingMode,
      required this.name,
      this.shortName,
      this.code,
      this.commission,
      required this.subjectType,
      this.electivePoints,
      required this.duration,
      this.semester,
      required this.courseStatus,
      this.currentCondition,
      this.finalOutcome,
      this.finalGrade,
      this.approvedAt,
      required this.gradeMin,
      required this.gradeMax,
      this.recoveryPolicy = RecoveryPolicy.highestGrade,
      this.startDate,
      this.endDate,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final String academicYearId;
  final int academicYear;
  final TrackingMode trackingMode;
  final String name;
  final String? shortName;
  final String? code;
  final String? commission;
  final SubjectType subjectType;
  final double? electivePoints;
  final SubjectDuration duration;
  final Semester? semester;
  final CourseStatus courseStatus;
  final AcademicCondition? currentCondition;
  final FinalOutcome? finalOutcome;
  final double? finalGrade;
  final DateTime? approvedAt;
  final double gradeMin;
  final double gradeMax;
  final RecoveryPolicy recoveryPolicy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? validate() {
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 100)
      return 'El nombre debe tener entre 2 y 100 caracteres.';
    if ((shortName?.trim().length ?? 0) > 15)
      return 'El nombre corto puede tener hasta 15 caracteres.';
    if (subjectType == SubjectType.elective &&
        (electivePoints == null || electivePoints! <= 0))
      return 'Las materias electivas requieren puntos mayores a cero.';
    if (subjectType == SubjectType.mandatory && electivePoints != null)
      return 'Una materia obligatoria no puede guardar puntos electivos.';
    if (duration == SubjectDuration.annual && semester != null)
      return 'Una materia anual no puede tener cuatrimestre.';
    if (duration == SubjectDuration.semester && semester == null)
      return 'Seleccioná el cuatrimestre.';
    if (gradeMin >= gradeMax)
      return 'La nota mínima debe ser menor a la máxima.';
    if (finalGrade != null &&
        (finalGrade! < gradeMin || finalGrade! > gradeMax))
      return 'La nota final debe estar dentro de la escala.';
    if (trackingMode == TrackingMode.tracked &&
        currentCondition != AcademicCondition.noData)
      return 'La condición inicial debe ser sin datos.';
    if (trackingMode == TrackingMode.historical) {
      if (currentCondition != null)
        return 'Una materia histórica no tiene condición actual.';
      if (finalOutcome == null) return 'Seleccioná el resultado final.';
      if ((finalOutcome == FinalOutcome.abandoned ||
              finalOutcome == FinalOutcome.regularized) &&
          finalGrade != null) return 'Ese resultado no admite nota final.';
    }
    return null;
  }
}
