import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/join_request_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';

/// Wraps a screen with authentication, join-request completion, member-approval,
/// and optional admin-role guards.
///
/// Lifecycle flow:
/// 1. Unauthenticated (`user == null`) -> [PhoneLoginScreen]
/// 2. Banned (`user.status == UserStatus.banned`) -> [AccessRestrictedScreen]
/// 3. Approved (`user.status == UserStatus.approved`) -> lands directly on [child] ([HomeScreen])
/// 4. Signed up, but join request not yet submitted (`!user.hasSubmittedJoinRequest`)
///    -> [JoinRequestScreen]
/// 5. Join request rejected (`user.status == UserStatus.rejected`) -> [AccessRestrictedScreen]
/// 6. Join request pending admin verification (`user.status == UserStatus.pending`)
///    -> [PendingApprovalScreen] (when [requireApproved] is true)
class ProtectedRoute extends ConsumerWidget {
  final Widget child;
  final bool requireApproved;
  final bool requireAdmin;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.requireApproved = true,
    this.requireAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = authState.user;
    if (user == null) {
      return const PhoneLoginScreen();
    }

    if (user.status == UserStatus.banned) {
      return const AccessRestrictedScreen();
    }

    // Once approved by an admin, the user lands directly on the app's HomeScreen
    if (user.status == UserStatus.approved) {
      if (requireAdmin && !user.isAdmin) {
        return Scaffold(
          appBar: AppBar(title: const Text('Access Denied')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Admin privileges are required to view this page.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      return child;
    }

    if (!user.hasSubmittedJoinRequest) {
      return const JoinRequestScreen();
    }

    if (user.status == UserStatus.rejected) {
      return const AccessRestrictedScreen();
    }

    if (requireApproved && user.status == UserStatus.pending) {
      return const PendingApprovalScreen();
    }

    return child;
  }
}
