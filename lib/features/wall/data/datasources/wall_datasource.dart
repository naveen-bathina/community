import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/repositories/wall_repository.dart';

class FirebaseWallRepository implements WallRepository {
  final FirebaseFirestore _firestore;

  FirebaseWallRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<CommunityPost>> getPosts() async {
    final snap = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      final ts = data['createdAt'];
      return CommunityPost.fromMap({
        ...data,
        'createdAt': ts is Timestamp ? ts.toDate() : DateTime.now(),
      }, docId: doc.id);
    }).toList();
  }

  @override
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorRole,
    required String content,
    String category = 'General',
    List<String> imageUrls = const [],
    List<String> links = const [],
    List<String> docUrls = const [],
  }) async {
    await _firestore.collection('posts').add({
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'content': content.trim(),
      'category': category,
      'imageUrls': imageUrls,
      'links': links,
      'docUrls': docUrls,
      'likedBy': <String>[],
      'comments': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final ref = _firestore.collection('posts').doc(postId);
    final doc = await ref.get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final likedBy = List<String>.from(
      (data['likedBy'] as List?)?.map((e) => e.toString()) ?? const [],
    );
    if (likedBy.contains(userId)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final ref = _firestore.collection('posts').doc(postId);
    final comment = PostComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: authorId,
      authorName: authorName,
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    await ref.update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }
}

class SupabaseWallRepository implements WallRepository {
  final SupabaseClient _supabase;

  SupabaseWallRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<CommunityPost>> getPosts() async {
    final rows = await _supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((r) => CommunityPost.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorRole,
    required String content,
    String category = 'General',
    List<String> imageUrls = const [],
    List<String> links = const [],
    List<String> docUrls = const [],
  }) async {
    await _supabase.from('posts').insert({
      'author_id': authorId,
      'author_name': authorName,
      'author_role': authorRole,
      'content': content.trim(),
      'category': category,
      'image_urls': imageUrls,
      'links': links,
      'doc_urls': docUrls,
      'liked_by': <String>[],
      'comments': <Map<String, dynamic>>[],
    });
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final rows = await _supabase.from('posts').select().eq('id', postId);
    if ((rows as List).isEmpty) return;
    final post = CommunityPost.fromMap(Map<String, dynamic>.from(rows.first));
    final likes = List<String>.from(post.likedBy);
    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    await _supabase
        .from('posts')
        .update({'liked_by': likes})
        .eq('id', postId);
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final rows = await _supabase.from('posts').select().eq('id', postId);
    if ((rows as List).isEmpty) return;
    final post = CommunityPost.fromMap(Map<String, dynamic>.from(rows.first));
    final updated = [
      ...post.comments.map((c) => c.toMap()),
      PostComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: authorId,
        authorName: authorName,
        content: content.trim(),
        createdAt: DateTime.now(),
      ).toMap(),
    ];
    await _supabase
        .from('posts')
        .update({'comments': updated})
        .eq('id', postId);
  }
}

class InMemoryWallRepository implements WallRepository {
  final List<CommunityPost> _posts = [
    CommunityPost(
      id: 'post-1',
      authorId: 'u-10',
      authorName: 'Adv. Kavita Krishnan',
      authorRole: 'Senior Counsel • Delhi Bar Association',
      content:
          'Looking for a co-counsel in Mumbai High Court for an urgent commercial arbitration hearing next week.',
      category: 'Case Referral',
      likedBy: const ['u-20'],
      comments: [
        PostComment(
          id: 'c-1',
          authorId: 'u-20',
          authorName: 'Adv. Rohan Deshmukh',
          content: 'Happy to assist in Bombay HC. Sent you a DM.',
          createdAt: DateTime(2026, 11, 9, 10, 15),
        ),
      ],
      createdAt: DateTime(2026, 11, 9, 10, 0),
    ),
  ];

  @override
  Future<List<CommunityPost>> getPosts() async => List.unmodifiable(_posts);

  @override
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorRole,
    required String content,
    String category = 'General',
    List<String> imageUrls = const [],
    List<String> links = const [],
    List<String> docUrls = const [],
  }) async {
    _posts.insert(
      0,
      CommunityPost(
        id: 'post-${_posts.length + 1}',
        authorId: authorId,
        authorName: authorName,
        authorRole: authorRole,
        content: content,
        category: category,
        imageUrls: imageUrls,
        links: links,
        docUrls: docUrls,
        likedBy: const [],
        comments: const [],
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    final likes = List<String>.from(post.likedBy);
    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    _posts[idx] = post.copyWith(likedBy: likes);
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    _posts[idx] = post.copyWith(
      comments: [
        ...post.comments,
        PostComment(
          id: 'c-${post.comments.length + 1}',
          authorId: authorId,
          authorName: authorName,
          content: content,
          createdAt: DateTime.now(),
        ),
      ],
    );
  }
}
