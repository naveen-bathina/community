import '../entities/community_post.dart';

abstract class WallRepository {
  Future<List<CommunityPost>> getPosts();

  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorRole,
    required String content,
    String category = 'General',
    List<String> imageUrls = const [],
    List<String> links = const [],
    List<String> docUrls = const [],
  });

  Future<void> toggleLike({
    required String postId,
    required String userId,
  });

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  });
}
