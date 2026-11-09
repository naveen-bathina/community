class PostComment {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'] ?? map['created_at'];
    DateTime parsedTime = DateTime.now();
    if (rawCreatedAt is DateTime) {
      parsedTime = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedTime = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    return PostComment(
      id: (map['id'] ?? '').toString(),
      authorId: (map['authorId'] ?? map['author_id'] ?? '').toString(),
      authorName: (map['authorName'] ?? map['author_name'] ?? 'Member')
          .toString(),
      content: (map['content'] ?? '').toString(),
      createdAt: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final String category;
  final List<String> imageUrls;
  final List<String> links;
  final List<String> docUrls;
  final List<String> likedBy;
  final List<PostComment> comments;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    this.category = 'General',
    this.imageUrls = const [],
    this.links = const [],
    this.docUrls = const [],
    this.likedBy = const [],
    this.comments = const [],
    required this.createdAt,
  });

  int get likeCount => likedBy.length;
  int get commentCount => comments.length;
  bool isLikedBy(String userId) => likedBy.contains(userId);

  CommunityPost copyWith({
    List<String>? likedBy,
    List<PostComment>? comments,
    List<String>? imageUrls,
    List<String>? links,
    List<String>? docUrls,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      content: content,
      category: category,
      imageUrls: imageUrls ?? this.imageUrls,
      links: links ?? this.links,
      docUrls: docUrls ?? this.docUrls,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      createdAt: createdAt,
    );
  }

  factory CommunityPost.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawCreatedAt = map['createdAt'] ?? map['created_at'];
    DateTime parsedTime = DateTime.now();
    if (rawCreatedAt is DateTime) {
      parsedTime = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedTime = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    final rawLikes = map['likedBy'] ?? map['liked_by'];
    final likedByList = rawLikes is List
        ? rawLikes.map((e) => e.toString()).toList()
        : <String>[];

    final rawComments = map['comments'];
    final commentsList = rawComments is List
        ? rawComments
              .whereType<Map>()
              .map((c) => PostComment.fromMap(Map<String, dynamic>.from(c)))
              .toList()
        : <PostComment>[];

    final rawImages = map['imageUrls'] ?? map['image_urls'] ?? map['images'];
    final imagesList = rawImages is List
        ? rawImages.map((e) => e.toString()).toList()
        : <String>[];

    final rawLinks = map['links'];
    final linksList = rawLinks is List
        ? rawLinks.map((e) => e.toString()).toList()
        : <String>[];

    final rawDocs = map['docUrls'] ?? map['doc_urls'] ?? map['docs'];
    final docsList = rawDocs is List
        ? rawDocs.map((e) => e.toString()).toList()
        : <String>[];

    return CommunityPost(
      id: (docId ?? map['id'] ?? '').toString(),
      authorId: (map['authorId'] ?? map['author_id'] ?? '').toString(),
      authorName: (map['authorName'] ?? map['author_name'] ?? 'Advocate')
          .toString(),
      authorRole:
          (map['authorRole'] ?? map['author_role'] ?? 'Verified Member')
              .toString(),
      content: (map['content'] ?? '').toString(),
      category: (map['category'] ?? 'General').toString(),
      imageUrls: imagesList,
      links: linksList,
      docUrls: docsList,
      likedBy: likedByList,
      comments: commentsList,
      createdAt: parsedTime,
    );
  }
}
