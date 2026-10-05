import '../../domain/entities/subject_schedule_block.dart';

abstract final class SubjectScheduleBlockMapper {
  static List<SubjectScheduleBlock> fromValue(Object? value) {
    if (value is! List) return const [];
    return value.map(_tryFromMap).whereType<SubjectScheduleBlock>().toList();
  }

  static SubjectScheduleBlock? _tryFromMap(Object? value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final modalityName = map['modality'];
    final modality = ClassModality.values
            .where((item) => item.name == modalityName)
            .firstOrNull ??
        ClassModality.presential;
    final block = SubjectScheduleBlock(
      id: map['id'] is String ? map['id'] as String : '',
      weekday: map['weekday'] is num ? (map['weekday'] as num).toInt() : 0,
      startMinutes: map['startMinutes'] is num
          ? (map['startMinutes'] as num).toInt()
          : -1,
      endMinutes:
          map['endMinutes'] is num ? (map['endMinutes'] as num).toInt() : -1,
      location: map['location'] is String ? map['location'] as String : null,
      modality: modality,
      virtualLink:
          map['virtualLink'] is String ? map['virtualLink'] as String : null,
    );
    return block.validate() == null ? block : null;
  }

  static List<Map<String, Object?>> toList(List<SubjectScheduleBlock> blocks) =>
      blocks
          .map((block) => {
                'id': block.id.trim(),
                'weekday': block.weekday,
                'startMinutes': block.startMinutes,
                'endMinutes': block.endMinutes,
                'location': _emptyToNull(block.location),
                'modality': block.modality.name,
                'virtualLink': _emptyToNull(block.virtualLink),
              })
          .toList();

  static String? _emptyToNull(String? value) =>
      value?.trim().isEmpty ?? true ? null : value!.trim();
}
