import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/admin/presentation/screens/manage_default_admins_screen.dart';
import 'package:legal_unity_network/features/auth/data/datasources/local_auth_storage.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/features/auth/domain/repositories/auth_repository.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/user_settings_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:legal_unity_network/shared/widgets/app_top_bar_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSuperUserAuthRepository implements AuthRepository {
  AuthUser? _currentUser;
  final List<AuthUser> members;
  final _controller = StreamController<AuthUser?>.broadcast();

  FakeSuperUserAuthRepository({
    AuthUser? currentUser,
    List<AuthUser>? memberList,
  })  : _currentUser = currentUser,
        members = memberList ?? [] {
    if (currentUser != null) {
      scheduleMicrotask(() => _controller.add(currentUser));
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  Future<AuthUser?> get currentUser async => _currentUser;

  @override
  Future<List<AuthUser>> getAllMembers() async => List.unmodifiable(members);

  @override
  Future<String?> updateUserRole({
    required String targetUserId,
    required UserRole newRole,
  }) async {
    final idx = members.indexWhere((m) => m.uid == targetUserId);
    if (idx != -1) {
      members[idx] = members[idx].copyWith(role: newRole, status: UserStatus.approved);
    }
    if (_currentUser?.uid == targetUserId) {
      _currentUser = _currentUser!.copyWith(role: newRole, status: UserStatus.approved);
      _controller.add(_currentUser);
    }
    return null;
  }

  @override
  Future<String?> setDefaultAdminByEmail(
    String email, {
    UserRole role = UserRole.foundingAdmin,
  }) async {
    final clean = email.trim().toLowerCase();
    final idx = members.indexWhere((m) => m.email.toLowerCase() == clean);
    if (idx != -1) {
      members[idx] = members[idx].copyWith(role: role, status: UserStatus.approved);
      return null;
    }
    // If not existing, add to roster as approved default admin
    final newAdmin = AuthUser(
      uid: 'user-${members.length + 1}',
      email: clean,
      firstName: 'Counsel',
      lastName: 'Appointed',
      status: UserStatus.approved,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    members.add(newAdmin);
    return null;
  }

  @override
  Future<List<AuthUser>> getPendingJoinRequests() async => const [];

  @override
  Future<String?> reviewJoinRequest({
    required String targetUserId,
    required bool approve,
    String? rejectionReason,
  }) async => null;

  @override
  Future<String?> sendOtp(String phoneNumber) async => null;

  @override
  Future<String?> verifyOtp(String verificationId, String code) async => null;

  @override
  Future<String?> signUpWithGoogle() async => null;

  @override
  Future<String?> submitJoinRequest(JoinRequestInput request) async => null;

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  final superUser = AuthUser(
    uid: 'super-user-1',
    email: 'naveen.bathina9@gmail.com',
    firstName: 'Naveen',
    lastName: 'Bathina',
    status: UserStatus.approved,
    role: UserRole.superAdmin,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final regularMember = AuthUser(
    uid: 'member-101',
    email: 'priya.sharma@bar.org',
    firstName: 'Priya',
    lastName: 'Sharma',
    stateBarAssociation: 'Bar Council of Delhi',
    enrollmentNumber: 'D/9988/2019',
    status: UserStatus.approved,
    role: UserRole.member,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final existingFoundingAdmin = AuthUser(
    uid: 'admin-201',
    email: 'rajesh.kumar@bar.org',
    firstName: 'Rajesh',
    lastName: 'Kumar',
    stateBarAssociation: 'Bar Council of Maharashtra & Goa',
    enrollmentNumber: 'MAH/1122/2014',
    status: UserStatus.approved,
    role: UserRole.foundingAdmin,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('Super User Authorization & Entities', () {
    test('AppConfig identifies naveen.bathina9@gmail.com as superAdminEmail', () {
      expect(AppConfig.superAdminEmail, 'naveen.bathina9@gmail.com');
      expect(AppConfig.isSuperAdminEmail('naveen.bathina9@gmail.com'), isTrue);
      expect(AppConfig.isSuperAdminEmail('NAVEEN.BATHINA9@GMAIL.COM'), isTrue);
      expect(AppConfig.isSuperAdminEmail('other@example.com'), isFalse);
    });

    test('AuthUser auto-detects super user privileges and admin permissions', () {
      final user = AuthUser(
        uid: 'u-super',
        email: 'naveen.bathina9@gmail.com',
        status: UserStatus.pending, // Even if marked pending in DB
        role: UserRole.member,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.isSuperAdmin, isTrue);
      expect(user.isAdmin, isTrue);
      expect(user.isApproved, isTrue);
      expect(user.hasSubmittedJoinRequest, isTrue);
    });

    test('UserModel auto-detects super user privileges', () {
      final model = UserModel(
        userId: 'u-super',
        email: 'naveen.bathina9@gmail.com',
        name: 'Naveen Bathina',
        status: UserStatus.pending,
        role: UserRole.member,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(model.isSuperAdmin, isTrue);
      expect(model.isAdmin, isTrue);
      expect(model.isApproved, isTrue);
    });
  });

  group('ManageDefaultAdminsScreen Widget Tests', () {
    testWidgets('Renders Super User Governance banner and active councils',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeSuperUserAuthRepository(
        currentUser: superUser,
        memberList: [superUser, existingFoundingAdmin, regularMember],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            localAuthStorageProvider.overrideWithValue(LocalAuthStorage(mockPrefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ManageDefaultAdminsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set Default Admins'), findsOneWidget);
      expect(find.text('Super User Governance Control'), findsOneWidget);
      expect(find.text(AppConfig.superAdminEmail), findsWidgets);
      expect(find.text('Appoint Default Admin by Email'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.text('Founding Admin'), findsWidgets);
      expect(find.text('Priya Sharma'), findsOneWidget);
    });

    testWidgets('Super User can appoint a default founding admin by email',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeSuperUserAuthRepository(
        currentUser: superUser,
        memberList: [superUser, regularMember],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            localAuthStorageProvider.overrideWithValue(LocalAuthStorage(mockPrefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ManageDefaultAdminsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter advocate email to appoint
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Advocate Email Address'),
        'newcounsel@bar.org',
      );
      await tester.tap(find.text('Appoint as Default Admin'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Successfully appointed newcounsel@bar.org'), findsOneWidget);
    });

    testWidgets('Super User can promote a member to Founding Admin from roster',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeSuperUserAuthRepository(
        currentUser: superUser,
        memberList: [superUser, regularMember],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            localAuthStorageProvider.overrideWithValue(LocalAuthStorage(mockPrefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ManageDefaultAdminsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Make Founding Admin'), findsOneWidget);
      await tester.tap(find.text('Make Founding Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Updated Priya Sharma to Founding Admin'), findsOneWidget);
    });
  });

  group('Navigation & Menu Integration for Super User', () {
    testWidgets('AppTopBarActions displays "Super User: Set Default Admins" for naveen.bathina9@gmail.com',
        (WidgetTester tester) async {
      await LocalAuthStorage(mockPrefs).saveUser(superUser);

      final repo = FakeSuperUserAuthRepository(
        currentUser: superUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            localAuthStorageProvider.overrideWithValue(LocalAuthStorage(mockPrefs)),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  AppTopBarActions(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open profile popup menu
      await tester.tap(find.byKey(const Key('top_right_profile_avatar_menu')));
      await tester.pumpAndSettle();

      expect(find.text('Super User: Set Default Admins'), findsOneWidget);
    });

    testWidgets('UserSettingsScreen displays Super User Governance card for naveen.bathina9@gmail.com',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await LocalAuthStorage(mockPrefs).saveUser(superUser);

      final repo = FakeSuperUserAuthRepository(
        currentUser: superUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            localAuthStorageProvider.overrideWithValue(LocalAuthStorage(mockPrefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: UserSettingsScreen(currentUser: superUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Super User Governance'), findsOneWidget);
      expect(find.text('Set default and founding administrators'), findsOneWidget);

      await tester.tap(find.text('Super User Governance'));
      await tester.pumpAndSettle();

      expect(find.text('Super User Governance Control'), findsOneWidget);
    });
  });
}
