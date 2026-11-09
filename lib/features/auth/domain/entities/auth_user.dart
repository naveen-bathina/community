import 'package:equatable/equatable.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';

/// Authenticated user entity including join-request profile details.
class AuthUser extends Equatable {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? stateBarAssociation;
  final String? enrollmentNumber;
  final String? photoUrl;
  final String? rejectionReason;
  final UserStatus status;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AuthUser({
    required this.uid,
    required this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.stateBarAssociation,
    this.enrollmentNumber,
    this.photoUrl,
    this.rejectionReason,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final combined = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return combined.isNotEmpty ? combined : email;
  }

  /// Whether the user has completed and submitted the mandatory join request details.
  bool get hasSubmittedJoinRequest =>
      isApproved ||
      ((firstName != null && firstName!.trim().isNotEmpty) &&
          (lastName != null && lastName!.trim().isNotEmpty) &&
          (stateBarAssociation != null &&
              stateBarAssociation!.trim().isNotEmpty) &&
          (enrollmentNumber != null && enrollmentNumber!.trim().isNotEmpty));

  bool get isApproved => status == UserStatus.approved;
  bool get isPending => status == UserStatus.pending;
  bool get isRejected => status == UserStatus.rejected;
  bool get isBanned => status == UserStatus.banned;
  bool get isAdmin =>
      role == UserRole.admin || role == UserRole.foundingAdmin;

  AuthUser copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? stateBarAssociation,
    String? enrollmentNumber,
    String? photoUrl,
    String? rejectionReason,
    UserStatus? status,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      stateBarAssociation: stateBarAssociation ?? this.stateBarAssociation,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      status: status ?? this.status,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'stateBarAssociation': stateBarAssociation,
      'enrollmentNumber': enrollmentNumber,
      'photoUrl': photoUrl,
      'rejectionReason': rejectionReason,
      'status': status.value,
      'role': role.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: (json['uid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: json['phoneNumber'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] is String
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      stateBarAssociation: json['stateBarAssociation'] as String?,
      enrollmentNumber: json['enrollmentNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      status: UserStatus.fromString((json['status'] as String?) ?? 'pending'),
      role: UserRole.fromString((json['role'] as String?) ?? 'member'),
      createdAt: json['createdAt'] is String
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        phoneNumber,
        firstName,
        lastName,
        dateOfBirth,
        gender,
        stateBarAssociation,
        enrollmentNumber,
        photoUrl,
        rejectionReason,
        status,
        role,
        createdAt,
        updatedAt,
      ];
}
