import 'package:equatable/equatable.dart';
import '../../core/config/app_config.dart';

/// User model representing a Member or Applicant
class UserModel extends Equatable {
  final String userId;
  final String email;
  final String? phone;
  final String name;
  final String? photoUrl;
  final UserStatus status;
  final UserRole role;

  // Profile fields
  final List<BarAdmission>? barAdmissions;
  final String? lawSchool;
  final List<String>? practiceAreas;
  final String? firmOrganization;
  final int? yearsOfExperience;
  final String? city;
  final String? state;
  final String? bio;
  final AvailabilityStatus? availabilityStatus;
  final String? achievements;
  final String? cles;
  final String? publications;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.userId,
    required this.email,
    this.phone,
    required this.name,
    this.photoUrl,
    required this.status,
    required this.role,
    this.barAdmissions,
    this.lawSchool,
    this.practiceAreas,
    this.firmOrganization,
    this.yearsOfExperience,
    this.city,
    this.state,
    this.bio,
    this.availabilityStatus,
    this.achievements,
    this.cles,
    this.publications,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user is an approved member
  bool get isApproved => status == UserStatus.approved || isSuperAdmin;

  /// Check if user is an admin
  bool get isAdmin =>
      role == UserRole.admin ||
      role == UserRole.foundingAdmin ||
      role == UserRole.superAdmin ||
      AppConfig.isSuperAdminEmail(email);

  /// Check if user is the designated Super User
  bool get isSuperAdmin =>
      role == UserRole.superAdmin || AppConfig.isSuperAdminEmail(email);

  /// Check if user profile is complete
  bool get isProfileComplete {
    return barAdmissions != null &&
        barAdmissions!.isNotEmpty &&
        practiceAreas != null &&
        practiceAreas!.isNotEmpty &&
        city != null &&
        state != null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      status: UserStatus.fromString(json['status'] as String),
      role: UserRole.fromString(json['role'] as String),
      barAdmissions: (json['barAdmissions'] as List<dynamic>?)
          ?.map((e) => BarAdmission.fromJson(e as Map<String, dynamic>))
          .toList(),
      lawSchool: json['lawSchool'] as String?,
      practiceAreas: (json['practiceAreas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      firmOrganization: json['firmOrganization'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      bio: json['bio'] as String?,
      availabilityStatus: json['availabilityStatus'] != null
          ? AvailabilityStatus.fromString(json['availabilityStatus'] as String)
          : null,
      achievements: json['achievements'] as String?,
      cles: json['cles'] as String?,
      publications: json['publications'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'phone': phone,
      'name': name,
      'photoUrl': photoUrl,
      'status': status.value,
      'role': role.value,
      'barAdmissions': barAdmissions?.map((e) => e.toJson()).toList(),
      'lawSchool': lawSchool,
      'practiceAreas': practiceAreas,
      'firmOrganization': firmOrganization,
      'yearsOfExperience': yearsOfExperience,
      'city': city,
      'state': state,
      'bio': bio,
      'availabilityStatus': availabilityStatus?.value,
      'achievements': achievements,
      'cles': cles,
      'publications': publications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? phone,
    String? name,
    String? photoUrl,
    UserStatus? status,
    UserRole? role,
    List<BarAdmission>? barAdmissions,
    String? lawSchool,
    List<String>? practiceAreas,
    String? firmOrganization,
    int? yearsOfExperience,
    String? city,
    String? state,
    String? bio,
    AvailabilityStatus? availabilityStatus,
    String? achievements,
    String? cles,
    String? publications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      role: role ?? this.role,
      barAdmissions: barAdmissions ?? this.barAdmissions,
      lawSchool: lawSchool ?? this.lawSchool,
      practiceAreas: practiceAreas ?? this.practiceAreas,
      firmOrganization: firmOrganization ?? this.firmOrganization,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      city: city ?? this.city,
      state: state ?? this.state,
      bio: bio ?? this.bio,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      achievements: achievements ?? this.achievements,
      cles: cles ?? this.cles,
      publications: publications ?? this.publications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        email,
        phone,
        name,
        photoUrl,
        status,
        role,
        barAdmissions,
        lawSchool,
        practiceAreas,
        firmOrganization,
        yearsOfExperience,
        city,
        state,
        bio,
        availabilityStatus,
        achievements,
        cles,
        publications,
        createdAt,
        updatedAt,
      ];
}

/// Bar admission information
class BarAdmission extends Equatable {
  final String jurisdiction;
  final String barNumber;
  final int yearAdmitted;
  final int? endYear;
  final bool isCurrentlyPracticing;

  const BarAdmission({
    required this.jurisdiction,
    required this.barNumber,
    required this.yearAdmitted,
    this.endYear,
    this.isCurrentlyPracticing = true,
  });

  int get startYear => yearAdmitted;

  String get yearSpanText {
    if (!isCurrentlyPracticing && endYear != null) {
      return '$yearAdmitted - $endYear';
    }
    if (isCurrentlyPracticing) {
      return '$yearAdmitted - Present';
    }
    return '$yearAdmitted';
  }

  factory BarAdmission.fromJson(Map<String, dynamic> json) {
    final start = (json['startYear'] as int?) ??
        (json['yearAdmitted'] as int? ?? DateTime.now().year);
    final isPracticing = (json['isCurrentlyPracticing'] as bool?) ?? true;
    final end = json['endYear'] as int?;
    return BarAdmission(
      jurisdiction: (json['jurisdiction'] as String?) ?? '',
      barNumber: (json['barNumber'] as String?) ?? '',
      yearAdmitted: start,
      endYear: end,
      isCurrentlyPracticing: isPracticing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jurisdiction': jurisdiction,
      'barNumber': barNumber,
      'yearAdmitted': yearAdmitted,
      'startYear': yearAdmitted,
      'endYear': endYear,
      'isCurrentlyPracticing': isCurrentlyPracticing,
    };
  }

  @override
  List<Object?> get props => [
        jurisdiction,
        barNumber,
        yearAdmitted,
        endYear,
        isCurrentlyPracticing,
      ];
}

/// User status enum
enum UserStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  banned('banned');

  final String value;
  const UserStatus(this.value);

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserStatus.pending,
    );
  }
}

/// User role enum
enum UserRole {
  member('member'),
  admin('admin'),
  foundingAdmin('founding_admin'),
  superAdmin('super_admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.member,
    );
  }
}

/// Availability status enum
enum AvailabilityStatus {
  acceptingReferrals('accepting_referrals'),
  notTakingClients('not_taking_clients'),
  availableForConsultation('available_for_consultation');

  final String value;
  const AvailabilityStatus(this.value);

  static AvailabilityStatus fromString(String value) {
    return AvailabilityStatus.values.firstWhere((e) => e.value == value);
  }

  String get displayName {
    switch (this) {
      case AvailabilityStatus.acceptingReferrals:
        return 'Accepting Referrals';
      case AvailabilityStatus.notTakingClients:
        return 'Not Taking New Clients';
      case AvailabilityStatus.availableForConsultation:
        return 'Available for Consultation';
    }
  }
}
