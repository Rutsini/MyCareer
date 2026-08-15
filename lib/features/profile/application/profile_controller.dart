import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/firebase/user_profile_service.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../domain/entities/user_profile.dart';
import '../../auth/application/auth_controller.dart';
import '../../notifications/application/notification_controller.dart';
import '../../../domain/entities/notification_settings.dart';

String requireUserId(Ref ref) {
  final id = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (id == null) throw const AppException('Tu sesión ya no está disponible.');
  return id;
}

final userProfileServiceProvider = Provider((ref) =>
    UserProfileService(ref.watch(firestoreProvider), requireUserId(ref)));
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) =>
    FirebaseUserProfileRepository(ref.watch(userProfileServiceProvider)));
final userProfileProvider = StreamProvider<UserProfile>(
    (ref) => ref.watch(userProfileRepositoryProvider).watchProfile());
final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) =>
        ProfileController(ref.watch(userProfileRepositoryProvider),
            ref.watch(notificationCoordinatorProvider)));

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController(this._repository, [this._notifications])
      : super(const AsyncData(null));
  final UserProfileRepository _repository;
  final NotificationCoordinator? _notifications;
  Future<bool> save(CareerSettings settings) async {
    state = const AsyncLoading();
    try {
      await _repository.updateCareer(settings);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state =
          AsyncError(const AppException('No pudimos guardar tu perfil.'), st);
      return false;
    }
  }

  Future<bool> enableNotifications(NotificationSettings current) async {
    state = const AsyncLoading();
    try {
      await _notifications?.initialize();
      if (await _notifications?.requestPermission() != true) {
        state = AsyncError(
          const AppException('Permiso de notificaciones desactivado.'),
          StackTrace.current,
        );
        return false;
      }
      await _repository
          .updateNotificationSettings(current.copyWith(enabled: true));
      await _notifications?.synchronize();
      state = const AsyncData(null);
      return true;
    } catch (_, st) {
      state = AsyncError(
          const AppException('No pudimos actualizar tus recordatorios.'), st);
      return false;
    }
  }

  Future<bool> saveNotifications(NotificationSettings settings) async {
    state = const AsyncLoading();
    try {
      await _repository.updateNotificationSettings(settings);
      if (settings.enabled) {
        await _notifications?.synchronize();
      } else {
        await _notifications?.cancelAcademic();
      }
      state = const AsyncData(null);
      return true;
    } catch (_, st) {
      state = AsyncError(
          const AppException('No pudimos actualizar tus recordatorios.'), st);
      return false;
    }
  }
}
