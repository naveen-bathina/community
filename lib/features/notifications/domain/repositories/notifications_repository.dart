import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<List<BroadcastMessage>> getBroadcasts();

  Future<void> publishBroadcast({
    required String senderId,
    required String senderName,
    required String title,
    required String content,
  });

  Future<List<AppNotification>> getNotifications(String userId);

  Future<void> markAsRead(String notificationId);
}
