const maxSubjectScheduleBlocks = 10;

enum ClassModality { presential, virtual, hybrid }

class SubjectScheduleBlock {
  const SubjectScheduleBlock({
    required this.id,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.location,
    this.modality = ClassModality.presential,
    this.virtualLink,
  });

  final String id;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String? location;
  final ClassModality modality;
  final String? virtualLink;

  String? validate() {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty || normalizedId.length > 100) {
      return 'El horario necesita un identificador válido.';
    }
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      return 'Seleccioná un día válido.';
    }
    if (startMinutes < 0 ||
        startMinutes >= 1440 ||
        endMinutes <= 0 ||
        endMinutes > 1440) {
      return 'Seleccioná horarios válidos.';
    }
    if (startMinutes >= endMinutes) {
      return 'La hora de fin debe ser posterior a la hora de inicio.';
    }
    if ((location?.trim().length ?? 0) > 200) {
      return 'El aula o ubicación puede tener hasta 200 caracteres.';
    }
    if ((virtualLink?.trim().length ?? 0) > 2048) {
      return 'El enlace puede tener hasta 2048 caracteres.';
    }
    return null;
  }

  SubjectScheduleBlock copyWith({
    String? id,
    int? weekday,
    int? startMinutes,
    int? endMinutes,
    String? location,
    bool clearLocation = false,
    ClassModality? modality,
    String? virtualLink,
    bool clearVirtualLink = false,
  }) =>
      SubjectScheduleBlock(
        id: id ?? this.id,
        weekday: weekday ?? this.weekday,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
        location: clearLocation ? null : location ?? this.location,
        modality: modality ?? this.modality,
        virtualLink: clearVirtualLink ? null : virtualLink ?? this.virtualLink,
      );
}
