import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/features/auth/data/datasources/local_auth_storage.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/features/auth/domain/repositories/auth_repository.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/auth_gate_screen.dart';
import 'package:legal_unity_network/features/profile/domain/repositories/profile_repository.dart';
import 'package:legal_unity_network/features/profile/presentation/providers/profile_provider.dart';
import 'package:legal_unity_network/features/wall/domain/entities/community_post.dart';
import 'package:legal_unity_network/features/wall/domain/repositories/wall_repository.dart';
import 'package:legal_unity_network/features/wall/presentation/providers/wall_provider.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePersistenceAuthRepo implements AuthRepository {
  AuthUser? _currentUser;
  final StreamController<AuthUser?> _streamController =
      StreamController<AuthUser?>.broadcast();

  FakePersistenceAuthRepo(this._currentUser);

  @override
  Stream<AuthUser?> get authStateChanges => _streamController.stream;

  @override
  Future<AuthUser?> get currentUser async => _currentUser;

  @override
  Future<String?> sendOtp(String phoneNumber) async => null;

  @override
  Future<String?> verifyOtp(String verificationId, String code) async => null;

  @override
  Future<String?> signUpWithGoogle() async => null;

  @override
  Future<String?> submitJoinRequest(JoinRequestInput request) async => null;

  @override
  Future<List<AuthUser>> getPendingJoinRequests() async => const [];

  @override
  Future<String?> reviewJoinRequest({
    required String targetUserId,
    required bool approve,
    String? rejectionReason,
  }) async =>
      null;

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _streamController.add(null);
  }
}

class FakeWallRepoForPersistence implements WallRepository {
  @override
  Future<List<CommunityPost>> getPosts() async => const [];

  @override
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorRole,
    required String content,
    String category = 'General',
    List<String> imageUrls = const [],
    List<String> links = const [],
    List<String> docUrls = const [],
  }) async {}

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {}

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {}
}

class FakeProfileRepoForPersistence implements ProfileRepository {
  @override
  Future<List<UserModel>> getApprovedMembers({
    String? searchQuery,
    String? practiceArea,
    AvailabilityStatus? availability,
  }) async =>
      const [];

  @override
  Future<UserModel?> getProfile(String userId) async => null;

  @override
  Future<String?> updateProfile(UserModel updatedProfile) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'AuthUser serializes to and deserializes from JSON correctly',
    () {
      final user = AuthUser(
        uid: 'user-persist-123',
        email: 'advocate.sharma@legalunity.org',
        phoneNumber: '+919876543210',
        firstName: 'Vikram',
        lastName: 'Sharma',
        gender: 'Male',
        stateBarAssociation: 'Bar Council of Delhi',
        enrollmentNumber: 'D/1234/2015',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final json = user.toJson();
      final recovered = AuthUser.fromJson(json);

      expect(recovered.uid, equals(user.uid));
      expect(recovered.email, equals(user.email));
      expect(recovered.fullName, equals('Vikram Sharma'));
      expect(recovered.stateBarAssociation, equals('Bar Council of Delhi'));
      expect(recovered.enrollmentNumber, equals('D/1234/2015'));
      expect(recovered.status, equals(UserStatus.approved));
      expect(recovered.role, equals(UserRole.member));
    },
  );

  testWidgets(
    'Maintains logged-in state across app sessions until user explicitly signs out',
    (WidgetTester tester) async {
      final loggedInUser = AuthUser(
        uid: 'user-persist-123',
        email: 'advocate.sharma@legalunity.org',
        phoneNumber: '+919876543210',
        firstName: 'Vikram',
        lastName: 'Sharma',
        gender: 'Male',
        stateBarAssociation: 'Bar Council of Delhi',
        enrollmentNumber: 'D/1234/2015',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final storage = LocalAuthStorage();
      // Pre-save user session into device storage (simulating previously logged-in user)
      await storage.saveUser(loggedInUser);

      // Backend simulates network delay or offline where currentUser takes time or is null
      final authRepo = FakePersistenceAuthRepo(null);

      // App Launch #1: User opens app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            localAuthStorageProvider.overrideWithValue(storage),
            wallRepositoryProvider
                .overrideWithValue(FakeWallRepoForPersistence()),
            profileRepositoryProvider
                .overrideWithValue(FakeProfileRepoForPersistence()),
          ],
          child: const MaterialApp(
            home: AuthGateScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: User immediately lands on HomeScreen (Community Wall), not PhoneLoginScreen
      expect(find.text('Jai Bhim Advocate Union'), findsOneWidget);
      expect(find.text('Community Wall'), findsOneWidget);
      expect(find.text('Send OTP'), findsNothing);

      // Explicit Sign Out via constant top-right profile avatar menu
      await tester.tap(find.byKey(const Key('top_right_profile_avatar_menu')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // After explicit sign out, user lands on LoginScreen (Google auth only)
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Send OTP'), findsNothing);

      // Verify local storage is cleared
      final savedAfterLogout = await storage.getUser();
      expect(savedAfterLogout, isNull);

      // App Launch #2: App restarts after explicit logout
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            localAuthStorageProvider.overrideWithValue(storage),
            wallRepositoryProvider
                .overrideWithValue(FakeWallRepoForPersistence()),
            profileRepositoryProvider
                .overrideWithValue(FakeProfileRepoForPersistence()),
          ],
          child: const MaterialApp(
            home: AuthGateScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stays on LoginScreen because user explicitly logged out
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Send OTP'), findsNothing);
      expect(find.text('Community Wall'), findsNothing);
    },
  );
}
