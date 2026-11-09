import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/community_post.dart';
import '../providers/wall_provider.dart';

/// Shows the post comments in a draggable bottom sheet that allows swiping up
/// for full-screen comments.
Future<void> showPostCommentsBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required CommunityPost post,
  required AuthUser currentUser,
  void Function(CommunityPost updatedPost)? onCommentAdded,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PostCommentsBottomSheet(
      post: post,
      currentUser: currentUser,
      onCommentAdded: onCommentAdded,
    ),
  );
}

class PostCommentsBottomSheet extends ConsumerStatefulWidget {
  final CommunityPost post;
  final AuthUser currentUser;
  final void Function(CommunityPost updatedPost)? onCommentAdded;

  const PostCommentsBottomSheet({
    super.key,
    required this.post,
    required this.currentUser,
    this.onCommentAdded,
  });

  @override
  ConsumerState<PostCommentsBottomSheet> createState() =>
      _PostCommentsBottomSheetState();
}

class _PostCommentsBottomSheetState
    extends ConsumerState<PostCommentsBottomSheet> {
  late CommunityPost _post;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(wallRepositoryProvider).addComment(
            postId: _post.id,
            authorId: widget.currentUser.uid,
            authorName: widget.currentUser.fullName,
            content: text,
          );

      final newComment = PostComment(
        id: 'c-${DateTime.now().millisecondsSinceEpoch}',
        authorId: widget.currentUser.uid,
        authorName: widget.currentUser.fullName,
        content: text,
        createdAt: DateTime.now(),
      );

      final updatedPost = _post.copyWith(
        comments: [..._post.comments, newComment],
      );

      if (mounted) {
        setState(() {
          _post = updatedPost;
          _commentController.clear();
          _isSubmitting = false;
        });
      }

      widget.onCommentAdded?.call(updatedPost);
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.of(context).viewInsets;

    return DraggableScrollableSheet(
      key: const Key('post_comments_bottom_sheet'),
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle for Swiping Up to Full Screen
                          Center(
                            child: Container(
                              key: const Key('post_comments_drag_handle'),
                              margin: const EdgeInsets.only(top: 10, bottom: 6),
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),

                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Comments (${_post.comments.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  key: const Key('close_comments_sheet_btn'),
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Close',
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      ),
                    ),

                    // Comments List or Empty State
                    if (_post.comments.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No comments yet. Start the conversation!',
                              style: TextStyle(
                                color: AppTheme.textSecondaryLight,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final comment = _post.comments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor:
                                                AppTheme.primaryBlue
                                                    .withValues(alpha: 0.15),
                                            child: Text(
                                              comment.authorName.isNotEmpty
                                                  ? comment.authorName[0]
                                                      .toUpperCase()
                                                  : 'A',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              comment.authorName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        comment.content,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _post.comments.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Input Field
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: insets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('comment_input_field'),
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const Key('submit_comment_button'),
                      onPressed: _isSubmitting ? null : _submitComment,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.send,
                              color: AppTheme.primaryBlue,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
