import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
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
          const SizedBox(height: 20),
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
        ],
      ),
    );
  }
}
