import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  const SessionStorage._();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> writeSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return json;
      return null;
    } catch (_) {
      // Crash-safe fallback for corrupt cached session payloads.
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
