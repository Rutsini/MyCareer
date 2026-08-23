import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/core/notifications/local_notification_gateway.dart';
import 'package:my_career/data/repositories/auth_repository.dart';
import 'package:my_career/data/repositories/user_profile_repository.dart';
import 'package:my_career/domain/entities/notification_settings.dart';
import 'package:my_career/domain/entities/user_profile.dart';
import 'package:my_career/features/auth/application/auth_controller.dart';
import 'package:my_career/features/notifications/application/notification_controller.dart';
import 'package:my_career/features/profile/application/profile_controller.dart';
import 'package:my_career/features/profile/presentation/screens/profile_screen.dart';

class _Profiles implements UserProfileRepository {
  _Profiles(this.profile);
  final UserProfile profile;
  CareerSettings? saved;
  @override
  Stream<UserProfile> watchProfile() => Stream.value(profile);
  @override
  Future<void> updateCareer(CareerSettings settings) async => saved = settings;
  @override
  Future<void> updateNotificationSettings(
      NotificationSettings settings) async {}
}

class _Auth implements AuthRepository {
  @override
  UserProfile? get currentUser => null;
  @override
  Stream<UserProfile?> authStateChanges() => Stream.value(null);
  @override
  Future<void> signIn(
      {required String email, required String password}) async {}
  @override
  Future<void> signUp(
      {required String name,
      required String email,
      required String password}) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

void main() {
  testWidgets(
      'perfil configurado colapsa, guarda y resume; notificaciones expanden',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const profile = UserProfile(
        id: 'u',
        email: 'maximo@test.com',
        displayName: 'Maximo',
        career: CareerSettings(
            name: 'Ingeniería en Sistemas',
            currentYear: 4,
            totalSubjects: 45,
            requiredElectivePoints: 30),
        settings:
            UserSettings(notifications: NotificationSettings(enabled: true)));
    final profiles = _Profiles(profile);
    await tester.pumpWidget(ProviderScope(overrides: [
      userProfileProvider.overrideWith((_) => Stream.value(profile)),
      userProfileRepositoryProvider.overrideWithValue(profiles),
      profileControllerProvider
          .overrideWith((_) => ProfileController(profiles)),
      authControllerProvider.overrideWith((_) => AuthController(_Auth())),
      notificationPermissionProvider
          .overrideWith((ref) => NotificationPermissionState.granted),
    ], child: const MaterialApp(home: Scaffold(body: ProfileScreen()))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ingeniería en Sistemas'), findsOneWidget);
    expect(find.textContaining('Año de carrera: 4'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Carrera'), findsNothing);
    await tester.tap(find.text('Configuración académica'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(4));
    await tester.enterText(find.byType(TextField).first, 'Sistemas UTN');
    final save = find.widgetWithText(FilledButton, 'Guardar');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(profiles.saved?.name, 'Sistemas UTN');
    expect(find.text('Perfil guardado.'), findsOneWidget);
    expect(find.textContaining('Sistemas UTN'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.scrollUntilVisible(
        find.text('Notificaciones y recordatorios'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Activadas · 1 día antes'), findsOneWidget);
    expect(find.text('Recordatorios por defecto'), findsNothing);
    await tester.tap(find.text('Notificaciones y recordatorios'));
    await tester.pumpAndSettle();
    expect(find.text('Recordatorios por defecto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
