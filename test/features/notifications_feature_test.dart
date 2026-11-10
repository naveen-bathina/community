import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/notifications/domain/entities/app_notification.dart';
import 'package:legal_unity_network/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:legal_unity_network/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:legal_unity_network/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  final List<BroadcastMessage> _broadcasts = [
    BroadcastMessage(
      id: 'b-1',
      senderId: 'admin-1',
      senderName: 'Bar Council Admin',
      title: 'Annual General Meeting 2026',
      content: 'All members are invited to the AGM on December 15th.',
      createdAt: DateTime(2026, 11, 9, 9, 0),
    ),
  ];

  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'n-1',
      userId: 'admin-1',
      title: 'Membership Approved',
      body: 'Welcome to the Legal Unity Network!',
      type: 'approval',
      isRead: false,
      createdAt: DateTime(2026, 11, 9, 8, 30),
    ),
  ];

  @override
  Future<List<BroadcastMessage>> getBroadcasts() async {
    return List.unmodifiable(_broadcasts);
  }

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
        id: 'b-${_broadcasts.length + 1}',
        senderId: senderId,
        senderName: senderName,
        title: title,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    return _notifications.where((n) => n.userId == userId).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    }
  }
}

void main() {
  testWidgets(
    'NotificationsScreen displays broadcasts, allows admin to publish broadcast, and marks alerts as read',
    (WidgetTester tester) async {
      final fakeRepo = FakeNotificationsRepository();
      final adminUser = AuthUser(
        uid: 'admin-1',
        email: 'vikram@legalunity.org',
        firstName: 'Vikram',
        lastName: 'Rao',
        role: UserRole.admin,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: NotificationsScreen(currentUser: adminUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify existing broadcast is visible
      expect(find.text('Annual General Meeting 2026'), findsOneWidget);
      expect(
        find.text('All members are invited to the AGM on December 15th.'),
        findsOneWidget,
      );

      // Admin publishes a new broadcast
      await tester.tap(find.byKey(const Key('new_broadcast_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('broadcast_title_input')),
        'Supreme Court E-Filing Update',
      );
      await tester.enterText(
        find.byKey(const Key('broadcast_content_input')),
        'New e-filing portal guidelines take effect next Monday.',
      );
      await tester.tap(find.byKey(const Key('publish_broadcast_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Supreme Court E-Filing Update'), findsOneWidget);

      // Switch to Personal Alerts tab and mark notification as read
      await tester.tap(find.text('Alerts (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Membership Approved'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mark_read_n-1')));
      await tester.pumpAndSettle();

      expect(find.text('Alerts (0)'), findsOneWidget);
    },
  );

  test(
    'BroadcastMessage.fromMap correctly parses Supabase maps with author_id and author_name',
    () {
      final message = BroadcastMessage.fromMap({
        'id': 'b-supabase-1',
        'author_id': 'uid-12345',
        'author_name': 'Chief Admin',
        'title': 'Emergency Notice',
        'content': 'Courts closed tomorrow due to gazetted holiday.',
        'created_at': '2026-11-09T10:00:00.000Z',
      });

      expect(message.id, 'b-supabase-1');
      expect(message.senderId, 'uid-12345');
      expect(message.senderName, 'Chief Admin');
      expect(message.title, 'Emergency Notice');
      expect(message.content, 'Courts closed tomorrow due to gazetted holiday.');
    },
  );

  testWidgets(
    'NotificationsScreen displays error SnackBar when publishBroadcast fails without throwing uncaught',
    (WidgetTester tester) async {
      final errorRepo = ErrorThrowingNotificationsRepository();
      final adminUser = AuthUser(
        uid: 'admin-1',
        email: 'vikram@legalunity.org',
        firstName: 'Vikram',
        lastName: 'Rao',
        role: UserRole.admin,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(errorRepo),
          ],
          child: MaterialApp(
            home: NotificationsScreen(currentUser: adminUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('new_broadcast_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('broadcast_title_input')),
        'Test Broadcast',
      );
      await tester.enterText(
        find.byKey(const Key('broadcast_content_input')),
        'Test Content',
      );
      await tester.tap(find.byKey(const Key('publish_broadcast_submit')));
      await tester.pumpAndSettle();

      // Verify that error snackbar appears instead of throwing an unhandled exception
      expect(find.textContaining('Could not publish broadcast'), findsOneWidget);
    },
  );
}

class ErrorThrowingNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<BroadcastMessage>> getBroadcasts() async => [];

  @override
  Future<List<AppNotification>> getNotifications(String userId) async => [];

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> publishBroadcast({
    required String senderId,
    required String senderName,
    required String title,
    required String content,
  }) async {
    throw Exception('Simulated permission-denied error');
  }
}
