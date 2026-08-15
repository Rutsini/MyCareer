// ignore_for_file: curly_braces_in_flow_control_structures
class AcademicYear {
  const AcademicYear(
      {required this.id,
      required this.year,
      required this.isCurrent,
      this.startDate,
      this.endDate,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final int year;
  final bool isCurrent;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? validate() {
    if (year < 1900 || year > 2200) return 'Ingresá un año válido.';
    if (startDate != null && endDate != null && !startDate!.isBefore(endDate!))
      return 'La fecha de inicio debe ser anterior a la fecha de fin.';
    return null;
  }
}
