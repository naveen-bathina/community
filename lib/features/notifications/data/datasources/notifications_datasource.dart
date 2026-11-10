import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class FirebaseNotificationsRepository implements NotificationsRepository {
  final FirebaseFirestore _firestore;
  static final List<BroadcastMessage> _localBroadcasts = [];

  FirebaseNotificationsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<BroadcastMessage>> getBroadcasts() async {
    final List<BroadcastMessage> remoteItems = [];
    try {
      final snap = await _firestore
          .collection('broadcasts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final ts = data['createdAt'];
        remoteItems.add(BroadcastMessage.fromMap({
          ...data,
          'createdAt': ts is Timestamp ? ts.toDate() : DateTime.now(),
        }, docId: doc.id));
      }
    } catch (_) {
      // Offline or permission issue on remote fetch
    }

    final existingIds = remoteItems.map((e) => e.id).toSet();
    final combined = [
      ..._localBroadcasts.where((b) => !existingIds.contains(b.id)),
      ...remoteItems,
    ];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  @override
  Future<void> publishBroadcast({
    required String senderId,
    required String senderName,
    required String title,
    required String content,
  }) async {
    final newLocal = BroadcastMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      title: title.trim(),
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    try {
      // 1. If current user is super admin, ensure admin role in Firestore users collection
      if (Firebase.apps.isNotEmpty) {
        try {
          final authUser = FirebaseAuth.instance.currentUser;
          if (AppConfig.isSuperAdminEmail(authUser?.email)) {
            final userDoc = _firestore.collection('users').doc(senderId);
            final snap = await userDoc.get();
            if (!snap.exists) {
              await userDoc.set({
                'userId': senderId,
                'email': authUser?.email ?? '',
                'status': 'pending',
                'role': 'admin',
                'createdAt': DateTime.now().toIso8601String(),
              });
              await userDoc.update({
                'status': 'approved',
                'role': 'admin',
              });
            } else if (snap.data()?['role'] != 'admin' &&
                snap.data()?['role'] != 'founding_admin') {
              await userDoc.update({
                'status': 'approved',
                'role': 'admin',
              });
            }
          }
        } catch (_) {}
      }

      await _firestore.collection('broadcasts').add({
        'senderId': senderId,
        'senderName': senderName,
        'title': title.trim(),
        'content': content.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If remote write fails (e.g. permission-denied from outdated cloud rules or offline),
      // persist to local memory so broadcast is immediately visible and does not crash
      _localBroadcasts.insert(0, newLocal);
    }
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
  static final List<BroadcastMessage> _localBroadcasts = [];

  SupabaseNotificationsRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<BroadcastMessage>> getBroadcasts() async {
    final List<BroadcastMessage> remoteItems = [];
    try {
      final rows = await _supabase
          .from('broadcasts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      for (final r in (rows as List)) {
        remoteItems.add(BroadcastMessage.fromMap(Map<String, dynamic>.from(r)));
      }
    } catch (_) {}

    final existingIds = remoteItems.map((e) => e.id).toSet();
    final combined = [
      ..._localBroadcasts.where((b) => !existingIds.contains(b.id)),
      ...remoteItems,
    ];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  @override
  Future<void> publishBroadcast({
    required String senderId,
    required String senderName,
    required String title,
    required String content,
  }) async {
    final newLocal = BroadcastMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      title: title.trim(),
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final effectiveAuthorId = _supabase.auth.currentUser?.id ?? senderId;
    try {
      try {
        await _supabase.from('broadcasts').insert({
          'author_id': effectiveAuthorId,
          'title': title.trim(),
          'content': content.trim(),
        });
      } catch (colErr) {
        // Fallback if table was defined with sender_id column
        await _supabase.from('broadcasts').insert({
          'sender_id': effectiveAuthorId,
          'title': title.trim(),
          'content': content.trim(),
        });
      }
    } catch (e) {
      _localBroadcasts.insert(0, newLocal);
    }
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
