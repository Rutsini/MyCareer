class EvaluationReminder {
  const EvaluationReminder({
    required this.id,
    required this.offsetMinutes,
    this.enabled = true,
  });

  final String id;
  final int offsetMinutes;
  final bool enabled;

  String? validate() {
    if (id.trim().isEmpty) {
      return 'El recordatorio debe tener un identificador.';
    }
    if (offsetMinutes < 0) return 'El tiempo del recordatorio no es válido.';
    return null;
  }
}
