import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/features/auth/domain/repositories/auth_repository.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/profile/domain/repositories/profile_repository.dart';
import 'package:legal_unity_network/features/profile/presentation/providers/profile_provider.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepoForProfileTest implements AuthRepository {
  final AuthUser? _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  FakeAuthRepoForProfileTest(this._user);

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  Future<AuthUser?> get currentUser async => _user;

  @override
  Future<void> signOut() async {}

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
  }) async => null;

  @override
  Future<List<AuthUser>> getAllMembers() async =>
      _user != null ? [_user] : [];

  @override
  Future<String?> updateUserRole({
    required String targetUserId,
    required UserRole newRole,
  }) async => null;

  @override
  Future<String?> setDefaultAdminByEmail(
    String email, {
    UserRole role = UserRole.foundingAdmin,
  }) async => null;
}

class FakeMyProfileRepository implements ProfileRepository {
  UserModel _profile = UserModel(
    userId: 'u-1',
    email: 'meera@legalunity.org',
    phone: '+919876543210',
    name: 'Meera Nair',
    status: UserStatus.approved,
    role: UserRole.member,
    barAdmissions: const [
      BarAdmission(
        jurisdiction: 'Bar Council of Karnataka',
        barNumber: 'KAR/2018/4451',
        yearAdmitted: 2018,
      ),
    ],
    lawSchool: 'National Law School of India University (NLSIU)',
    practiceAreas: const ['Corporate Law', 'Arbitration'],
    firmOrganization: 'Nair & Partners',
    yearsOfExperience: 8,
    city: 'Bengaluru',
    state: 'Karnataka',
    bio: 'Corporate & M&A counsel representing technology enterprises.',
    availabilityStatus: AvailabilityStatus.acceptingReferrals,
    achievements: 'Best Young Corporate Counsel 2024',
    cles: 'Advanced International Arbitration CLE (24 Credits)',
    publications: 'Cross-Border M&A in India ( Bar Journal, 2025 )',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  UserModel get currentSavedProfile => _profile;

  @override
  Future<List<UserModel>> getApprovedMembers({
    String? searchQuery,
    String? practiceArea,
    AvailabilityStatus? availability,
  }) async {
    return [_profile];
  }

  @override
  Future<UserModel?> getProfile(String userId) async {
    return _profile;
  }

  @override
  Future<String?> updateProfile(UserModel updatedProfile) async {
    _profile = updatedProfile;
    return null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'MyProfileScreen displays logged-in user details, credentials, and allows full profile editing & bar admission management',
    (WidgetTester tester) async {
      final fakeRepo = FakeMyProfileRepository();
      final currentUser = AuthUser(
        uid: 'u-1',
        email: 'meera@legalunity.org',
        phoneNumber: '+919876543210',
        firstName: 'Meera',
        lastName: 'Nair',
        gender: 'Female',
        stateBarAssociation: 'Bar Council of Karnataka',
        enrollmentNumber: 'KAR/2018/4451',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: MyProfileScreen(currentUser: currentUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify profile overview details are displayed
      expect(find.text('Meera Nair'), findsOneWidget);
      expect(find.text('Nair & Partners'), findsOneWidget);
      expect(find.text('8 Years Experience'), findsOneWidget);
      expect(find.text('Accepting Referrals'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('KAR/2018/4451 (2018 - Present)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('National Law School of India University (NLSIU)'),
        findsOneWidget,
      );
      expect(find.text('Bar Council of Karnataka'), findsWidgets);
      expect(find.text('KAR/2018/4451 (2018 - Present)'), findsOneWidget);

      // Verify edit professional profile button is removed from body (now only in action bar)
      expect(find.byKey(const Key('manage_edit_profile_btn')), findsNothing);

      // Tap Edit Profile icon in the AppBar action bar to open EditProfileScreen
      await tester.tap(find.byKey(const Key('appbar_edit_profile_btn')));
      await tester.pumpAndSettle();

      // Update Law School, Years of Experience, Achievements, and Firm
      await tester.enterText(
        find.byKey(const Key('edit_firm_input')),
        'Nair Supreme Chambers LLP',
      );
      await tester.enterText(
        find.byKey(const Key('edit_law_school_input')),
        'NLSIU Bengaluru (LL.M.)',
      );
      await tester.enterText(
        find.byKey(const Key('edit_experience_input')),
        '10',
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('save_profile_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      // Verify MyProfileScreen reflects the updated fields
      await tester.scrollUntilVisible(
        find.text('Nair Supreme Chambers LLP'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Nair Supreme Chambers LLP'), findsOneWidget);
      expect(find.text('10 Years Experience'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('NLSIU Bengaluru (LL.M.)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('NLSIU Bengaluru (LL.M.)'), findsOneWidget);
    },
  );

  testWidgets(
    'EditProfileScreen allows adding Bar Admission with State Bar Council dropdown, Enrollment Number, Start Year, and End Year / Practicing Current',
    (WidgetTester tester) async {
      final fakeRepo = FakeMyProfileRepository();
      final currentUser = AuthUser(
        uid: 'u-1',
        email: 'meera@legalunity.org',
        firstName: 'Meera',
        lastName: 'Nair',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: EditProfileScreen(currentUser: currentUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Bar Admissions section and tap Add Admission
      await tester.scrollUntilVisible(
        find.byKey(const Key('add_bar_admission_btn')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('add_bar_admission_btn')));
      await tester.pumpAndSettle();

      // Verify the dialog contains State Bar Council dropdown, Enrollment Number, Start Year, and Practicing Current switch
      expect(find.text('Add Bar Admission'), findsOneWidget);
      expect(find.byKey(const Key('bar_council_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('bar_number_input')), findsOneWidget);
      expect(find.byKey(const Key('bar_start_year_input')), findsOneWidget);
      expect(
        find.byKey(const Key('bar_practicing_current_switch')),
        findsOneWidget,
      );

      // Select State Bar Council from dropdown
      await tester.tap(find.byKey(const Key('bar_council_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bar Council of Delhi').last);
      await tester.pumpAndSettle();

      // Enter Enrollment Number and Start Year
      await tester.enterText(
        find.byKey(const Key('bar_number_input')),
        'D/5678/2019',
      );
      await tester.enterText(
        find.byKey(const Key('bar_start_year_input')),
        '2019',
      );

      // Toggle Practicing Current to false, which reveals End Year field
      await tester.tap(find.byKey(const Key('bar_practicing_current_switch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bar_end_year_input')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('bar_end_year_input')),
        '2023',
      );

      // Confirm adding bar admission
      await tester.tap(find.byKey(const Key('confirm_add_bar_button')));
      await tester.pumpAndSettle();

      // Verify the new admission is listed with State Bar Council, Enrollment Number, and (Start Year - End Year)
      expect(find.text('Bar Council of Delhi'), findsOneWidget);
      expect(find.text('D/5678/2019 (2019 - 2023)'), findsOneWidget);

      // Now add a second admission with Practicing Current = true
      await tester.tap(find.byKey(const Key('add_bar_admission_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bar_council_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bar Council of Gujarat').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('bar_number_input')),
        'GUJ/9988/2023',
      );
      await tester.enterText(
        find.byKey(const Key('bar_start_year_input')),
        '2023',
      );
      // Practicing Current is true by default
      await tester.tap(find.byKey(const Key('confirm_add_bar_button')));
      await tester.pumpAndSettle();

      // Verify second admission is listed with (Start Year - Present)
      expect(find.text('Bar Council of Gujarat'), findsOneWidget);
      expect(find.text('GUJ/9988/2023 (2023 - Present)'), findsOneWidget);

      // Save profile
      await tester.scrollUntilVisible(
        find.byKey(const Key('save_profile_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      // Verify in saved repository profile
      final savedAdmissions = fakeRepo.currentSavedProfile.barAdmissions ?? [];
      expect(
        savedAdmissions.any(
          (b) =>
              b.jurisdiction == 'Bar Council of Delhi' &&
              b.barNumber == 'D/5678/2019' &&
              b.startYear == 2019 &&
              b.endYear == 2023 &&
              !b.isCurrentlyPracticing,
        ),
        isTrue,
      );
      expect(
        savedAdmissions.any(
          (b) =>
              b.jurisdiction == 'Bar Council of Gujarat' &&
              b.barNumber == 'GUJ/9988/2023' &&
              b.startYear == 2023 &&
              b.isCurrentlyPracticing,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'Top right avatar menu excludes Edit Profile item, and shows Verify Join Requests only for admins',
    (WidgetTester tester) async {
      final fakeRepo = FakeMyProfileRepository();
      final memberUser = AuthUser(
        uid: 'm-1',
        email: 'member@legalunity.org',
        firstName: 'Meera',
        lastName: 'Nair',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final adminUser = AuthUser(
        uid: 'a-1',
        email: 'admin@legalunity.org',
        firstName: 'Arun',
        lastName: 'Jaitley',
        role: UserRole.admin,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // 1. Member view
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider
                .overrideWithValue(FakeAuthRepoForProfileTest(memberUser)),
          ],
          child: MaterialApp(
            home: MyProfileScreen(currentUser: memberUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('top_right_profile_avatar_menu')));
      await tester.pumpAndSettle();

      expect(find.text('Manage Profile'), findsOneWidget);
      expect(find.text('User Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      // Removed edit profile and non-admin cannot see verify join requests
      expect(find.text('Edit Professional Profile'), findsNothing);
      expect(find.text('Admin: Verify Join Requests'), findsNothing);

      // Dismiss menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      SharedPreferences.setMockInitialValues({});

      // 2. Admin view
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider
                .overrideWithValue(FakeAuthRepoForProfileTest(adminUser)),
          ],
          child: MaterialApp(
            home: MyProfileScreen(currentUser: adminUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('top_right_profile_avatar_menu')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Professional Profile'), findsNothing);
      expect(find.text('Admin: Verify Join Requests'), findsOneWidget);
    },
  );
}
