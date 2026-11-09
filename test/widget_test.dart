import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/router/protected_route.dart';
import 'package:legal_unity_network/features/admin/presentation/screens/admin_join_requests_screen.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/features/auth/domain/repositories/auth_repository.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/main.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository implements AuthRepository {
  AuthUser? _user;
  final List<AuthUser> pendingRequests;
  final _controller = StreamController<AuthUser?>.broadcast();

  FakeAuthRepository([this._user, List<AuthUser>? pending])
      : pendingRequests = pending ?? [];

  void emitUser(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  Future<AuthUser?> get currentUser async => _user;

  @override
  Future<String?> sendOtp(String phoneNumber) async => null;

  @override
  Future<String?> verifyOtp(String verificationId, String code) async => null;

  @override
  Future<String?> signUpWithGoogle() async => null;

  @override
  Future<String?> submitJoinRequest(JoinRequestInput request) async {
    if (_user != null) {
      _user = _user!.copyWith(
        firstName: request.firstName,
        lastName: request.lastName,
        dateOfBirth: request.dateOfBirth,
        gender: request.gender,
        phoneNumber: request.mobileNumber,
        stateBarAssociation: request.stateBarAssociation,
        enrollmentNumber: request.enrollmentNumber,
        photoUrl: request.existingPhotoUrl ?? 'data:image/jpeg;base64,/9j/4AAQ',
        status: UserStatus.pending,
      );
      _controller.add(_user);
    }
    return null;
  }

  @override
  Future<List<AuthUser>> getPendingJoinRequests() async =>
      List.unmodifiable(pendingRequests);

  @override
  Future<String?> reviewJoinRequest({
    required String targetUserId,
    required bool approve,
    String? rejectionReason,
  }) async {
    pendingRequests.removeWhere((u) => u.uid == targetUserId);
    if (_user?.uid == targetUserId) {
      _user = _user!.copyWith(
        status: approve ? UserStatus.approved : UserStatus.rejected,
        rejectionReason: rejectionReason,
      );
      _controller.add(_user);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    emitUser(null);
  }
}

AuthUser _makeUser({
  String uid = 'user-123',
  UserStatus status = UserStatus.approved,
  UserRole role = UserRole.member,
  bool withJoinRequest = true,
}) {
  return AuthUser(
    uid: uid,
    email: 'counsel@example.com',
    phoneNumber: '+919999999999',
    firstName: withJoinRequest ? 'Aarav' : null,
    lastName: withJoinRequest ? 'Sharma' : null,
    dateOfBirth: withJoinRequest ? DateTime(1990, 5, 15) : null,
    gender: withJoinRequest ? 'Male' : null,
    stateBarAssociation:
        withJoinRequest ? 'Bar Council of Karnataka' : null,
    enrollmentNumber: withJoinRequest ? 'KAR/1234/2018' : null,
    photoUrl: withJoinRequest
        ? 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
        : null,
    status: status,
    role: role,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Unauthenticated user is routed to LoginScreen with only Google authentication',
      (WidgetTester tester) async {
    final repo = FakeAuthRepository(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Jai Bhim Advocate Union'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byKey(const Key('google_sign_in_btn')), findsOneWidget);
    expect(find.text('Send OTP'), findsNothing);
    expect(find.text('Phone Number'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets(
      'Newly signed-up user without join request is routed to JoinRequestScreen',
      (WidgetTester tester) async {
    final repo = FakeAuthRepository(
      _makeUser(status: UserStatus.pending, withJoinRequest: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Complete Your Advocate Verification'),
      findsOneWidget,
    );
    expect(find.text('First Name *'), findsOneWidget);
    expect(find.text('Last Name *'), findsOneWidget);
    expect(find.text('Date Of Birth *'), findsOneWidget);
    expect(find.text('Gender *'), findsOneWidget);
    expect(find.text('Mobile Number *'), findsOneWidget);
    expect(find.text('State Bar Association *'), findsOneWidget);
    expect(find.text('Enrollment Number *'), findsOneWidget);
    expect(find.text('Submit Join Request'), findsOneWidget);
  });

  testWidgets(
      'Pending applicant who submitted join request is routed to PendingApprovalScreen',
      (WidgetTester tester) async {
    final repo = FakeAuthRepository(
      _makeUser(status: UserStatus.pending, withJoinRequest: true),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending Admin Approval'), findsOneWidget);
    expect(find.text('Aarav Sharma'), findsOneWidget);
    expect(find.text('KAR/1234/2018'), findsOneWidget);
    expect(find.text('Check Approval Status'), findsOneWidget);
  });

  testWidgets('Banned user is routed to AccessRestrictedScreen',
      (WidgetTester tester) async {
    final repo = FakeAuthRepository(
      _makeUser(status: UserStatus.banned),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Account Has Been Suspended'), findsOneWidget);
  });

  testWidgets('Approved member is routed to HomeScreen and can sign out',
      (WidgetTester tester) async {
    final repo = FakeAuthRepository(
      _makeUser(status: UserStatus.approved, role: UserRole.member),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Community Wall'), findsOneWidget);

    await tester.tap(find.byKey(const Key('top_right_profile_avatar_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Send OTP'), findsNothing);
  });

  testWidgets('AdminJoinRequestsScreen displays applicant details and approves',
      (WidgetTester tester) async {
    final applicant = _makeUser(
      uid: 'applicant-1',
      status: UserStatus.pending,
      withJoinRequest: true,
    );
    final repo = FakeAuthRepository(
      _makeUser(status: UserStatus.approved, role: UserRole.admin),
      [applicant],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: AdminJoinRequestsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aarav Sharma'), findsOneWidget);
    expect(find.text('KAR/1234/2018'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(find.text('No pending join requests to review.'), findsOneWidget);
  });

  testWidgets('ProtectedRoute with requireAdmin blocks regular members',
      (WidgetTester tester) async {
    final repo = FakeAuthRepository(
      _makeUser(status: UserStatus.approved, role: UserRole.member),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: ProtectedRoute(
            requireAdmin: true,
            child: Scaffold(body: Text('Admin Dashboard')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Access Denied'), findsOneWidget);
    expect(find.text('Admin Dashboard'), findsNothing);
  });

  testWidgets(
      'Once admin approves join request, user automatically lands on HomeScreen',
      (WidgetTester tester) async {
    final pendingUser = _makeUser(
      uid: 'user-123',
      status: UserStatus.pending,
      withJoinRequest: true,
    );
    final repo = FakeAuthRepository(pendingUser, [pendingUser]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Initially on PendingApprovalScreen
    expect(find.text('Pending Admin Approval'), findsOneWidget);

    // Open Admin Verification Queue and tap Approve
    await tester.tap(find.byTooltip('Admin Verification Queue'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Join Requests'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    // User automatically lands on HomeScreen showing Community Wall
    expect(find.text('Community Wall'), findsOneWidget);
  });

  test('AppConfig app title defaults to Jai Bhim Advocate Union and is configurable', () {
    expect(AppConfig.appName, 'Jai Bhim Advocate Union');
    expect(AppConfig.welcomeTitle, 'Welcome to Jai Bhim Advocate Union');

    // Dynamically reconfigure app title
    AppConfig.setAppName('National Advocate League');
    expect(AppConfig.appName, 'National Advocate League');
    expect(AppConfig.welcomeTitle, 'Welcome to National Advocate League');

    // Reset to default
    AppConfig.reset();
    expect(AppConfig.appName, 'Jai Bhim Advocate Union');
  });
}
