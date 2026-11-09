import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/config/firebase_config.dart';
import 'package:legal_unity_network/core/config/supabase_config.dart';
import 'package:legal_unity_network/core/router/protected_route.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/auth_gate_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/home_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:legal_unity_network/firebase_options.dart';

/// Simple full-screen splash page displayed while the app boots.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppConfig.appName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading ${AppConfig.appName.toLowerCase()}...',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGateScreen(),
        '/login': (context) => const PhoneLoginScreen(),
        '/pending-approval': (context) => const ProtectedRoute(
              requireApproved: false,
              child: PendingApprovalScreen(),
            ),
        '/restricted': (context) => const AccessRestrictedScreen(),
        '/home': (context) => const ProtectedRoute(
              requireApproved: true,
              child: HomeScreen(),
            ),
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (uses SUPABASE_URL and SUPABASE_ANON_KEY dart-defines)
  await SupabaseConfig.initialize();

  // Initialize Firebase fallback if not using Supabase exclusively
  if (!SupabaseConfig.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseConfig.enableOfflinePersistence();
    } catch (e) {
      debugPrint('Firebase fallback not initialized on this platform: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
