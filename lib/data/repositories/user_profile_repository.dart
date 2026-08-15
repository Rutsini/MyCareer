import '../../domain/entities/user_profile.dart';
import '../firebase/user_profile_service.dart';
import '../mappers/user_profile_mapper.dart';

abstract interface class UserProfileRepository {
  Stream<UserProfile> watchProfile();
  Future<void> updateCareer(CareerSettings settings);
}

class FirebaseUserProfileRepository implements UserProfileRepository {
  FirebaseUserProfileRepository(this._service);
  final UserProfileService _service;
  @override
  Stream<UserProfile> watchProfile() =>
      _service.watch().map(UserProfileMapper.fromDocument);
  @override
  Future<void> updateCareer(CareerSettings s) => _service.updateCareer({
        'name': s.name,
        'currentYear': s.currentYear,
        'totalSubjects': s.totalSubjects,
        'requiredElectivePoints': s.requiredElectivePoints
      });
}
