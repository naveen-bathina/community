import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/router/protected_route.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/home_screen.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ProtectedRoute(
      requireApproved: true,
      child: HomeScreen(),
    );
  }
}
