import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/auth_exception.dart';
import '../../domain/entities/user_profile.dart';
import '../firebase/auth_service.dart';

abstract interface class AuthRepository {
  Stream<UserProfile?> authStateChanges();
  UserProfile? get currentUser;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._service, this._firestore);

  final AuthService _service;
  final FirebaseFirestore _firestore;

  @override
  Stream<UserProfile?> authStateChanges() =>
      _service.authStateChanges().map(_toProfile);

  @override
  UserProfile? get currentUser => _toProfile(_service.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _service.signIn(email: email.trim(), password: password);
    } on FirebaseAuthException catch (error) {
      throw _translate(error);
    } catch (error) {
      throw AuthException('No pudimos iniciar sesión. Intentá nuevamente.',
          cause: error);
    }
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    User? createdUser;
    try {
      final credential = await _service.signUp(
        email: email.trim(),
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        throw const AuthException('No pudimos crear la cuenta.');
      }
      await createdUser.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(createdUser.uid).set({
        'displayName': name.trim(),
        'email': email.trim(),
        'career': {
          'name': null,
          'currentYear': null,
          'totalSubjects': null,
          'requiredElectivePoints': null,
        },
        'settings': {
          'theme': 'system',
          'defaultGradeMin': 0,
          'defaultGradeMax': 10,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': AppConstants.schemaVersion,
      });
    } on FirebaseAuthException catch (error) {
      throw _translate(error);
    } on FirebaseException catch (error) {
      // Auth ya fue creado. Se conserva la cuenta para evitar una eliminacion
      // riesgosa; un reintento/flujo de reparacion puede completar el perfil.
      throw AuthException(
        'La cuenta fue creada, pero no pudimos guardar tu perfil. '
        'Iniciá sesión e intentá nuevamente más tarde.',
        cause: error,
      );
    } on AuthException {
      rethrow;
    } catch (error) {
      throw AuthException('No pudimos crear la cuenta. Intentá nuevamente.',
          cause: error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _service.signOut();
    } catch (error) {
      throw AuthException('No pudimos cerrar la sesión.', cause: error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _service.sendPasswordResetEmail(email.trim());
    } on FirebaseAuthException catch (error) {
      throw _translate(error);
    }
  }

  UserProfile? _toProfile(User? user) => user == null
      ? null
      : UserProfile(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
        );

  AuthException _translate(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-email' => 'El correo ingresado no es válido.',
      'user-not-found' => 'No existe un usuario con ese correo.',
      'wrong-password' ||
      'invalid-credential' =>
        'El correo o la contraseña no son correctos.',
      'email-already-in-use' => 'Ese correo ya está registrado.',
      'weak-password' => 'La contraseña es demasiado débil.',
      'network-request-failed' => 'Hay un problema de conexión. Revisá tu red.',
      'too-many-requests' => 'Hubo demasiados intentos. Esperá un momento.',
      'user-disabled' => 'Esta cuenta fue deshabilitada.',
      _ => 'No pudimos completar la operación. Intentá nuevamente.',
    };
    return AuthException(message, cause: error);
  }
}
