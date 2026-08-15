import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/firebase/user_profile_service.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../domain/entities/user_profile.dart';
import '../../auth/application/auth_controller.dart';

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
    StateNotifierProvider<ProfileController, AsyncValue<void>>(
        (ref) => ProfileController(ref.watch(userProfileRepositoryProvider)));

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController(this._repository) : super(const AsyncData(null));
  final UserProfileRepository _repository;
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
}
