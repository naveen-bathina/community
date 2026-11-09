import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/community_post.dart';
import '../providers/wall_provider.dart';
import '../widgets/post_comments_bottom_sheet.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final CommunityPost post;
  final AuthUser currentUser;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUser,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
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

  Future<void> _toggleLike() async {
    await ref.read(wallRepositoryProvider).toggleLike(
          postId: _post.id,
          userId: widget.currentUser.uid,
        );

    final updatedLikes = List<String>.from(_post.likedBy);
    if (updatedLikes.contains(widget.currentUser.uid)) {
      updatedLikes.remove(widget.currentUser.uid);
    } else {
      updatedLikes.add(widget.currentUser.uid);
    }

    if (mounted) {
      setState(() {
        _post = _post.copyWith(likedBy: updatedLikes);
      });
    }
  }

  Future<void> _addComment() async {
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

      if (mounted) {
        setState(() {
          _post = _post.copyWith(
            comments: [..._post.comments, newComment],
          );
          _commentController.clear();
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openCommentsBottomSheet() {
    showPostCommentsBottomSheet(
      context: context,
      ref: ref,
      post: _post,
      currentUser: widget.currentUser,
      onCommentAdded: (updatedPost) {
        if (mounted) {
          setState(() => _post = updatedPost);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _post.isLikedBy(widget.currentUser.uid);

    return Scaffold(
      key: const Key('full_screen_post_scaffold'),
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          IconButton(
            key: const Key('open_comments_sheet_appbar_btn'),
            icon: const Icon(Icons.mode_comment_outlined),
            tooltip: 'View comments bottom sheet',
            onPressed: _openCommentsBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppTheme.primaryBlue.withValues(alpha: 0.15),
                        child: Text(
                          _post.authorName.isNotEmpty
                              ? _post.authorName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _post.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _post.authorRole,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          _post.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Post content
                  if (_post.content.isNotEmpty) ...[
                    SelectableText(
                      _post.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Post images
                  if (_post.imageUrls.isNotEmpty) ...[
                    ..._post.imageUrls.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final img = entry.value;
                      return Container(
                        key: Key('post_image_$idx'),
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        ),
                        child: _buildPostImage(img),
                      );
                    }),
                  ],

                  // Post links
                  if (_post.links.isNotEmpty) ...[
                    ..._post.links.map(
                      (link) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () async {
                            final uri = Uri.tryParse(link);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link,
                                  size: 18,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    link,
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Post docs
                  if (_post.docUrls.isNotEmpty) ...[
                    ..._post.docUrls.map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: AppTheme.primaryBlue,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  doc,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DOC',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  const Divider(height: 1),

                  // Actions row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        TextButton.icon(
                          key: Key('detail_like_post_${_post.id}'),
                          onPressed: _toggleLike,
                          icon: Icon(
                            isLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 20,
                            color: isLiked
                                ? AppTheme.primaryBlue
                                : AppTheme.textSecondaryLight,
                          ),
                          label: Text('${_post.likeCount} Likes'),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          key: Key('detail_comment_post_${_post.id}'),
                          onPressed: _openCommentsBottomSheet,
                          icon: const Icon(
                            Icons.mode_comment_outlined,
                            size: 20,
                          ),
                          label: Text('${_post.commentCount} Comments'),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Comments section
                  Text(
                    'Comments (${_post.commentCount})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_post.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No comments yet. Start the conversation!',
                          style: TextStyle(color: AppTheme.textSecondaryLight),
                        ),
                      ),
                    )
                  else
                    ..._post.comments.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.primaryBlue
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      c.authorName.isNotEmpty
                                          ? c.authorName[0].toUpperCase()
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
                                      c.authorName,
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
                                c.content,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom comment input bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('detail_comment_input_field'),
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
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
                  key: const Key('detail_submit_comment_button'),
                  onPressed: _isSubmitting ? null : _addComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(String img) {
    if (img.startsWith('data:image')) {
      final commaIdx = img.indexOf(',');
      if (commaIdx != -1) {
        try {
          final bytes = base64Decode(img.substring(commaIdx + 1));
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
          );
        } catch (_) {}
      }
    }
    if (img.startsWith('http')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          height: 140,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image, size: 40, color: Colors.grey),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
      child: Center(
        child: Text(img, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
