import 'package:legal_unity_network/shared/models/user_model.dart';

abstract class ProfileRepository {
  /// Returns approved members matching optional search query, practice area, and availability.
  Future<List<UserModel>> getApprovedMembers({
    String? searchQuery,
    String? practiceArea,
    AvailabilityStatus? availability,
  });

  /// Returns a single user's profile by [userId].
  Future<UserModel?> getProfile(String userId);

  /// Updates the current user's profile details.
  /// Returns null on success or an error message on failure.
  Future<String?> updateProfile(UserModel updatedProfile);
}
