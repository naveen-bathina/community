import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/config/firebase_config.dart';
import 'package:legal_unity_network/core/config/supabase_config.dart';
import 'package:legal_unity_network/core/router/protected_route.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/about/presentation/screens/about_screen.dart';
import 'package:legal_unity_network/features/admin/presentation/screens/manage_default_admins_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/auth_gate_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/home_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:legal_unity_network/features/help/presentation/screens/help_support_screen.dart';
import 'package:legal_unity_network/features/legal/presentation/screens/legal_screen.dart';
import 'package:legal_unity_network/firebase_options.dart';
import 'package:legal_unity_network/shared/widgets/app_brand.dart';

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
            const AppLogo(size: 88),
            const SizedBox(height: 24),
            Text(
              AppConfig.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppConfig.appMotto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade800,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
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
      builder: (context, child) => FTheme(
        data: FThemes.zinc.light,
        child: child!,
      ),
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
        '/about': (context) => const AboutScreen(),
        '/legal': (context) => const LegalScreen(),
        '/help': (context) => const HelpSupportScreen(),
        '/admin/default-admins': (context) =>
            const ManageDefaultAdminsScreen(),
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
