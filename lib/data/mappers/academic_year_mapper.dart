import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/academic_year.dart';
import 'firestore_mapper_utils.dart';

abstract final class AcademicYearMapper {
  static AcademicYear fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AcademicYear(
        id: doc.id,
        year: (data['year'] as num?)?.toInt() ?? int.tryParse(doc.id) ?? 0,
        isCurrent: data['isCurrent'] as bool? ?? false,
        startDate: data['startDate'] is Timestamp
            ? (data['startDate'] as Timestamp).toDate()
            : null,
        endDate: data['endDate'] is Timestamp
            ? (data['endDate'] as Timestamp).toDate()
            : null,
        createdAt: dateFromFirestore(data['createdAt']),
        updatedAt: dateFromFirestore(data['updatedAt']));
  }
}
