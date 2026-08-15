import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subject.dart';
import 'firestore_mapper_utils.dart';

T _enumValue<T extends Enum>(List<T> values, Object? value, T fallback) =>
    values.where((item) => item.name == value).firstOrNull ?? fallback;

abstract final class SubjectMapper {
  static Subject fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final scale = d['gradeScale'] as Map<String, dynamic>? ?? const {};
    DateTime? nullableDate(Object? value) =>
        value is Timestamp ? value.toDate() : null;
    T? nullableEnum<T extends Enum>(List<T> values, Object? value) =>
        value == null ? null : values.where((e) => e.name == value).firstOrNull;
    return Subject(
        id: doc.id,
        academicYearId: d['academicYearId'] as String? ?? '',
        academicYear: (d['academicYear'] as num?)?.toInt() ?? 0,
        trackingMode: _enumValue(
            TrackingMode.values, d['trackingMode'], TrackingMode.tracked),
        name: d['name'] as String? ?? '',
        shortName: d['shortName'] as String?,
        code: d['code'] as String?,
        commission: d['commission'] as String?,
        subjectType: _enumValue(
            SubjectType.values, d['subjectType'], SubjectType.mandatory),
        electivePoints: (d['electivePoints'] as num?)?.toDouble(),
        duration: _enumValue(
            SubjectDuration.values, d['duration'], SubjectDuration.annual),
        semester: nullableEnum(Semester.values, d['semester']),
        courseStatus: _enumValue(
            CourseStatus.values, d['courseStatus'], CourseStatus.active),
        currentCondition:
            nullableEnum(AcademicCondition.values, d['currentCondition']),
        finalOutcome: nullableEnum(FinalOutcome.values, d['finalOutcome']),
        finalGrade: (d['finalGrade'] as num?)?.toDouble(),
        approvedAt: nullableDate(d['approvedAt']),
        gradeMin: numberToDouble(scale['min']),
        gradeMax: numberToDouble(scale['max'], 10),
        recoveryPolicy: _enumValue(RecoveryPolicy.values, d['recoveryPolicy'],
            RecoveryPolicy.highestGrade),
        startDate: nullableDate(d['startDate']),
        endDate: nullableDate(d['endDate']),
        notes: d['notes'] as String?,
        createdAt: dateFromFirestore(d['createdAt']),
        updatedAt: dateFromFirestore(d['updatedAt']));
  }

  static Map<String, dynamic> toMap(Subject s, {required bool creating}) => {
        'academicYearId': s.academicYearId,
        'academicYear': s.academicYear,
        'trackingMode': s.trackingMode.name,
        'name': s.name.trim(),
        'shortName': _emptyToNull(s.shortName),
        'code': _emptyToNull(s.code),
        'commission': _emptyToNull(s.commission),
        'subjectType': s.subjectType.name,
        'electivePoints':
            s.subjectType == SubjectType.elective ? s.electivePoints : null,
        'duration': s.duration.name,
        'semester':
            s.duration == SubjectDuration.semester ? s.semester?.name : null,
        'gradeScale': {'min': s.gradeMin, 'max': s.gradeMax},
        'recoveryPolicy': s.recoveryPolicy.name,
        'courseStatus': s.courseStatus.name,
        'currentCondition': s.trackingMode == TrackingMode.tracked
            ? s.currentCondition?.name
            : null,
        'finalOutcome': s.finalOutcome?.name,
        'finalGrade': s.finalGrade,
        'approvedAt':
            s.approvedAt == null ? null : Timestamp.fromDate(s.approvedAt!),
        'startDate':
            s.startDate == null ? null : Timestamp.fromDate(s.startDate!),
        'endDate': s.endDate == null ? null : Timestamp.fromDate(s.endDate!),
        'notes': _emptyToNull(s.notes),
        if (creating) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      };

  static String? _emptyToNull(String? value) =>
      value?.trim().isEmpty ?? true ? null : value!.trim();
}
