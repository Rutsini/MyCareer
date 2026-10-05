import '../../core/errors/app_exception.dart';

const maxFirestoreBatchWrites = 500;

void ensureAtomicDeletionCapacity(int relatedDocumentCount) {
  if (relatedDocumentCount >= maxFirestoreBatchWrites) {
    throw const AppException(
      'Hay demasiados datos relacionados para completar la operación de forma '
      'segura. Eliminá algunos elementos y volvé a intentar.',
    );
  }
}
