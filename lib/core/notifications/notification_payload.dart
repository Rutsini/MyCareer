import 'dart:convert';

class NotificationPayload {
  const NotificationPayload(
      {required this.evaluationId, required this.subjectId});
  final String evaluationId;
  final String subjectId;

  String encode() => jsonEncode({
        'evaluationId': evaluationId,
        'subjectId': subjectId,
      });

  static NotificationPayload? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final data = jsonDecode(value);
      if (data is! Map) {
        return null;
      }
      final evaluationId = data['evaluationId'];
      final subjectId = data['subjectId'];
      if (evaluationId is! String ||
          evaluationId.isEmpty ||
          subjectId is! String ||
          subjectId.isEmpty) {
        return null;
      }
      return NotificationPayload(
        evaluationId: evaluationId,
        subjectId: subjectId,
      );
    } catch (_) {
      return null;
    }
  }
}
