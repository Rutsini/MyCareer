// ignore_for_file: curly_braces_in_flow_control_structures
import 'academic_rule.dart';
import 'subject_schedule_block.dart';

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
      this.finalOutcome,
      this.finalGrade,
      this.approvedAt,
      required this.gradeMin,
      required this.gradeMax,
      this.recoveryPolicy = RecoveryPolicy.highestGrade,
      this.startDate,
      this.endDate,
      this.notes,
      this.scheduleBlocks = const [],
      this.promotionRules = const [],
      this.regularityRules = const [],
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
  final FinalOutcome? finalOutcome;
  final double? finalGrade;
  final DateTime? approvedAt;
  final double gradeMin;
  final double gradeMax;
  final RecoveryPolicy recoveryPolicy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final List<SubjectScheduleBlock> scheduleBlocks;
  final List<AcademicRule> promotionRules;
  final List<AcademicRule> regularityRules;
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
    if (promotionRules.length > maxAcademicRulesPerCategory ||
        regularityRules.length > maxAcademicRulesPerCategory)
      return 'Podés configurar hasta $maxAcademicRulesPerCategory condiciones '
          'por categoría.';
    if (scheduleBlocks.length > maxSubjectScheduleBlocks)
      return 'Podés cargar hasta $maxSubjectScheduleBlocks horarios por materia.';
    final scheduleIds = <String>{};
    for (final block in scheduleBlocks) {
      final error = block.validate();
      if (error != null) return error;
      if (!scheduleIds.add(block.id.trim()))
        return 'Cada horario debe tener un identificador diferente.';
    }
    if (finalGrade != null &&
        (finalGrade! < gradeMin || finalGrade! > gradeMax))
      return 'La nota final debe estar dentro de la escala.';
    if (trackingMode == TrackingMode.historical) {
      if (finalOutcome == null) return 'Seleccioná el resultado final.';
      if ((finalOutcome == FinalOutcome.abandoned ||
              finalOutcome == FinalOutcome.regularized) &&
          finalGrade != null) return 'Ese resultado no admite nota final.';
    }
    return null;
  }

  Subject copyWith({
    String? id,
    List<AcademicRule>? promotionRules,
    List<AcademicRule>? regularityRules,
    RecoveryPolicy? recoveryPolicy,
    CourseStatus? courseStatus,
    List<SubjectScheduleBlock>? scheduleBlocks,
    DateTime? updatedAt,
  }) =>
      Subject(
          id: id ?? this.id,
          academicYearId: academicYearId,
          academicYear: academicYear,
          trackingMode: trackingMode,
          name: name,
          shortName: shortName,
          code: code,
          commission: commission,
          subjectType: subjectType,
          electivePoints: electivePoints,
          duration: duration,
          semester: semester,
          courseStatus: courseStatus ?? this.courseStatus,
          finalOutcome: finalOutcome,
          finalGrade: finalGrade,
          approvedAt: approvedAt,
          gradeMin: gradeMin,
          gradeMax: gradeMax,
          recoveryPolicy: recoveryPolicy ?? this.recoveryPolicy,
          startDate: startDate,
          endDate: endDate,
          notes: notes,
          scheduleBlocks:
              List.unmodifiable(scheduleBlocks ?? this.scheduleBlocks),
          promotionRules: promotionRules ?? this.promotionRules,
          regularityRules: regularityRules ?? this.regularityRules,
          createdAt: createdAt,
          updatedAt: updatedAt ?? this.updatedAt);
}
