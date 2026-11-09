import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';

abstract class AuthRepository {
  /// Stream of authentication state changes (emits null when signed out).
  Stream<AuthUser?> get authStateChanges;

  /// Returns the currently authenticated user and their profile status/role.
  Future<AuthUser?> get currentUser;

  /// Sends a one-time passcode (OTP) to the specified [phoneNumber].
  /// Returns null on success or a user-facing error message on failure.
  Future<String?> sendOtp(String phoneNumber);

  /// Verifies the [code] against the [verificationId] (or phone number).
  /// Returns null on success or a user-facing error message on failure.
  Future<String?> verifyOtp(String verificationId, String code);

  /// Initiates Google OAuth sign-in.
  /// Returns null on success or a user-facing error message on failure.
  Future<String?> signUpWithGoogle();

  /// Submits the user's Join Request details for admin verification.
  /// Returns null on success or a user-facing error message on failure.
  Future<String?> submitJoinRequest(JoinRequestInput request);

  /// Fetches all pending join requests awaiting admin verification.
  Future<List<AuthUser>> getPendingJoinRequests();

  /// Approves or rejects a user's join request (admin action).
  /// Returns null on success or a user-facing error message on failure.
  Future<String?> reviewJoinRequest({
    required String targetUserId,
    required bool approve,
    String? rejectionReason,
  });

  /// Fetches all registered / approved members (for Super User admin assignment).
  Future<List<AuthUser>> getAllMembers();

  /// Updates a user's role (e.g. appointing Founding Admin or Admin).
  Future<String?> updateUserRole({
    required String targetUserId,
    required UserRole newRole,
  });

  /// Appoints a default admin by email address.
  Future<String?> setDefaultAdminByEmail(
    String email, {
    UserRole role = UserRole.foundingAdmin,
  });

  /// Signs out the current user and clears the local session.
  Future<void> signOut();
}
