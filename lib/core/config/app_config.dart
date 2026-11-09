/// Central branding and application configuration.
/// Allows app title and branding elements to be configured via:
/// 1. Compile-time environment definition: `--dart-define=APP_NAME=...`
/// 2. Programmatic runtime configuration: `AppConfig.setAppName(...)`
class AppConfig {
  static const String defaultAppName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Jai Bhim Advocate Union',
  );

  static String _appName = defaultAppName;

  /// The active application title / branding name.
  static String get appName => _appName;

  /// Returns welcoming header text branded with the active application name.
  static String get welcomeTitle => 'Welcome to $appName';

  /// Updates the application title dynamically at runtime.
  static void setAppName(String name) {
    _appName = name;
  }

  /// Resets the application title to the default configuration.
  static void reset() {
    _appName = defaultAppName;
  }
}
