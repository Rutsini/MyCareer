import '../../core/errors/app_exception.dart';

const maxFirestoreBatchWrites = 500;

void ensureAtomicDeletionCapacity(int relatedDocumentCount) {
  if (relatedDocumentCount >= maxFirestoreBatchWrites) {
    throw const AppException(
      'Hay demasiadas evaluaciones para eliminarlas de forma segura. '
      'Eliminá algunas evaluaciones y volvé a intentar.',
    );
  }
}
