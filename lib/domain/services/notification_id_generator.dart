abstract final class NotificationIdGenerator {
  static const int academicIdBase = 100000000;
  static const int academicIdLimit = 2100000000;

  static int generate(String evaluationId, String reminderId) {
    var hash = 0x811c9dc5;
    for (final unit in '$evaluationId\u0000$reminderId'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return academicIdBase + (hash % (academicIdLimit - academicIdBase));
  }

  static bool isAcademic(int id) =>
      id >= academicIdBase && id < academicIdLimit;
}
