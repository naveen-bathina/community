import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class FirebaseNotificationsRepository implements NotificationsRepository {
  final FirebaseFirestore _firestore;

  FirebaseNotificationsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<BroadcastMessage>> getBroadcasts() async {
    final snap = await _firestore
        .collection('broadcasts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      final ts = data['createdAt'];
      return BroadcastMessage.fromMap({
        ...data,
        'createdAt': ts is Timestamp ? ts.toDate() : DateTime.now(),
      }, docId: doc.id);
    }).toList();
  }

  @override
  Future<void> publishBroadcast({
    required String senderId,
    required String senderName,
    required String title,
    required String content,
  }) async {
    await _firestore.collection('broadcasts').add({
      'senderId': senderId,
      'senderName': senderName,
      'title': title.trim(),
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    final items = snap.docs.map((doc) {
      final data = doc.data();
      final ts = data['createdAt'];
      return AppNotification.fromMap({
        ...data,
        'createdAt': ts is Timestamp ? ts.toDate() : DateTime.now(),
      }, docId: doc.id);
    }).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
}

class SupabaseNotificationsRepository implements NotificationsRepository {
  final SupabaseClient _supabase;

  SupabaseNotificationsRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<BroadcastMessage>> getBroadcasts() async {
    final rows = await _supabase
        .from('broadcasts')
        .select('id, sender_id, title, content, created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((r) => BroadcastMessage.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<void> publishBroadcast({
    required String senderId,
    required String senderName,
    required String title,
    required String content,
  }) async {
    await _supabase.from('broadcasts').insert({
      'sender_id': senderId,
      'title': title.trim(),
      'content': content.trim(),
    });
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final rows = await _supabase
        .from('notifications')
        .select('id, user_id, title, body, type, is_read, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => AppNotification.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}

class InMemoryNotificationsRepository implements NotificationsRepository {
  final List<BroadcastMessage> _broadcasts = [];
  final List<AppNotification> _notifications = [];

  @override
  Future<List<BroadcastMessage>> getBroadcasts() async =>
      List.unmodifiable(_broadcasts);

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
        id: 'local-${_broadcasts.length + 1}',
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
      _notifications.where((n) => n.userId == userId).toList();

  @override
  Future<void> markAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    }
  }
}
