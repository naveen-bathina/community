import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/wall_datasource.dart';
import '../../domain/repositories/wall_repository.dart';

final wallRepositoryProvider = Provider<WallRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    try {
      return SupabaseWallRepository();
    } catch (_) {}
  }
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseWallRepository();
    }
  } catch (_) {}
  return InMemoryWallRepository();
});
