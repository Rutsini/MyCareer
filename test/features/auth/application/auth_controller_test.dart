import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/data/repositories/auth_repository.dart';
import 'package:my_career/domain/entities/user_profile.dart';
import 'package:my_career/features/auth/application/auth_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  bool signInCalled = false;
  @override
  UserProfile? get currentUser => null;
  @override
  Stream<UserProfile?> authStateChanges() => const Stream.empty();
  @override
  Future<void> signIn({required String email, required String password}) async => signInCalled = true;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> signUp({required String name, required String email, required String password}) async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

void main() {
  test('AuthController delega el inicio de sesión al repositorio', () async {
    final repository = _FakeAuthRepository();
    final controller = AuthController(repository);
    final success = await controller.signIn(email: 'user@example.com', password: '123456');
    expect(success, isTrue);
    expect(repository.signInCalled, isTrue);
    expect(controller.state.hasError, isFalse);
  });
}
