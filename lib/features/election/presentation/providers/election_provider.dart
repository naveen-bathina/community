import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/election_datasource.dart';
import '../../domain/repositories/election_repository.dart';

final electionRepositoryProvider = Provider<ElectionRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    try {
      return SupabaseElectionRepository();
    } catch (_) {}
  }
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseElectionRepository();
    }
  } catch (_) {}
  return InMemoryElectionRepository();
});
