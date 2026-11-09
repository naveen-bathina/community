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

  // Super User Configuration
  static const String superAdminEmail = 'naveen.bathina9@gmail.com';

  /// Returns true if [email] matches the designated Super User email.
  static bool isSuperAdminEmail(String? email) {
    if (email == null) return false;
    return email.trim().toLowerCase() == superAdminEmail.toLowerCase();
  }

  // Branding & Philosophy
  static const String appMotto = 'Educate • Agitate • Organize';
  static const String appTagline = 'Equality • Liberty • Fraternity • Justice';
  static const String appSubtitle =
      'Professional Solidarity, Case Referrals & Democratic Bar Governance';
  static const String appVersion = '1.0.0+1';
  static const String appLogoAsset = 'assets/images/app_logo.png';
  static const String appLogoHighResAsset = 'assets/images/app_logo_1024.png';

  // Mission & Identity
  static const String organizationName = 'Jai Bhim Advocate Union';
  static const String missionStatement =
      'Empowering legal practitioners across India with democratic bar governance, verified advocate referrals, and unwavering dedication to constitutional justice and equal legal aid.';

  // Contact & Secretariat
  static const String supportEmail = 'support@jaibhimadvocates.org';
  static const String grievanceEmail = 'grievance@jaibhimadvocates.org';
  static const String helplinePhone = '+91 1800-202-1950';
  static const String secretariatAddress =
      'National Legal Secretariat, Advocate Chambers, Bar Complex, New Delhi - 110001';
  static const String websiteUrl = 'https://jaibhimadvocates.org';

  // Bar Council Regulatory Disclaimer
  static const String bciComplianceSummary =
      'Compliant with Bar Council of India Rules (Rule 36, Section IV). This application is an internal, non-commercial communication and welfare directory for enrolled advocates. It is not an advertisement or client solicitation service.';
}
