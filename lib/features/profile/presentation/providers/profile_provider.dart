import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/config/supabase_config.dart';
import 'package:legal_unity_network/features/profile/data/datasources/profile_datasource.dart';
import 'package:legal_unity_network/features/profile/domain/repositories/profile_repository.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return SupabaseProfileDataSource(SupabaseConfig.client);
  }
  if (Firebase.apps.isNotEmpty) {
    return FirestoreProfileDataSource();
  }
  return EmptyProfileDataSource();
});

class DirectoryFilter {
  final String searchQuery;
  final String? practiceArea;
  final AvailabilityStatus? availability;

  const DirectoryFilter({
    this.searchQuery = '',
    this.practiceArea,
    this.availability,
  });

  DirectoryFilter copyWith({
    String? searchQuery,
    String? practiceArea,
    bool clearPracticeArea = false,
    AvailabilityStatus? availability,
    bool clearAvailability = false,
  }) {
    return DirectoryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      practiceArea:
          clearPracticeArea ? null : (practiceArea ?? this.practiceArea),
      availability:
          clearAvailability ? null : (availability ?? this.availability),
    );
  }
}

final directoryFilterProvider = StateProvider<DirectoryFilter>((ref) {
  return const DirectoryFilter();
});

final directoryMembersProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final filter = ref.watch(directoryFilterProvider);
  return repo.getApprovedMembers(
    searchQuery: filter.searchQuery,
    practiceArea: filter.practiceArea,
    availability: filter.availability,
  );
});
