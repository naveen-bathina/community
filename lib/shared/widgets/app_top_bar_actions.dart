import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/about/presentation/screens/about_screen.dart';
import 'package:legal_unity_network/features/admin/presentation/screens/admin_join_requests_screen.dart';
import 'package:legal_unity_network/features/admin/presentation/screens/manage_default_admins_screen.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/help/presentation/screens/help_support_screen.dart';
import 'package:legal_unity_network/features/legal/presentation/screens/legal_screen.dart';
import 'package:legal_unity_network/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/user_settings_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:legal_unity_network/shared/widgets/app_brand.dart';

enum AppProfileMenuAction {
  manageProfile,
  userSettings,
  aboutUnion,
  legalCompliance,
  helpSupport,
  inviteColleagues,
  manageDefaultAdmins,
  verifyJoinRequests,
  signOut,
}

/// Constant top-right action bar items (Notification Bell + Profile Avatar Menu)
/// used across the application.
class AppTopBarActions extends ConsumerWidget {
  final bool showNotificationBell;

  const AppTopBarActions({
    super.key,
    this.showNotificationBell = true,
  });

  ImageProvider? _buildAvatar(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      final commaIdx = url.indexOf(',');
      if (commaIdx != -1) {
        try {
          return MemoryImage(base64Decode(url.substring(commaIdx + 1)));
        } catch (_) {
          return null;
        }
      }
    }
    return NetworkImage(url);
  }

  AuthUser _effectiveUser(AuthUser? user) {
    return user ??
        AuthUser(
          uid: 'guest-member',
          email: 'member@legalunity.org',
          firstName: 'Legal',
          lastName: 'Member',
          status: UserStatus.approved,
          role: UserRole.member,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
  }

  Future<void> _onMenuSelected(
    BuildContext context,
    WidgetRef ref,
    AppProfileMenuAction action,
    AuthUser effectiveUser,
  ) async {
    switch (action) {
      case AppProfileMenuAction.manageProfile:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MyProfileScreen(currentUser: effectiveUser),
          ),
        );
        break;
      case AppProfileMenuAction.userSettings:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => UserSettingsScreen(currentUser: effectiveUser),
          ),
        );
        break;
      case AppProfileMenuAction.aboutUnion:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AboutScreen(),
          ),
        );
        break;
      case AppProfileMenuAction.legalCompliance:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const LegalScreen(),
          ),
        );
        break;
      case AppProfileMenuAction.helpSupport:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const HelpSupportScreen(),
          ),
        );
        break;
      case AppProfileMenuAction.inviteColleagues:
        await showDialog<void>(
          context: context,
          builder: (_) => const InviteAdvocatesDialog(),
        );
        break;
      case AppProfileMenuAction.manageDefaultAdmins:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ManageDefaultAdminsScreen(),
          ),
        );
        break;
      case AppProfileMenuAction.verifyJoinRequests:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AdminJoinRequestsScreen(),
          ),
        );
        break;
      case AppProfileMenuAction.signOut:
        await ref.read(authProvider.notifier).signOut();
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final effectiveUser = _effectiveUser(user);
    final avatar = _buildAvatar(user?.photoUrl);
    final initials = effectiveUser.fullName.isNotEmpty
        ? effectiveUser.fullName[0].toUpperCase()
        : 'U';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNotificationBell)
          IconButton(
            key: const Key('top_right_notifications_bell'),
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      NotificationsScreen(currentUser: effectiveUser),
                ),
              );
            },
          ),
        PopupMenuButton<AppProfileMenuAction>(
          key: const Key('top_right_profile_avatar_menu'),
          tooltip: 'Profile & Settings Menu',
          onSelected: (action) =>
              _onMenuSelected(context, ref, action, effectiveUser),
          itemBuilder: (context) => [
            PopupMenuItem<AppProfileMenuAction>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effectiveUser.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    effectiveUser.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<AppProfileMenuAction>(
              value: AppProfileMenuAction.manageProfile,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryBlue,
                ),
                title: Text('Manage Profile'),
              ),
            ),
            const PopupMenuItem<AppProfileMenuAction>(
              value: AppProfileMenuAction.userSettings,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.settings_outlined,
                  color: AppTheme.primaryBlue,
                ),
                title: Text('User Settings'),
              ),
            ),
            const PopupMenuItem<AppProfileMenuAction>(
              value: AppProfileMenuAction.aboutUnion,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryBlue,
                ),
                title: Text('About Union'),
              ),
            ),
            const PopupMenuItem<AppProfileMenuAction>(
              value: AppProfileMenuAction.legalCompliance,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.policy_outlined,
                  color: AppTheme.primaryBlue,
                ),
                title: Text('Legal & Compliance'),
              ),
            ),
            const PopupMenuItem<AppProfileMenuAction>(
              value: AppProfileMenuAction.helpSupport,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.help_outline,
                  color: AppTheme.primaryBlue,
                ),
                title: Text('Help & Support'),
              ),
            ),
            const PopupMenuItem<AppProfileMenuAction>(
              value: AppProfileMenuAction.inviteColleagues,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.share_outlined,
                  color: AppTheme.primaryBlue,
                ),
                title: Text('Invite Colleagues'),
              ),
            ),
            if (effectiveUser.isSuperAdmin)
              PopupMenuItem<AppProfileMenuAction>(
                value: AppProfileMenuAction.manageDefaultAdmins,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.security,
                    color: Colors.amber.shade800,
                  ),
                  title: Text(
                    'Super User: Set Default Admins',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (effectiveUser.isAdmin)
              const PopupMenuItem<AppProfileMenuAction>(
                value: AppProfileMenuAction.verifyJoinRequests,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: Text('Admin: Verify Join Requests'),
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<AppProfileMenuAction>(
              value: AppProfileMenuAction.signOut,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout, color: AppTheme.errorRed),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: avatar,
              child: avatar == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
