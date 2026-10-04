import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/core/errors/app_exception.dart';
import 'package:my_career/data/firebase/atomic_delete_guard.dart';

void main() {
  test('admite el máximo de documentos relacionados en un batch', () {
    expect(
      () => ensureAtomicDeletionCapacity(maxFirestoreBatchWrites - 1),
      returnsNormally,
    );
  });

  test('rechaza la eliminación antes de superar el batch de Firestore', () {
    expect(
      () => ensureAtomicDeletionCapacity(maxFirestoreBatchWrites),
      throwsA(isA<AppException>()),
    );
  });
}
