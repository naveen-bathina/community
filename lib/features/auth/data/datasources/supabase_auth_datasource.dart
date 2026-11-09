import 'dart:async';
import 'dart:convert';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/features/auth/domain/repositories/auth_repository.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

/// Supabase implementation of [AuthRepository].
class SupabaseAuthDataSource implements AuthRepository {
  final SupabaseClient _supabase;
  String? _lastPhoneNumber;

  SupabaseAuthDataSource(this._supabase);

  @override
  Stream<AuthUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((authState) async {
      final session = authState.session;
      if (session == null) {
        return null;
      }
      return _mapSupabaseUser(session.user);
    });
  }

  @override
  Future<AuthUser?> get currentUser async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _mapSupabaseUser(user);
  }

  Future<AuthUser> _mapSupabaseUser(User user) async {
    UserStatus status = UserStatus.pending;
    UserRole role = UserRole.member;
    DateTime createdAt =
        DateTime.tryParse(user.createdAt) ?? DateTime.now().toUtc();
    DateTime updatedAt =
        DateTime.tryParse(user.updatedAt ?? '') ?? createdAt;

    String? firstName;
    String? lastName;
    DateTime? dateOfBirth;
    String? gender;
    String? phone = user.phone;
    String? stateBarAssociation;
    String? enrollmentNumber;
    String? photoUrl;
    String? rejectionReason;

    // 1. Check trusted app_metadata claims first (never user_metadata)
    final appMeta = user.appMetadata;
    if (appMeta['status'] is String) {
      status = _parseStatus(appMeta['status'] as String);
    }
    if (appMeta['role'] is String) {
      role = _parseRole(appMeta['role'] as String);
    }

    // 2. Fetch authoritative profile and join request fields from public.profiles
    try {
      final profile = await _supabase
          .from('profiles')
          .select(
            'id, email, phone, first_name, last_name, date_of_birth, gender, '
            'state_bar_association, enrollment_number, photo_url, '
            'rejection_reason, status, role, created_at, updated_at',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        firstName = profile['first_name'] as String?;
        lastName = profile['last_name'] as String?;
        if (profile['date_of_birth'] is String) {
          dateOfBirth = DateTime.tryParse(profile['date_of_birth'] as String);
        }
        gender = profile['gender'] as String?;
        if (profile['phone'] is String &&
            (profile['phone'] as String).isNotEmpty) {
          phone = profile['phone'] as String;
        }
        stateBarAssociation = profile['state_bar_association'] as String?;
        enrollmentNumber = profile['enrollment_number'] as String?;
        photoUrl = profile['photo_url'] as String?;
        rejectionReason = profile['rejection_reason'] as String?;
        if (profile['status'] is String) {
          status = _parseStatus(profile['status'] as String);
        }
        if (profile['role'] is String) {
          role = _parseRole(profile['role'] as String);
        }
        if (profile['created_at'] is String) {
          createdAt =
              DateTime.tryParse(profile['created_at'] as String) ?? createdAt;
        }
        if (profile['updated_at'] is String) {
          updatedAt =
              DateTime.tryParse(profile['updated_at'] as String) ?? updatedAt;
        }
      }
    } catch (_) {
      // Safe fallback if offline or row not created yet
    }

    return AuthUser(
      uid: user.id,
      email: user.email ?? '',
      phoneNumber: phone,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      stateBarAssociation: stateBarAssociation,
      enrollmentNumber: enrollmentNumber,
      photoUrl: photoUrl,
      rejectionReason: rejectionReason,
      status: status,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AuthUser _mapProfileRow(Map<String, dynamic> row) {
    final createdAt = DateTime.tryParse((row['created_at'] as String?) ?? '') ??
        DateTime.now().toUtc();
    final updatedAt = DateTime.tryParse((row['updated_at'] as String?) ?? '') ??
        createdAt;

    return AuthUser(
      uid: row['id'] as String,
      email: (row['email'] as String?) ?? '',
      phoneNumber: row['phone'] as String?,
      firstName: row['first_name'] as String?,
      lastName: row['last_name'] as String?,
      dateOfBirth: row['date_of_birth'] is String
          ? DateTime.tryParse(row['date_of_birth'] as String)
          : null,
      gender: row['gender'] as String?,
      stateBarAssociation: row['state_bar_association'] as String?,
      enrollmentNumber: row['enrollment_number'] as String?,
      photoUrl: row['photo_url'] as String?,
      rejectionReason: row['rejection_reason'] as String?,
      status: _parseStatus((row['status'] as String?) ?? 'pending'),
      role: _parseRole((row['role'] as String?) ?? 'member'),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  UserStatus _parseStatus(String raw) {
    for (final s in UserStatus.values) {
      if (s.value == raw) return s;
    }
    return UserStatus.pending;
  }

  UserRole _parseRole(String raw) {
    for (final r in UserRole.values) {
      if (r.value == raw) return r;
    }
    return UserRole.member;
  }

  @override
  Future<String?> sendOtp(String phoneNumber) async {
    try {
      final normalized = phoneNumber.trim();
      _lastPhoneNumber = normalized;
      await _supabase.auth.signInWithOtp(
        phone: normalized,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to send OTP. Please check your phone number and try again.';
    }
  }

  @override
  Future<String?> verifyOtp(String verificationId, String code) async {
    final phone =
        verificationId.isNotEmpty ? verificationId : (_lastPhoneNumber ?? '');
    if (phone.isEmpty) {
      return 'Phone number is missing. Please request a new OTP.';
    }

    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone.trim(),
        token: code.trim(),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to verify OTP code.';
    }
  }

  @override
  Future<String?> signUpWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to sign in with Google.';
    }
  }

  @override
  Future<String?> submitJoinRequest(JoinRequestInput request) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return 'You must be signed in to submit a join request.';
    }

    try {
      String? photoUrl = request.existingPhotoUrl;
      if (request.profilePhotoBytes != null) {
        try {
          final path = '${user.id}/avatar.jpg';
          await _supabase.storage.from('avatars').uploadBinary(
                path,
                request.profilePhotoBytes!,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );
          photoUrl = _supabase.storage.from('avatars').getPublicUrl(path);
        } catch (_) {
          photoUrl =
              'data:image/jpeg;base64,${base64Encode(request.profilePhotoBytes!)}';
        }
      }

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'phone': request.mobileNumber.trim(),
        'first_name': request.firstName.trim(),
        'last_name': request.lastName.trim(),
        'name': request.fullName,
        'date_of_birth': request.dateOfBirth.toIso8601String(),
        'gender': request.gender.trim(),
        'state_bar_association': request.stateBarAssociation.trim(),
        'enrollment_number': request.enrollmentNumber.trim(),
        'photo_url': photoUrl ?? '',
        'rejection_reason': null,
        'status': UserStatus.pending.value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to submit join request: $e';
    }
  }

  @override
  Future<List<AuthUser>> getPendingJoinRequests() async {
    try {
      final rows = await _supabase
          .from('profiles')
          .select()
          .eq('status', UserStatus.pending.value)
          .not('enrollment_number', 'is', null)
          .order('created_at', ascending: true);

      return (rows as List<dynamic>)
          .map((e) => _mapProfileRow(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<String?> reviewJoinRequest({
    required String targetUserId,
    required bool approve,
    String? rejectionReason,
  }) async {
    try {
      await _supabase.from('profiles').update({
        'status': approve
            ? UserStatus.approved.value
            : UserStatus.rejected.value,
        'rejection_reason': approve ? null : rejectionReason?.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', targetUserId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to update join request: $e';
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
