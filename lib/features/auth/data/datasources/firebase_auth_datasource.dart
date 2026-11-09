import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/features/auth/domain/repositories/auth_repository.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';

class FirebaseAuthDataSource implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore? _firestore;
  final GoogleSignIn _googleSignIn;

  // Holds the verificationId from the most recent OTP send so verifyOtp can use it.
  String? _verificationId;

  FirebaseAuthDataSource(
    this._firebaseAuth, {
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firestore = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<AuthUser?>.value(null);
      }
      return _db
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) => _mapUserWithData(user, snap.data()))
          .handleError((_) {});
    });
  }

  @override
  Future<AuthUser?> get currentUser async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUser(user);
  }

  Future<AuthUser> _mapFirebaseUser(User user) async {
    Map<String, dynamic>? data;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      data = doc.data();
    } catch (_) {
      // Safe fallback when offline or Firestore doc not created yet
    }
    return _mapUserWithData(user, data);
  }

  AuthUser _mapUserWithData(User user, Map<String, dynamic>? data) {
    UserStatus status = UserStatus.pending;
    UserRole role = UserRole.member;
    DateTime createdAt = user.metadata.creationTime ?? DateTime.now();
    DateTime updatedAt = user.metadata.lastSignInTime ?? createdAt;

    String? firstName;
    String? lastName;
    DateTime? dateOfBirth;
    String? gender;
    String? phone = user.phoneNumber;
    String? stateBarAssociation;
    String? enrollmentNumber;
    String? photoUrl = user.photoURL;
    String? rejectionReason;

    if (data != null) {
      firstName = data['firstName'] as String?;
      lastName = data['lastName'] as String?;
      if (data['dateOfBirth'] is String) {
        dateOfBirth = DateTime.tryParse(data['dateOfBirth'] as String);
      }
      gender = data['gender'] as String?;
      if (data['phone'] is String && (data['phone'] as String).isNotEmpty) {
        phone = data['phone'] as String;
      }
      stateBarAssociation = data['stateBarAssociation'] as String?;
      enrollmentNumber = data['enrollmentNumber'] as String?;
      if (data['photoUrl'] is String &&
          (data['photoUrl'] as String).isNotEmpty) {
        photoUrl = data['photoUrl'] as String;
      }
      rejectionReason = data['rejectionReason'] as String?;
      if (data['status'] is String) {
        status = _parseStatus(data['status'] as String);
      }
      if (data['role'] is String) {
        role = _parseRole(data['role'] as String);
      }
      if (data['createdAt'] is String) {
        createdAt =
            DateTime.tryParse(data['createdAt'] as String) ?? createdAt;
      }
      if (data['updatedAt'] is String) {
        updatedAt =
            DateTime.tryParse(data['updatedAt'] as String) ?? updatedAt;
      }
    }

    if (AppConfig.isSuperAdminEmail(user.email)) {
      status = UserStatus.approved;
      role = UserRole.superAdmin;
    }

    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      phoneNumber: phone,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      stateBarAssociation: stateBarAssociation,
      enrollmentNumber: enrollmentNumber,
      photoUrl: photoUrl,
      rejectionReason: rejectionReason,
      status: status,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AuthUser _mapFirestoreDoc(String docId, Map<String, dynamic> data) {
    final createdAt = DateTime.tryParse((data['createdAt'] as String?) ?? '') ??
        DateTime.now();
    final updatedAt = DateTime.tryParse((data['updatedAt'] as String?) ?? '') ??
        createdAt;

    return AuthUser(
      uid: (data['userId'] as String?) ?? docId,
      email: (data['email'] as String?) ?? '',
      phoneNumber: data['phone'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      dateOfBirth: data['dateOfBirth'] is String
          ? DateTime.tryParse(data['dateOfBirth'] as String)
          : null,
      gender: data['gender'] as String?,
      stateBarAssociation: data['stateBarAssociation'] as String?,
      enrollmentNumber: data['enrollmentNumber'] as String?,
      photoUrl: data['photoUrl'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      status: _parseStatus((data['status'] as String?) ?? 'pending'),
      role: _parseRole((data['role'] as String?) ?? 'member'),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  UserStatus _parseStatus(String raw) {
    for (final s in UserStatus.values) {
      if (s.value == raw) return s;
    }
    return UserStatus.pending;
  }

  UserRole _parseRole(String raw) {
    for (final r in UserRole.values) {
      if (r.value == raw) return r;
    }
    return UserRole.member;
  }

  @override
  Future<String?> sendOtp(String phoneNumber) async {
    try {
      final completer = Completer<void>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await _firebaseAuth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await completer.future;
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send OTP (${e.code})';
    } catch (e) {
      return 'Failed to send OTP: $e';
    }
  }

  @override
  Future<String?> verifyOtp(String verificationId, String code) async {
    final resolvedVerificationId =
        (_verificationId != null && _verificationId!.isNotEmpty)
            ? _verificationId!
            : (verificationId.startsWith('+') ? '' : verificationId);

    if (resolvedVerificationId.isEmpty) {
      return 'Verification ID is missing. Please request a new OTP.';
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: resolvedVerificationId,
        smsCode: code.trim(),
      );
      await _firebaseAuth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to verify OTP (${e.code})';
    } catch (e) {
      return 'Failed to verify OTP: $e';
    }
  }

  @override
  Future<String?> signUpWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return 'Google sign-in was cancelled.';
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to sign in with Google (${e.code})';
    } catch (e) {
      return 'Failed to sign in with Google: $e';
    }
  }

  @override
  Future<String?> submitJoinRequest(JoinRequestInput request) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return 'You must be signed in to submit a join request.';
    }

    try {
      String? photoUrl = request.existingPhotoUrl ?? user.photoURL;
      if (request.profilePhotoBytes != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pictures')
              .child('${user.uid}.jpg');
          await storageRef.putData(
            request.profilePhotoBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          photoUrl = await storageRef.getDownloadURL();
        } catch (_) {
          // Fallback to base64 data URI when Firebase Storage is not enabled
          photoUrl =
              'data:image/jpeg;base64,${base64Encode(request.profilePhotoBytes!)}';
        }
      }

      final nowIso = DateTime.now().toUtc().toIso8601String();
      final docRef = _db.collection('users').doc(user.uid);
      final existingSnap = await docRef.get();
      final existingData = existingSnap.data();

      final payload = <String, dynamic>{
        'userId': user.uid,
        'email': user.email ?? '',
        'phone': request.mobileNumber.trim(),
        'firstName': request.firstName.trim(),
        'lastName': request.lastName.trim(),
        'name': request.fullName,
        'dateOfBirth': request.dateOfBirth.toIso8601String(),
        'gender': request.gender.trim(),
        'stateBarAssociation': request.stateBarAssociation.trim(),
        'enrollmentNumber': request.enrollmentNumber.trim(),
        'barAdmissions': [
          {
            'jurisdiction': request.stateBarAssociation.trim(),
            'barNumber': request.enrollmentNumber.trim(),
            'yearAdmitted': DateTime.now().year,
          },
        ],
        'photoUrl': photoUrl ?? '',
        'rejectionReason': null,
        'status': UserStatus.pending.value,
        'role': (existingData?['role'] as String?) ?? UserRole.member.value,
        'createdAt': (existingData?['createdAt'] as String?) ?? nowIso,
        'updatedAt': nowIso,
      };

      if (existingSnap.exists) {
        await docRef.update(payload);
      } else {
        await docRef.set(payload);
      }

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to submit join request (${e.code})';
    } catch (e) {
      return 'Failed to submit join request: $e';
    }
  }

  @override
  Future<List<AuthUser>> getPendingJoinRequests() async {
    try {
      final query = await _db
          .collection('users')
          .where('status', isEqualTo: UserStatus.pending.value)
          .get();

      final list = query.docs
          .map((doc) => _mapFirestoreDoc(doc.id, doc.data()))
          .where((u) => u.hasSubmittedJoinRequest)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<String?> reviewJoinRequest({
    required String targetUserId,
    required bool approve,
    String? rejectionReason,
  }) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _db.collection('users').doc(targetUserId).update({
        'status': approve
            ? UserStatus.approved.value
            : UserStatus.rejected.value,
        'rejectionReason': approve ? null : rejectionReason?.trim(),
        'updatedAt': nowIso,
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to update join request (${e.code})';
    } catch (e) {
      return 'Failed to update join request: $e';
    }
  }

  @override
  Future<List<AuthUser>> getAllMembers() async {
    try {
      final query = await _db.collection('users').get();
      return query.docs
          .map((doc) => _mapFirestoreDoc(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<String?> updateUserRole({
    required String targetUserId,
    required UserRole newRole,
  }) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _db.collection('users').doc(targetUserId).update({
        'role': newRole.value,
        'status': UserStatus.approved.value,
        'updatedAt': nowIso,
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to update role (${e.code})';
    } catch (e) {
      return 'Failed to update role: $e';
    }
  }

  @override
  Future<String?> setDefaultAdminByEmail(
    String email, {
    UserRole role = UserRole.foundingAdmin,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return updateUserRole(
          targetUserId: query.docs.first.id,
          newRole: role,
        );
      }
      return 'No member found registered with email $cleanEmail';
    } catch (e) {
      return 'Failed to appoint default admin: $e';
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) => null);
    await _firebaseAuth.signOut();
  }
}
