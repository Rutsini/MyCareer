import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/firebase/auth_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/user_profile.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
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
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

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

  Future<bool> signOut() => _run(_repository.signOut);

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
