/// Firebase collection and field name constants
class FirebaseConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';
  static const String groupChatCollection = 'groupChat';
  static const String broadcastsCollection = 'broadcasts';
  static const String electionsCollection = 'elections';
  static const String nominationsCollection = 'nominations';
  static const String votesCollection = 'votes';
  static const String adminActionsCollection = 'adminActions';
  static const String notificationsCollection = 'notifications';

  // Storage paths
  static const String profilePhotosPath = 'profile_photos';
  static const String chatAttachmentsPath = 'chat_attachments';

  // User fields
  static const String userIdField = 'userId';
  static const String emailField = 'email';
  static const String phoneField = 'phone';
  static const String nameField = 'name';
  static const String photoUrlField = 'photoUrl';
  static const String statusField = 'status';
  static const String roleField = 'role';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';

  // User status values
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusBanned = 'banned';

  // User roles
  static const String roleMember = 'member';
  static const String roleAdmin = 'admin';
  static const String roleFoundingAdmin = 'founding_admin';

  // Message fields
  static const String messageIdField = 'messageId';
  static const String senderIdField = 'senderId';
  static const String contentField = 'content';
  static const String messageTypeField = 'type';
  static const String timestampField = 'timestamp';
  static const String attachmentsField = 'attachments';

  // Message types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';
  static const String messageTypeLink = 'link';
}
