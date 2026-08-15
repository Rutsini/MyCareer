import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/core/notifications/notification_payload.dart';

void main() {
  test('payload conserva evaluationId y subjectId', () {
    const payload = NotificationPayload(evaluationId: 'e1', subjectId: 's1');
    final parsed = NotificationPayload.tryParse(payload.encode());
    expect(parsed?.evaluationId, 'e1');
    expect(parsed?.subjectId, 's1');
  });

  test('payload inválido no lanza excepción', () {
    expect(NotificationPayload.tryParse('not-json'), isNull);
    expect(NotificationPayload.tryParse('{"evaluationId":"e"}'), isNull);
  });
}
