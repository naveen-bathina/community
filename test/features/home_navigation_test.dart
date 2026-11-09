import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/home_screen.dart';
import 'package:legal_unity_network/features/notifications/domain/entities/app_notification.dart';
import 'package:legal_unity_network/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:legal_unity_network/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:legal_unity_network/features/profile/domain/repositories/profile_repository.dart';
import 'package:legal_unity_network/features/profile/presentation/providers/profile_provider.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNavNotificationsRepository implements NotificationsRepository {
  final List<BroadcastMessage> _broadcasts;
  final List<AppNotification> _notifications;

  FakeNavNotificationsRepository({
    List<BroadcastMessage>? broadcasts,
    List<AppNotification>? notifications,
  })  : _broadcasts = broadcasts ?? [],
        _notifications = notifications ?? [];

  @override
  Future<List<BroadcastMessage>> getBroadcasts() async => _broadcasts;

  @override
  Future<void> publishBroadcast({
    required String senderId,
    required String senderName,
    required String title,
    required String content,
  }) async {
    _broadcasts.insert(
      0,
      BroadcastMessage(
        id: 'b-new',
        senderId: senderId,
        senderName: senderName,
        title: title,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async =>
      _notifications;

  @override
  Future<void> markAsRead(String notificationId) async {}
}

class FakeProfileEditRepository implements ProfileRepository {
  UserModel _profile = UserModel(
    userId: 'u-1',
    email: 'meera@legalunity.org',
    name: 'Meera Nair',
    status: UserStatus.approved,
    role: UserRole.member,
    practiceAreas: const ['Corporate Law'],
    firmOrganization: 'Nair & Partners',
    city: 'Bengaluru',
    state: 'Karnataka',
    bio: 'Corporate & M&A counsel.',
    availabilityStatus: AvailabilityStatus.acceptingReferrals,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  UserModel get savedProfile => _profile;

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
    'EditProfileScreen loads member profile and saves updated firm, bio, and practice areas',
    (WidgetTester tester) async {
      final fakeProfileRepo = FakeProfileEditRepository();
      final user = AuthUser(
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
            profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
          ],
          child: MaterialApp(
            home: EditProfileScreen(currentUser: user),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial values loaded
      expect(find.text('Nair & Partners'), findsOneWidget);

      // Update firm and bio
      await tester.enterText(
        find.byKey(const Key('edit_firm_input')),
        'Nair Legal Chambers LLP',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('edit_bio_input')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Corporate & M&A counsel.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('edit_bio_input')),
        'Senior Corporate & Arbitration Counsel.',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('save_profile_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      expect(
        fakeProfileRepo.savedProfile.firmOrganization,
        'Nair Legal Chambers LLP',
      );
      expect(
        fakeProfileRepo.savedProfile.bio,
        'Senior Corporate & Arbitration Counsel.',
      );
    },
  );

  testWidgets(
    'HomeScreen has constant top-right profile menu & bell icon, FAB for new post, and shows Elections only when election notification is released',
    (WidgetTester tester) async {
      final fakeProfileRepo = FakeProfileEditRepository();
      final noElectionNotifRepo = FakeNavNotificationsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
            notificationsRepositoryProvider.overrideWithValue(
              noElectionNotifRepo,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Home tab shows Community Wall posts and a FloatingActionButton for new post
      expect(find.text('Community Wall'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byKey(const Key('create_wall_post_button')), findsOneWidget);

      // Action bar has notification (bell) icon and profile avatar menu
      expect(
        find.byKey(const Key('top_right_notifications_bell')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('top_right_profile_avatar_menu')),
        findsOneWidget,
      );

      // Elections tab is hidden when no election notification is released
      expect(find.text('Elections'), findsNothing);

      // Tap Bell icon to open NotificationsScreen (which also has constant profile avatar menu)
      await tester.tap(find.byKey(const Key('top_right_notifications_bell')));
      await tester.pumpAndSettle();
      expect(find.text('Broadcasts & Alerts'), findsOneWidget);
      expect(
        find.byKey(const Key('top_right_profile_avatar_menu')),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Open top-right profile avatar menu and check items
      await tester.tap(find.byKey(const Key('top_right_profile_avatar_menu')));
      await tester.pumpAndSettle();

      expect(find.text('Manage Profile'), findsOneWidget);
      expect(find.text('User Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Tap User Settings from the menu; verify constant profile avatar menu is present there too
      await tester.tap(find.text('User Settings'));
      await tester.pumpAndSettle();
      expect(find.text('User Settings'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(
        find.byKey(const Key('top_right_profile_avatar_menu')),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Switch to Directory tab; constant profile avatar & bell icon remain in AppBar
      await tester.tap(find.text('Directory'));
      await tester.pumpAndSettle();
      expect(find.text('Meera Nair'), findsOneWidget);
      expect(
        find.byKey(const Key('top_right_profile_avatar_menu')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'HomeScreen shows Elections tab once an election notification/broadcast is released',
    (WidgetTester tester) async {
      final fakeProfileRepo = FakeProfileEditRepository();
      final electionNotifRepo = FakeNavNotificationsRepository(
        broadcasts: [
          BroadcastMessage(
            id: 'b-elec',
            senderId: 'admin-1',
            senderName: 'Admin',
            title: 'Bar Council Election 2026 Nominations Open',
            content: 'Official election notification released.',
            createdAt: DateTime(2026, 11, 9),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
            notificationsRepositoryProvider.overrideWithValue(
              electionNotifRepo,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Elections tab is now visible because election notification was released
      expect(find.text('Elections'), findsOneWidget);
      await tester.tap(find.text('Elections'));
      await tester.pumpAndSettle();
      expect(find.text('Governance & Elections'), findsOneWidget);
    },
  );
}
