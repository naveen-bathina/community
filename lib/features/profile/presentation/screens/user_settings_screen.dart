import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/about/presentation/screens/about_screen.dart';
import 'package:legal_unity_network/features/admin/presentation/screens/manage_default_admins_screen.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/help/presentation/screens/help_support_screen.dart';
import 'package:legal_unity_network/features/legal/presentation/screens/legal_screen.dart';
import 'package:legal_unity_network/shared/widgets/app_brand.dart';
import 'package:legal_unity_network/shared/widgets/app_top_bar_actions.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  final AuthUser currentUser;

  const UserSettingsScreen({super.key, required this.currentUser});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  bool _broadcastAlerts = true;
  bool _electionAlerts = true;
  bool _showPhoneInDirectory = true;
  bool _showEmailInDirectory = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Settings'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: const [
          AppTopBarActions(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.currentUser.isSuperAdmin) ...[
            Card(
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.shade300, width: 1.5),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade800,
                  child: const Icon(Icons.security, color: Colors.white, size: 20),
                ),
                title: const Text(
                  'Super User Governance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D3E00),
                  ),
                ),
                subtitle: const Text(
                  'Set default and founding administrators',
                  style: TextStyle(fontSize: 12.5),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF5D3E00)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ManageDefaultAdminsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Account Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.person_outline,
                      color: AppTheme.primaryBlue,
                    ),
                    title: Text(widget.currentUser.fullName),
                    subtitle: Text(widget.currentUser.email),
                  ),
                  if (widget.currentUser.stateBarAssociation != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.verified_user_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                      title: Text(widget.currentUser.stateBarAssociation!),
                      subtitle: Text(
                        'Enrollment No: ${widget.currentUser.enrollmentNumber ?? "Verified"}',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Notification Preferences
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Official Bar Broadcasts'),
                    subtitle: const Text(
                      'Receive important community announcements',
                    ),
                    value: _broadcastAlerts,
                    onChanged: (val) => setState(() => _broadcastAlerts = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Governance & Election Updates'),
                    subtitle: const Text(
                      'Alerts when nominations or voting periods open',
                    ),
                    value: _electionAlerts,
                    onChanged: (val) => setState(() => _electionAlerts = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Directory Privacy
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Directory Privacy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Mobile Number in Directory'),
                    value: _showPhoneInDirectory,
                    onChanged: (val) =>
                        setState(() => _showPhoneInDirectory = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Email Address in Directory'),
                    value: _showEmailInDirectory,
                    onChanged: (val) =>
                        setState(() => _showEmailInDirectory = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Union & Community Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Union & Fraternity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryBlue,
                    ),
                    title: const Text('About Union'),
                    subtitle: const Text('Mission, vision, Dr. Ambedkar ideals & leadership'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.share_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    title: const Text('Invite Colleague Advocates'),
                    subtitle: const Text('Share platform invite with members of your Bar'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => const InviteAdvocatesDialog(),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.help_outline,
                      color: AppTheme.primaryBlue,
                    ),
                    title: const Text('Help, FAQ & Support Desk'),
                    subtitle: const Text('Grievance cell, questions, and guides'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legal, Privacy & Compliance Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legal & Compliance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.description_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    title: const Text('Terms of Service & By-Laws'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalScreen(initialTabIndex: 0),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    title: const Text('Advocate Data Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalScreen(initialTabIndex: 1),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.gavel_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    title: const Text('Bar Council Disclaimer'),
                    subtitle: const Text('BCI Rule 36 Non-Solicitation Compliance'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalScreen(initialTabIndex: 2),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.handshake_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    title: const Text('Advocate Code of Conduct & Ethics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalScreen(initialTabIndex: 3),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sign Out button
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            label: const Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
          const SizedBox(height: 24),

          // App Version & Brand Footer
          Center(
            child: Column(
              children: [
                const AppLogo(size: 32, showBadgeBorder: false),
                const SizedBox(height: 6),
                Text(
                  AppConfig.appName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                Text(
                  'Version ${AppConfig.appVersion} • ${AppConfig.appMotto}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
