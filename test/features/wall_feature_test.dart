import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/wall/domain/entities/community_post.dart';
import 'package:legal_unity_network/features/wall/domain/repositories/wall_repository.dart';
import 'package:legal_unity_network/features/wall/presentation/providers/wall_provider.dart';
import 'package:legal_unity_network/features/wall/presentation/screens/community_wall_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeWallRepository implements WallRepository {
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
  Future<List<CommunityPost>> getPosts() async {
    return List.unmodifiable(_posts);
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
    final updatedComments = [
      ...post.comments,
      PostComment(
        id: 'c-${post.comments.length + 1}',
        authorId: authorId,
        authorName: authorName,
        content: content,
        createdAt: DateTime.now(),
      ),
    ];
    _posts[idx] = post.copyWith(comments: updatedComments);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'CommunityWallScreen displays posts visible to all users, allows creating a post, liking, and commenting',
    (WidgetTester tester) async {
      final fakeRepo = FakeWallRepository();
      final currentUser = AuthUser(
        uid: 'u-99',
        email: 'sanjay@legalunity.org',
        firstName: 'Sanjay',
        lastName: 'Kulkarni',
        stateBarAssociation: 'Bar Council of Maharashtra & Goa',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final wallKey = GlobalKey<CommunityWallScreenState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wallRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CommunityWallScreen(
                  key: wallKey,
                  currentUser: currentUser,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                key: const Key('create_wall_post_button'),
                onPressed: () => wallKey.currentState?.showCreatePostDialog(),
                child: const Icon(Icons.post_add),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify existing post is visible to all users
      expect(find.text('Adv. Kavita Krishnan'), findsOneWidget);
      expect(
        find.textContaining('Looking for a co-counsel in Mumbai High Court'),
        findsOneWidget,
      );
      expect(find.text('1'), findsWidgets); // 1 like & 1 comment

      // Create a new post on the wall
      await tester.tap(find.byKey(const Key('create_wall_post_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('wall_post_content_input')),
        'Sharing summary of today’s Supreme Court constitution bench judgment on digital privacy.',
      );
      await tester.tap(find.byKey(const Key('submit_wall_post_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sanjay Kulkarni'), findsOneWidget);
      expect(
        find.text(
          'Sharing summary of today’s Supreme Court constitution bench judgment on digital privacy.',
        ),
        findsOneWidget,
      );

      // Like the existing post (post-1)
      await tester.tap(find.byKey(const Key('like_post_post-1')));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      // Add a comment on post-1
      await tester.tap(find.byKey(const Key('comment_post_post-1')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('comment_input_field')),
        'We can also assist with filing in Mumbai.',
      );
      await tester.tap(find.byKey(const Key('submit_comment_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('We can also assist with filing in Mumbai.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'CommunityWallScreen allows creating posts with texts, pictures, links, and documents',
    (WidgetTester tester) async {
      final fakeRepo = FakeWallRepository();
      final currentUser = AuthUser(
        uid: 'u-101',
        email: 'priya@legalunity.org',
        firstName: 'Priya',
        lastName: 'Sharma',
        stateBarAssociation: 'Bar Council of Delhi',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final wallKey = GlobalKey<CommunityWallScreenState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wallRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CommunityWallScreen(
                  key: wallKey,
                  currentUser: currentUser,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                key: const Key('create_wall_post_button'),
                onPressed: () => wallKey.currentState?.showCreatePostDialog(),
                child: const Icon(Icons.post_add),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap FAB to open Create Post dialog
      await tester.tap(find.byKey(const Key('create_wall_post_button')));
      await tester.pumpAndSettle();

      // Enter text content
      await tester.enterText(
        find.byKey(const Key('wall_post_content_input')),
        'Drafting sample statement of claim for international commercial arbitration under SIAC rules.',
      );

      // Add a Picture
      await tester.tap(find.byKey(const Key('add_post_picture_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('post_image_url_input')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('post_image_url_input')),
        'https://example.com/arbitration_hearing.jpg',
      );
      await tester.tap(find.byKey(const Key('confirm_add_image_btn')));
      await tester.pumpAndSettle();

      // Add a Web Link
      await tester.tap(find.byKey(const Key('add_post_link_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('post_link_input')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('post_link_input')),
        'https://siac.org.sg/siac-rules-2024',
      );
      await tester.tap(find.byKey(const Key('confirm_add_link_btn')));
      await tester.pumpAndSettle();

      // Add a Document
      await tester.tap(find.byKey(const Key('add_post_doc_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('post_doc_input')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('post_doc_input')),
        'SIAC_Claim_Statement_Template.pdf',
      );
      await tester.tap(find.byKey(const Key('confirm_add_doc_btn')));
      await tester.pumpAndSettle();

      // Submit the post
      await tester.tap(find.byKey(const Key('submit_wall_post_button')));
      await tester.pumpAndSettle();

      // Verify the post appears with text, picture, link, and doc
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(
        find.textContaining('Drafting sample statement of claim'),
        findsOneWidget,
      );
      expect(find.text('https://siac.org.sg/siac-rules-2024'), findsOneWidget);
      expect(find.text('SIAC_Claim_Statement_Template.pdf'), findsOneWidget);
      expect(find.byKey(const Key('post_image_0')), findsOneWidget);
    },
  );

  testWidgets(
    'Show post comments from bottom sheet and allow swipe up for full screen comments',
    (WidgetTester tester) async {
      final fakeRepo = FakeWallRepository();
      final currentUser = AuthUser(
        uid: 'u-99',
        email: 'sanjay@legalunity.org',
        firstName: 'Sanjay',
        lastName: 'Kulkarni',
        stateBarAssociation: 'Bar Council of Maharashtra & Goa',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final wallKey = GlobalKey<CommunityWallScreenState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wallRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CommunityWallScreen(
                  key: wallKey,
                  currentUser: currentUser,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap comment button on post-1 to open bottom sheet
      await tester.tap(find.byKey(const Key('comment_post_post-1')));
      await tester.pumpAndSettle();

      // Verify comments bottom sheet is displayed
      expect(find.byKey(const Key('post_comments_bottom_sheet')), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.text('Comments (1)'), findsOneWidget);
      expect(
        find.text('Happy to assist in Bombay HC. Sent you a DM.'),
        findsOneWidget,
      );

      // Verify swipe up on bottom sheet
      await tester.drag(
        find.byKey(const Key('post_comments_drag_handle')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Add a comment from the bottom sheet
      await tester.enterText(
        find.byKey(const Key('comment_input_field')),
        'Brief has been reviewed and notes prepared.',
      );
      await tester.tap(find.byKey(const Key('submit_comment_button')));
      await tester.pumpAndSettle();

      // Verify comment appears in bottom sheet
      expect(
        find.text('Brief has been reviewed and notes prepared.'),
        findsOneWidget,
      );
      expect(find.text('Comments (2)'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byKey(const Key('close_comments_sheet_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('post_comments_bottom_sheet')), findsNothing);
    },
  );

  testWidgets(
    'Show selected post on full screen mode',
    (WidgetTester tester) async {
      final fakeRepo = FakeWallRepository();
      final currentUser = AuthUser(
        uid: 'u-99',
        email: 'sanjay@legalunity.org',
        firstName: 'Sanjay',
        lastName: 'Kulkarni',
        stateBarAssociation: 'Bar Council of Maharashtra & Goa',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final wallKey = GlobalKey<CommunityWallScreenState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wallRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CommunityWallScreen(
                  key: wallKey,
                  currentUser: currentUser,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on post card to open in full screen mode
      await tester.tap(find.byKey(const Key('post_card_post-1')));
      await tester.pumpAndSettle();

      // Verify full screen post screen
      expect(find.byKey(const Key('full_screen_post_scaffold')), findsOneWidget);
      expect(find.text('Post Details'), findsOneWidget);
      expect(find.text('Adv. Kavita Krishnan'), findsOneWidget);
      expect(find.text('Senior Counsel • Delhi Bar Association'), findsOneWidget);
      expect(find.text('Case Referral'), findsOneWidget);
      expect(
        find.textContaining('Looking for a co-counsel in Mumbai High Court'),
        findsOneWidget,
      );

      // Verify back button navigates back to wall
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('full_screen_post_scaffold')), findsNothing);
      expect(find.text('Community Wall'), findsOneWidget);
    },
  );
}
