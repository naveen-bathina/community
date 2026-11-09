import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/shared/widgets/app_top_bar_actions.dart';

/// Admin screen to inspect pending Join Requests and either Approve or Reject them.
class AdminJoinRequestsScreen extends ConsumerStatefulWidget {
  const AdminJoinRequestsScreen({super.key});

  @override
  ConsumerState<AdminJoinRequestsScreen> createState() =>
      _AdminJoinRequestsScreenState();
}

class _AdminJoinRequestsScreenState
    extends ConsumerState<AdminJoinRequestsScreen> {
  String? _processingUserId;

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

  Future<void> _handleDecision(AuthUser applicant, {required bool approve}) async {
    String? rejectionReason;

    if (!approve) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reject Join Request'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection (optional)',
              hintText: 'e.g. Unable to verify bar enrollment number',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      rejectionReason = controller.text.trim();
    }

    setState(() => _processingUserId = applicant.uid);

    final error = await ref.read(authProvider.notifier).reviewJoinRequest(
          targetUserId: applicant.uid,
          approve: approve,
          rejectionReason: rejectionReason,
        );

    if (!mounted) return;

    setState(() => _processingUserId = null);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ref.invalidate(pendingJoinRequestsProvider);
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Approved ${applicant.fullName}'
                : 'Rejected ${applicant.fullName}',
          ),
        ),
      );
      if (approve &&
          ref.read(authProvider).isApproved &&
          Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingJoinRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Join Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingJoinRequestsProvider),
          ),
          const AppTopBarActions(),
        ],
      ),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading join requests: $err'),
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 64),
                    SizedBox(height: 16),
                    Text('No pending join requests to review.'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final applicant = requests[index];
              final avatar = _buildAvatar(applicant.photoUrl);
              final isBusy = _processingUserId == applicant.uid;
              final dobStr = applicant.dateOfBirth != null
                  ? DateFormat('dd MMM yyyy').format(applicant.dateOfBirth!)
                  : 'N/A';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: avatar,
                            child: avatar == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  applicant.fullName,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  applicant.stateBarAssociation ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'First Name',
                        value: applicant.firstName ?? '-',
                      ),
                      _DetailRow(
                        label: 'Last Name',
                        value: applicant.lastName ?? '-',
                      ),
                      _DetailRow(
                        label: 'Date Of Birth',
                        value: dobStr,
                      ),
                      _DetailRow(
                        label: 'Gender',
                        value: applicant.gender ?? '-',
                      ),
                      _DetailRow(
                        label: 'Mobile Number',
                        value: applicant.phoneNumber ?? '-',
                      ),
                      _DetailRow(
                        label: 'State Bar Association',
                        value: applicant.stateBarAssociation ?? '-',
                      ),
                      _DetailRow(
                        label: 'Enrollment Number',
                        value: applicant.enrollmentNumber ?? '-',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _handleDecision(
                                      applicant,
                                      approve: false,
                                    ),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _handleDecision(
                                      applicant,
                                      approve: true,
                                    ),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
