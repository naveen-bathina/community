import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/notifications_datasource.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    try {
      return SupabaseNotificationsRepository();
    } catch (_) {}
  }
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseNotificationsRepository();
    }
  } catch (_) {}
  return InMemoryNotificationsRepository();
});

/// True when an election notification or broadcast has been released.
final electionNotificationReleasedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, userId) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final broadcasts = await repo.getBroadcasts();
  final notifications = await repo.getNotifications(userId);

  final hasElectionBroadcast = broadcasts.any(
    (b) =>
        b.title.toLowerCase().contains('election') ||
        b.content.toLowerCase().contains('election'),
  );
  final hasElectionNotification = notifications.any(
    (n) =>
        n.type.toLowerCase().contains('election') ||
        n.title.toLowerCase().contains('election') ||
        n.body.toLowerCase().contains('election'),
  );
  return hasElectionBroadcast || hasElectionNotification;
});
