import '../config/app_config.dart';

/// Application-wide constants
class AppConstants {
  // App Info
  static String get appName => AppConfig.appName;
  static const String appVersion = '1.0.0';

  // File Upload Limits (Firebase Free Tier)
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxProfilePhotoSizeBytes = 500 * 1024; // 500KB

  // Allowed file types
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Election Constants
  static const int foundingAdminCount = 5;
  static const int electedAdminCount = 5;
  static const int firstElectionMemberThreshold = 25;
  static const int firstElectionDaysThreshold = 90;
  static const int nominationPeriodDays = 7;
  static const int votingPeriodDays = 14;
  static const int electionCycleYears = 1;

  // Moderation
  static const int muteDuration24Hours = 24;
  static const int muteDuration7Days = 7;

  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minBioLength = 10;
  static const int maxBioLength = 500;
  static const int minMessageLength = 1;
  static const int maxMessageLength = 5000;

  // Feature Flags (for future expansion)
  static const bool enablePushNotifications = false; // Free tier limitation
  static const bool enableMultipleGroups = false; // Single group for MVP

  // State Bar Councils
  static const List<String> stateBarCouncils = [
    'Bar Council of Andhra Pradesh',
    'Bar Council of Assam, Nagaland, Mizoram, Arunachal Pradesh & Sikkim',
    'Bar Council of Bihar',
    'Bar Council of Chhattisgarh',
    'Bar Council of Delhi',
    'Bar Council of Gujarat',
    'Bar Council of Himachal Pradesh',
    'Bar Council of Jammu & Kashmir',
    'Bar Council of Jharkhand',
    'Bar Council of Karnataka',
    'Bar Council of Kerala',
    'Bar Council of Madhya Pradesh',
    'Bar Council of Maharashtra & Goa',
    'Bar Council of Odisha',
    'Bar Council of Punjab & Haryana',
    'Bar Council of Rajasthan',
    'Bar Council of Tamil Nadu & Puducherry',
    'Bar Council of Telangana',
    'Bar Council of Tripura',
    'Bar Council of Uttar Pradesh',
    'Bar Council of Uttarakhand',
    'Bar Council of West Bengal',
    'Other State Bar Council',
  ];
}
