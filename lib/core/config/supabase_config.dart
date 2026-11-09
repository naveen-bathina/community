import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration for Supabase client initialization and access.
///
/// Never pass a `service_role` or secret key to the Flutter client.
/// Only use your project's public/publishable (`anon`) key via `--dart-define`.
class SupabaseConfig {
  SupabaseConfig._();

  /// Default Supabase project URL for Legal Unity Network (`lpuxvdwuwyybzwubfcfz`).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lpuxvdwuwyybzwubfcfz.supabase.co',
  );

  /// Publishable / anon key provided via `--dart-define=SUPABASE_ANON_KEY=...`.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  static bool _initialized = false;

  /// Whether Supabase has been initialized with a valid URL and anon key.
  static bool get isConfigured =>
      _initialized && supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Initializes the Supabase Flutter SDK if [supabaseAnonKey] is configured.
  static Future<void> initialize() async {
    if (_initialized || supabaseAnonKey.isEmpty) {
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }

  /// Convenience getter for the active [SupabaseClient].
  static SupabaseClient get client => Supabase.instance.client;
}
