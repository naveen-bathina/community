import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_unity_network/features/profile/domain/repositories/profile_repository.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirestoreProfileDataSource implements ProfileRepository {
  final FirebaseFirestore _db;

  FirestoreProfileDataSource([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  UserModel _docToModel(String id, Map<String, dynamic> data) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final normalized = <String, dynamic>{
      ...data,
      'userId': (data['userId'] as String?) ?? id,
      'email': (data['email'] as String?) ?? '',
      'name': (data['name'] as String?) ??
          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
      'status': (data['status'] as String?) ?? UserStatus.approved.value,
      'role': (data['role'] as String?) ?? UserRole.member.value,
      'createdAt': (data['createdAt'] as String?) ?? nowIso,
      'updatedAt': (data['updatedAt'] as String?) ?? nowIso,
    };
    return UserModel.fromJson(normalized);
  }

  @override
  Future<List<UserModel>> getApprovedMembers({
    String? searchQuery,
    String? practiceArea,
    AvailabilityStatus? availability,
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .where('status', isEqualTo: UserStatus.approved.value)
          .get();

      final all = snap.docs.map((d) => _docToModel(d.id, d.data())).toList();
      return _filterMembers(
        all,
        searchQuery: searchQuery,
        practiceArea: practiceArea,
        availability: availability,
      );
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<UserModel?> getProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return _docToModel(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> updateProfile(UserModel updatedProfile) async {
    try {
      await _db.collection('users').doc(updatedProfile.userId).set(
            updatedProfile.toJson(),
            SetOptions(merge: true),
          );
      return null;
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }
}

class SupabaseProfileDataSource implements ProfileRepository {
  final SupabaseClient _supabase;

  SupabaseProfileDataSource(this._supabase);

  UserModel _rowToModel(Map<String, dynamic> row) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final json = <String, dynamic>{
      'userId': row['id'] as String,
      'email': (row['email'] as String?) ?? '',
      'phone': row['phone'] as String?,
      'name': (row['name'] as String?) ??
          '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim(),
      'photoUrl': row['photo_url'] as String?,
      'status': (row['status'] as String?) ?? UserStatus.approved.value,
      'role': (row['role'] as String?) ?? UserRole.member.value,
      'lawSchool': row['law_school'] as String?,
      'practiceAreas': row['practice_areas'],
      'firmOrganization': row['firm_organization'] as String?,
      'yearsOfExperience': row['years_of_experience'] as int?,
      'city': row['city'] as String?,
      'state': row['state'] as String?,
      'bio': row['bio'] as String?,
      'availabilityStatus': row['availability_status'] as String?,
      'achievements': row['achievements'] as String?,
      'cles': row['cles'] as String?,
      'publications': row['publications'] as String?,
      'createdAt': (row['created_at'] as String?) ?? nowIso,
      'updatedAt': (row['updated_at'] as String?) ?? nowIso,
    };
    return UserModel.fromJson(json);
  }

  @override
  Future<List<UserModel>> getApprovedMembers({
    String? searchQuery,
    String? practiceArea,
    AvailabilityStatus? availability,
  }) async {
    try {
      final rows = await _supabase
          .from('profiles')
          .select()
          .eq('status', UserStatus.approved.value);
      final all = (rows as List<dynamic>)
          .map((e) => _rowToModel(e as Map<String, dynamic>))
          .toList();
      return _filterMembers(
        all,
        searchQuery: searchQuery,
        practiceArea: practiceArea,
        availability: availability,
      );
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<UserModel?> getProfile(String userId) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return _rowToModel(row);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> updateProfile(UserModel updatedProfile) async {
    try {
      await _supabase.from('profiles').update({
        'name': updatedProfile.name,
        'phone': updatedProfile.phone,
        'photo_url': updatedProfile.photoUrl,
        'bar_admissions':
            updatedProfile.barAdmissions?.map((b) => b.toJson()).toList() ??
                const <Map<String, dynamic>>[],
        'law_school': updatedProfile.lawSchool,
        'practice_areas': updatedProfile.practiceAreas ?? const <String>[],
        'firm_organization': updatedProfile.firmOrganization,
        'years_of_experience': updatedProfile.yearsOfExperience,
        'city': updatedProfile.city,
        'state': updatedProfile.state,
        'bio': updatedProfile.bio,
        'availability_status': updatedProfile.availabilityStatus?.value,
        'achievements': updatedProfile.achievements,
        'cles': updatedProfile.cles,
        'publications': updatedProfile.publications,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', updatedProfile.userId);
      return null;
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }
}

class EmptyProfileDataSource implements ProfileRepository {
  @override
  Future<List<UserModel>> getApprovedMembers({
    String? searchQuery,
    String? practiceArea,
    AvailabilityStatus? availability,
  }) async =>
      const [];

  @override
  Future<UserModel?> getProfile(String userId) async => null;

  @override
  Future<String?> updateProfile(UserModel updatedProfile) async => null;
}

List<UserModel> _filterMembers(
  List<UserModel> members, {
  String? searchQuery,
  String? practiceArea,
  AvailabilityStatus? availability,
}) {
  return members.where((m) {
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      final matchesName = m.name.toLowerCase().contains(q);
      final matchesCity = (m.city ?? '').toLowerCase().contains(q);
      final matchesState = (m.state ?? '').toLowerCase().contains(q);
      final matchesFirm = (m.firmOrganization ?? '').toLowerCase().contains(q);
      if (!matchesName && !matchesCity && !matchesState && !matchesFirm) {
        return false;
      }
    }
    if (practiceArea != null && practiceArea.isNotEmpty) {
      if (!(m.practiceAreas ?? const []).contains(practiceArea)) {
        return false;
      }
    }
    if (availability != null && m.availabilityStatus != availability) {
      return false;
    }
    return true;
  }).toList();
}
