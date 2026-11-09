import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_user.dart';

/// Local device persistence storage for maintaining logged-in user state
/// across app relaunches, backgrounding, and offline states until the user
/// explicitly logs out.
class LocalAuthStorage {
  static const String _keyAuthUser = 'legal_unity_cached_auth_user';

  final SharedPreferences? _prefs;

  LocalAuthStorage([this._prefs]);

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      return await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {
      return null;
    }
  }

  /// Saves the authenticated user's session profile to local device storage.
  Future<void> saveUser(AuthUser user) async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final jsonStr = jsonEncode(user.toJson());
        await prefs.setString(_keyAuthUser, jsonStr);
      }
    } catch (_) {}
  }

  /// Retrieves the persisted user session profile, or null if unauthenticated.
  Future<AuthUser?> getUser() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final jsonStr = prefs.getString(_keyAuthUser);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          return AuthUser.fromJson(map);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Explicitly clears the persisted user session profile on logout.
  Future<void> clear() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        await prefs.remove(_keyAuthUser);
      }
    } catch (_) {}
  }
}
