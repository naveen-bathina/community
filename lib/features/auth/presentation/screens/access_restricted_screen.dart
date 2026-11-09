import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/join_request_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';

/// Displayed when an authenticated user's status is `rejected` or `banned`.
class AccessRestrictedScreen extends ConsumerWidget {
  const AccessRestrictedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isBanned = user?.status == UserStatus.banned;
    final rejectionReason = user?.rejectionReason;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBanned ? 'Account Suspended' : 'Join Request Rejected'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                isBanned
                    ? 'Your Account Has Been Suspended'
                    : 'Registration Not Approved',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isBanned
                    ? 'Your access to ${AppConfig.appName} has been revoked by community moderation.'
                    : 'Your join request could not be verified. You may review your details and resubmit your request.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (!isBanned &&
                  rejectionReason != null &&
                  rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Admin Note: $rejectionReason',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (!isBanned) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const JoinRequestScreen(isEditing: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update & Resubmit Join Request'),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
