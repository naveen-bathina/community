class BroadcastMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String title;
  final String content;
  final DateTime createdAt;

  const BroadcastMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory BroadcastMessage.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawCreatedAt = map['createdAt'] ?? map['created_at'];
    DateTime parsedTime = DateTime.now();
    if (rawCreatedAt is DateTime) {
      parsedTime = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedTime = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    return BroadcastMessage(
      id: (docId ?? map['id'] ?? '').toString(),
      senderId: (map['senderId'] ?? map['sender_id'] ?? '').toString(),
      senderName: (map['senderName'] ?? map['sender_name'] ?? 'Admin').toString(),
      title: (map['title'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      createdAt: parsedTime,
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'system',
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawCreatedAt = map['createdAt'] ?? map['created_at'];
    DateTime parsedTime = DateTime.now();
    if (rawCreatedAt is DateTime) {
      parsedTime = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedTime = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    return AppNotification(
      id: (docId ?? map['id'] ?? '').toString(),
      userId: (map['userId'] ?? map['user_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      type: (map['type'] ?? 'system').toString(),
      isRead: (map['isRead'] ?? map['is_read'] ?? false) == true,
      createdAt: parsedTime,
    );
  }
}
