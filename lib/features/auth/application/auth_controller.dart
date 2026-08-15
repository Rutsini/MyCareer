import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/firebase/auth_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../domain/services/notification_id_generator.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthProvider)),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(firestoreProvider),
  ),
);
final authStateProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
  (ref) => AuthController(ref.watch(authRepositoryProvider), () async {
    final gateway = ref.read(localNotificationGatewayProvider);
    for (final id in await gateway.pendingIds()) {
      if (NotificationIdGenerator.isAcademic(id)) await gateway.cancel(id);
    }
  }),
);

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository, [this._beforeSignOut])
      : super(const AsyncData(null));

  final AuthRepository _repository;
  final Future<void> Function()? _beforeSignOut;

  Future<bool> signIn({required String email, required String password}) =>
      _run(() => _repository.signIn(email: email, password: password));

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) =>
      _run(() => _repository.signUp(
            name: name,
            email: email,
            password: password,
          ));

  Future<bool> signOut() => _run(() async {
        await _beforeSignOut?.call();
        await _repository.signOut();
      });

  Future<bool> _run(Future<void> Function() operation) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await operation();
      state = const AsyncData(null);
      return true;
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      state = AsyncError(
        const AppException('Ocurrió un error inesperado.'),
        stackTrace,
      );
      return false;
    }
  }
}
