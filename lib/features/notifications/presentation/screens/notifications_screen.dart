import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../../shared/widgets/app_brand.dart';
import '../../../../shared/widgets/app_top_bar_actions.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  final AuthUser currentUser;

  const NotificationsScreen({super.key, required this.currentUser});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<BroadcastMessage> _broadcasts = [];
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final broadcasts = await repo.getBroadcasts();
      final notifications = await repo.getNotifications(widget.currentUser.uid);
      if (!mounted) return;
      setState(() {
        _broadcasts = broadcasts;
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _showPublishBroadcastDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Community Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('broadcast_title_input'),
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('broadcast_content_input'),
              controller: contentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Announcement Content',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('publish_broadcast_submit'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (submitted == true &&
        titleCtrl.text.trim().isNotEmpty &&
        contentCtrl.text.trim().isNotEmpty) {
      try {
        await ref.read(notificationsRepositoryProvider).publishBroadcast(
              senderId: widget.currentUser.uid,
              senderName: widget.currentUser.fullName,
              title: titleCtrl.text.trim(),
              content: contentCtrl.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Broadcast published successfully')),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not publish broadcast: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await ref.read(notificationsRepositoryProvider).markAsRead(notificationId);
      await _loadData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 26, showBadgeBorder: false),
              SizedBox(width: 8),
              Text('Broadcasts & Alerts'),
            ],
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          actions: const [
            AppTopBarActions(showNotificationBell: false),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              const Tab(
                icon: Icon(Icons.campaign_outlined),
                text: 'Broadcasts',
              ),
              Tab(
                icon: const Icon(Icons.notifications_outlined),
                text: 'Alerts ($_unreadCount)',
              ),
            ],
          ),
        ),
        floatingActionButton: widget.currentUser.isAdmin
            ? FloatingActionButton.extended(
                key: const Key('new_broadcast_button'),
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                onPressed: _showPublishBroadcastDialog,
                icon: const Icon(Icons.campaign),
                label: const Text('New Broadcast'),
              )
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBroadcastsTab(),
                  _buildAlertsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildBroadcastsTab() {
    if (_broadcasts.isEmpty) {
      return const Center(
        child: Text('No official broadcasts published yet.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _broadcasts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _broadcasts[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.content),
                const SizedBox(height: 8),
                Text(
                  'By ${item.senderName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_notifications.isEmpty) {
      return const Center(child: Text('No personal alerts.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final n = _notifications[index];
        return Card(
          color: n.isRead ? null : AppTheme.primaryBlue.withValues(alpha: 0.06),
          child: ListTile(
            leading: Icon(
              n.isRead
                  ? Icons.notifications_none
                  : Icons.notifications_active,
              color: n.isRead ? AppTheme.textSecondaryLight : AppTheme.primaryBlue,
            ),
            title: Text(
              n.title,
              style: TextStyle(
                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(n.body),
            trailing: n.isRead
                ? const Icon(Icons.done_all, size: 18, color: AppTheme.successGreen)
                : TextButton(
                    key: Key('mark_read_${n.id}'),
                    onPressed: () => _markAsRead(n.id),
                    child: const Text('Mark Read'),
                  ),
          ),
        );
      },
    );
  }
}
