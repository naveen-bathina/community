import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/config/supabase_config.dart';
import 'package:legal_unity_network/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:legal_unity_network/features/auth/data/datasources/local_auth_storage.dart';
import 'package:legal_unity_network/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser, AuthState, User;

/// Singleton SupabaseClient exposed through Riverpod when initialized.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

/// Singleton FirebaseAuth instance exposed through Riverpod as fallback.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Fallback repository used when neither Supabase nor Firebase is initialized
/// on the current platform (e.g., Web/Desktop without SUPABASE_ANON_KEY).
class UnconfiguredAuthDataSource implements AuthRepository {
  static const String _configMessage =
      'Auth backend is not configured for this platform. '
      'Pass --dart-define=SUPABASE_ANON_KEY=<your-anon-key> when running.';

  @override
  Stream<AuthUser?> get authStateChanges => const Stream<AuthUser?>.empty();

  @override
  Future<AuthUser?> get currentUser async => null;

  @override
  Future<String?> sendOtp(String phoneNumber) async => _configMessage;

  @override
  Future<String?> verifyOtp(String verificationId, String code) async =>
      _configMessage;

  @override
  Future<String?> signUpWithGoogle() async => _configMessage;

  @override
  Future<String?> submitJoinRequest(JoinRequestInput request) async =>
      _configMessage;

  @override
  Future<List<AuthUser>> getPendingJoinRequests() async => const [];

  @override
  Future<String?> reviewJoinRequest({
    required String targetUserId,
    required bool approve,
    String? rejectionReason,
  }) async =>
      _configMessage;

  @override
  Future<void> signOut() async {}
}

/// Provides the active [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    final supabase = ref.watch(supabaseClientProvider);
    return SupabaseAuthDataSource(supabase);
  }
  if (Firebase.apps.isNotEmpty) {
    final firebaseAuth = ref.watch(firebaseAuthProvider);
    return FirebaseAuthDataSource(firebaseAuth);
  }
  return UnconfiguredAuthDataSource();
});

/// Provider for persistent local auth storage.
final localAuthStorageProvider = Provider<LocalAuthStorage>((ref) {
  return LocalAuthStorage();
});

/// Primary auth state provider watched by [AuthGateScreen] and route guards.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(localAuthStorageProvider);
  return AuthNotifier(repository, storage);
});

/// Alias for [authNotifierProvider] used across screens and route guards.
final authProvider = authNotifierProvider;

/// Provider that fetches pending join requests for admin verification.
final pendingJoinRequestsProvider =
    FutureProvider.autoDispose<List<AuthUser>>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getPendingJoinRequests();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final LocalAuthStorage _storage;
  StreamSubscription<AuthUser?>? _authSubscription;

  AuthNotifier(this._authRepository, [LocalAuthStorage? storage])
      : _storage = storage ?? LocalAuthStorage(),
        super(const AuthState(isLoading: true)) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // 1. Immediately restore cached user session from persistent device storage
    AuthUser? cachedUser;
    try {
      cachedUser = await _storage.getUser();
      if (cachedUser != null && mounted) {
        state = AuthState(user: cachedUser, isLoading: false);
      }
    } catch (_) {}

    // 2. Fetch authoritative user from auth repository
    try {
      final user = await _authRepository.currentUser;
      if (user != null) {
        await _storage.saveUser(user);
        if (mounted) {
          state = AuthState(user: user, isLoading: false);
        }
      } else if (cachedUser == null) {
        if (mounted) {
          state = const AuthState(user: null, isLoading: false);
        }
      }
    } catch (e) {
      if (mounted && cachedUser == null) {
        state = const AuthState(
          user: null,
          isLoading: false,
          error: 'Failed to load authentication state',
        );
      }
    }

    // 3. Listen to auth state changes
    await _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) async {
        if (user != null) {
          await _storage.saveUser(user);
          if (mounted) {
            state = AuthState(user: user, isLoading: false);
          }
        }
      },
      onError: (Object error) {
        if (mounted && state.user == null) {
          state = state.copyWith(
            isLoading: false,
            error: error.toString(),
          );
        }
      },
    );
  }

  /// Re-fetches the current user profile (e.g. to check if admin approved an applicant).
  Future<void> refreshUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.currentUser;
      if (user != null) {
        await _storage.saveUser(user);
        if (mounted) {
          state = AuthState(user: user, isLoading: false);
        }
      } else {
        if (mounted) {
          state = state.copyWith(isLoading: false);
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to refresh profile status',
        );
      }
    }
  }

  Future<String?> sendOtp(String phoneNumber) async {
    final error = await _authRepository.sendOtp(phoneNumber);
    if (error != null && mounted) {
      state = state.copyWith(error: error);
    }
    return error;
  }

  Future<String?> verifyOtp(String verificationId, String code) async {
    final error = await _authRepository.verifyOtp(verificationId, code);
    if (error == null) {
      await refreshUser();
    } else if (mounted) {
      state = state.copyWith(error: error);
    }
    return error;
  }

  Future<String?> signUpWithGoogle() async {
    final error = await _authRepository.signUpWithGoogle();
    if (error == null) {
      await refreshUser();
    } else if (mounted) {
      state = state.copyWith(error: error);
    }
    return error;
  }

  Future<String?> submitJoinRequest(JoinRequestInput request) async {
    final error = await _authRepository.submitJoinRequest(request);
    if (error == null) {
      await refreshUser();
    } else if (mounted) {
      state = state.copyWith(error: error);
    }
    return error;
  }

  Future<String?> reviewJoinRequest({
    required String targetUserId,
    required bool approve,
    String? rejectionReason,
  }) async {
    final error = await _authRepository.reviewJoinRequest(
      targetUserId: targetUserId,
      approve: approve,
      rejectionReason: rejectionReason,
    );
    if (error == null && state.user?.uid == targetUserId) {
      await refreshUser();
    }
    return error;
  }

  Future<void> signOut() async {
    await _storage.clear();
    await _authRepository.signOut();
    if (mounted) {
      state = const AuthState(user: null, isLoading: false);
    }
    if (kDebugMode) {
      debugPrint('User signed out');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthUser? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isAuthenticated => user != null;
  bool get hasSubmittedJoinRequest => user?.hasSubmittedJoinRequest ?? false;
  bool get isApproved => user?.isApproved ?? false;
  bool get isPending => user?.isPending ?? false;
  bool get isRejected => user?.isRejected ?? false;
  bool get isBanned => user?.isBanned ?? false;
  bool get isAdmin => user?.isAdmin ?? false;
}
