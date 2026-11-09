import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Input payload when a newly signed-up user submits a Join Request for admin verification.
class JoinRequestInput extends Equatable {
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender;
  final String mobileNumber;
  final String stateBarAssociation;
  final String enrollmentNumber;
  final Uint8List? profilePhotoBytes;
  final String? existingPhotoUrl;

  const JoinRequestInput({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.mobileNumber,
    required this.stateBarAssociation,
    required this.enrollmentNumber,
    this.profilePhotoBytes,
    this.existingPhotoUrl,
  });

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        dateOfBirth,
        gender,
        mobileNumber,
        stateBarAssociation,
        enrollmentNumber,
        profilePhotoBytes,
        existingPhotoUrl,
      ];
}
