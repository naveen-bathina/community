import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_unity_network/features/about/presentation/screens/about_screen.dart';
import 'package:legal_unity_network/features/admin/presentation/screens/admin_join_requests_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/join_request_screen.dart';
import 'package:legal_unity_network/features/help/presentation/screens/help_support_screen.dart';
import 'package:legal_unity_network/features/legal/presentation/screens/legal_screen.dart';
import 'package:legal_unity_network/shared/widgets/app_brand.dart';

/// Displayed to authenticated Applicants whose Join Request is `pending` admin verification.
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final avatar = _buildAvatar(user?.photoUrl);
    final dobStr = user?.dateOfBirth != null
        ? DateFormat('dd MMM yyyy').format(user!.dateOfBirth!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Under Review'),
        actions: [
          IconButton(
            tooltip: 'Admin Verification Queue',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminJoinRequestsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 76),
              const SizedBox(height: 16),
              Text(
                'Pending Admin Approval',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your join request has been submitted and is awaiting verification by community admins.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (user != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: avatar,
                          child: avatar == null
                              ? const Icon(Icons.person, size: 36)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: const Text('Status: Pending Verification'),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                        ),
                        const Divider(height: 24),
                        if (dobStr != null)
                          _SummaryRow(label: 'Date Of Birth', value: dobStr),
                        if (user.gender != null)
                          _SummaryRow(label: 'Gender', value: user.gender!),
                        if (user.phoneNumber != null)
                          _SummaryRow(
                            label: 'Mobile Number',
                            value: user.phoneNumber!,
                          ),
                        if (user.stateBarAssociation != null)
                          _SummaryRow(
                            label: 'State Bar',
                            value: user.stateBarAssociation!,
                          ),
                        if (user.enrollmentNumber != null)
                          _SummaryRow(
                            label: 'Enrollment No.',
                            value: user.enrollmentNumber!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => ref.read(authProvider.notifier).refreshUser(),
                icon: const Icon(Icons.refresh),
                label: const Text('Check Approval Status'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const JoinRequestScreen(isEditing: true),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Join Request Details'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('About Union', style: TextStyle(fontSize: 12)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('Help & Support', style: TextStyle(fontSize: 12)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const HelpSupportScreen()),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.policy_outlined, size: 16),
                    label: const Text('Terms & By-Laws', style: TextStyle(fontSize: 12)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const LegalScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
