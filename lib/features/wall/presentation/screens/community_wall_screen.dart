import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/community_post.dart';
import '../providers/wall_provider.dart';
import '../widgets/post_comments_bottom_sheet.dart';
import 'post_detail_screen.dart';

class CommunityWallScreen extends ConsumerStatefulWidget {
  final AuthUser currentUser;

  const CommunityWallScreen({super.key, required this.currentUser});

  @override
  ConsumerState<CommunityWallScreen> createState() =>
      CommunityWallScreenState();
}

class CommunityWallScreenState extends ConsumerState<CommunityWallScreen> {
  List<CommunityPost> _posts = [];
  bool _isLoading = true;

  Future<void> showCreatePostDialog() => _showCreatePostDialog();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await ref.read(wallRepositoryProvider).getPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _promptAddPicture() async {
    final urlCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (pCtx) => AlertDialog(
        title: const Text('Attach Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              key: const Key('pick_image_from_gallery_btn'),
              onPressed: () async {
                try {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    if (pCtx.mounted) {
                      Navigator.of(pCtx).pop(
                        'data:image/jpeg;base64,${base64Encode(bytes)}',
                      );
                    }
                  }
                } catch (_) {}
              },
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pick from Gallery'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Or enter Image URL:',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              key: const Key('post_image_url_input'),
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(pCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_add_image_btn'),
            onPressed: () => Navigator.of(pCtx).pop(urlCtrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptAddLink() async {
    final linkCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (lCtx) => AlertDialog(
        title: const Text('Attach Web Link'),
        content: TextField(
          key: const Key('post_link_input'),
          controller: linkCtrl,
          decoration: const InputDecoration(
            labelText: 'Web URL',
            hintText: 'https://livelaw.in/...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(lCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_add_link_btn'),
            onPressed: () => Navigator.of(lCtx).pop(linkCtrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptAddDoc() async {
    final docCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Attach Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              key: const Key('pick_doc_from_files_btn'),
              onPressed: () async {
                try {
                  final res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx'],
                  );
                  if (res != null && res.files.isNotEmpty) {
                    final name = res.files.first.name;
                    if (dCtx.mounted) {
                      Navigator.of(dCtx).pop(name);
                    }
                  }
                } catch (_) {}
              },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Choose Document File'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Or enter Document Title / Link:',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              key: const Key('post_doc_input'),
              controller: docCtrl,
              decoration: const InputDecoration(
                hintText: 'Contract_Brief.pdf',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_add_doc_btn'),
            onPressed: () => Navigator.of(dCtx).pop(docCtrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePostDialog() async {
    final contentCtrl = TextEditingController();
    String selectedCategory = 'Case Referral';
    final List<String> attachedImages = [];
    final List<String> attachedLinks = [];
    final List<String> attachedDocs = [];

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Wall Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Case Referral',
                      child: Text('Case Referral'),
                    ),
                    DropdownMenuItem(
                      value: 'Legal Update',
                      child: Text('Legal Update'),
                    ),
                    DropdownMenuItem(
                      value: 'Discussion',
                      child: Text('Discussion'),
                    ),
                    DropdownMenuItem(
                      value: 'General',
                      child: Text('General'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('wall_post_content_input'),
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Share with all Legal Unity members...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Attach to post:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('add_post_picture_btn'),
                      onPressed: () async {
                        final img = await _promptAddPicture();
                        if (img != null && img.isNotEmpty) {
                          setDialogState(() => attachedImages.add(img));
                        }
                      },
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Picture'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('add_post_link_btn'),
                      onPressed: () async {
                        final link = await _promptAddLink();
                        if (link != null && link.isNotEmpty) {
                          setDialogState(() => attachedLinks.add(link));
                        }
                      },
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Link'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('add_post_doc_btn'),
                      onPressed: () async {
                        final doc = await _promptAddDoc();
                        if (doc != null && doc.isNotEmpty) {
                          setDialogState(() => attachedDocs.add(doc));
                        }
                      },
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Doc'),
                    ),
                  ],
                ),
                if (attachedImages.isNotEmpty ||
                    attachedLinks.isNotEmpty ||
                    attachedDocs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...attachedImages.asMap().entries.map(
                            (e) => Chip(
                              avatar: const Icon(Icons.image, size: 16),
                              label: Text('Image ${e.key + 1}'),
                              onDeleted: () {
                                setDialogState(
                                  () => attachedImages.removeAt(e.key),
                                );
                              },
                            ),
                          ),
                      ...attachedLinks.asMap().entries.map(
                            (e) => Chip(
                              avatar: const Icon(Icons.link, size: 16),
                              label: Text(
                                e.value.length > 20
                                    ? '${e.value.substring(0, 18)}...'
                                    : e.value,
                              ),
                              onDeleted: () {
                                setDialogState(
                                  () => attachedLinks.removeAt(e.key),
                                );
                              },
                            ),
                          ),
                      ...attachedDocs.asMap().entries.map(
                            (e) => Chip(
                              avatar: const Icon(Icons.description, size: 16),
                              label: Text(
                                e.value.length > 20
                                    ? '${e.value.substring(0, 18)}...'
                                    : e.value,
                              ),
                              onDeleted: () {
                                setDialogState(
                                  () => attachedDocs.removeAt(e.key),
                                );
                              },
                            ),
                          ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('submit_wall_post_button'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true &&
        (contentCtrl.text.trim().isNotEmpty ||
            attachedImages.isNotEmpty ||
            attachedLinks.isNotEmpty ||
            attachedDocs.isNotEmpty)) {
      final roleLabel = widget.currentUser.stateBarAssociation != null
          ? '${widget.currentUser.role.value.toUpperCase()} • ${widget.currentUser.stateBarAssociation}'
          : 'Verified Member';
      await ref.read(wallRepositoryProvider).createPost(
            authorId: widget.currentUser.uid,
            authorName: widget.currentUser.fullName,
            authorRole: roleLabel,
            content: contentCtrl.text.trim(),
            category: selectedCategory,
            imageUrls: attachedImages,
            links: attachedLinks,
            docUrls: attachedDocs,
          );
      await _loadPosts();
    }
  }

  Future<void> _toggleLike(String postId) async {
    await ref.read(wallRepositoryProvider).toggleLike(
          postId: postId,
          userId: widget.currentUser.uid,
        );
    await _loadPosts();
  }

  Future<void> _openPostDetail(CommunityPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          post: post,
          currentUser: widget.currentUser,
        ),
      ),
    );
    await _loadPosts();
  }

  void _openCommentsBottomSheet(CommunityPost post) {
    showPostCommentsBottomSheet(
      context: context,
      ref: ref,
      post: post,
      currentUser: widget.currentUser,
      onCommentAdded: (_) {
        _loadPosts();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Community Wall',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No community posts yet. Be the first to share an update!',
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = _posts[index];
              final isLiked = post.isLikedBy(widget.currentUser.uid);

              return Card(
                key: Key('post_card_${post.id}'),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openPostDetail(post),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryBlue.withValues(alpha: 0.15),
                            child: Text(
                              post.authorName.isNotEmpty
                                  ? post.authorName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  post.authorRole,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              post.category,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (post.content.isNotEmpty) ...[
                        Text(
                          post.content,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (post.imageUrls.isNotEmpty) ...[
                        ...post.imageUrls.asMap().entries.map(
                          (entry) {
                            final idx = entry.key;
                            final img = entry.value;
                            return Container(
                              key: Key('post_image_$idx'),
                              margin: const EdgeInsets.only(bottom: 8),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.primaryBlue
                                    .withValues(alpha: 0.05),
                              ),
                              child: _buildPostImage(img),
                            );
                          },
                        ),
                      ],
                      if (post.links.isNotEmpty) ...[
                        ...post.links.map(
                          (link) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              onTap: () async {
                                final uri = Uri.tryParse(link);
                                if (uri != null && await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.link,
                                      size: 16,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        link,
                                        style: const TextStyle(
                                          color: AppTheme.primaryBlue,
                                          fontSize: 13,
                                          decoration:
                                              TextDecoration.underline,
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
                      if (post.docUrls.isNotEmpty) ...[
                        ...post.docUrls.map(
                          (doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    color: AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      doc,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'DOC',
                                      style: TextStyle(
                                        fontSize: 10,
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
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      Row(
                        children: [
                          TextButton.icon(
                            key: Key('like_post_${post.id}'),
                            onPressed: () => _toggleLike(post.id),
                            icon: Icon(
                              isLiked
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              size: 18,
                              color: isLiked
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textSecondaryLight,
                            ),
                            label: Text('${post.likeCount}'),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            key: Key('comment_post_${post.id}'),
                            onPressed: () => _openCommentsBottomSheet(post),
                            icon: const Icon(
                              Icons.mode_comment_outlined,
                              size: 18,
                            ),
                            label: Text('${post.commentCount}'),
                          ),
                        ],
                      ),
                      if (post.comments.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _openCommentsBottomSheet(post),
                          child: Text(
                            'View all ${post.comments.length} comments',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
            },
          ),
      ],
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
            height: 200,
            width: double.infinity,
          );
        } catch (_) {}
      }
    }
    if (img.startsWith('http')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image, size: 40, color: Colors.grey),
          ),
        ),
      );
    }
    return Container(
      height: 100,
      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                img,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
