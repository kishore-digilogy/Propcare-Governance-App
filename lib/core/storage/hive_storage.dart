import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import 'storage_keys.dart';

/// Hive-backed local storage wrapper for PropCare Governance.
///
/// Call [HiveStorage.init] once before [runApp].
class HiveStorage {
  HiveStorage._();

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(StorageKeys.appBox);
  }

  // ── Generic Getters & Setters ──────────────────────────────────────────────

  static T? get<T>(String key) => _box.get(key) as T?;

  static String? getString(String key) => _box.get(key) as String?;

  static bool getBool(String key, {bool defaultValue = false}) =>
      _box.get(key, defaultValue: defaultValue) as bool;

  static Future<void> put(String key, dynamic value) => _box.put(key, value);

  static Future<void> delete(String key) => _box.delete(key);

  static Future<void> clear() => _box.clear();

  // ── Session Cookie & CSRF Token ────────────────────────────────────────────

  /// The active session cookie value, e.g. `ppATEZ1y2vkeGahXkg...`
  static String? get sessionCookie => getString(StorageKeys.sessionCookie);

  static Future<void> saveSessionCookie(String cookie) =>
      put(StorageKeys.sessionCookie, cookie);

  /// The CSRF token used for mutating requests (POST, PUT, DELETE, PATCH).
  static String? get csrfToken => getString(StorageKeys.csrfToken);

  static Future<void> saveCsrfToken(String token) =>
      put(StorageKeys.csrfToken, token);

  // ── Auth Token ─────────────────────────────────────────────────────────────

  static String? get authToken => getString(StorageKeys.authToken);

  static Future<void> saveAuthToken(String token) =>
      put(StorageKeys.authToken, token);

  static Future<void> deleteAuthToken() => delete(StorageKeys.authToken);

  /// Check whether user has an active session.
  static bool get isLoggedIn {
    final cookie = sessionCookie;
    final token = authToken;
    return (cookie != null && cookie.isNotEmpty) ||
        (token != null && token.isNotEmpty);
  }

  // ── User Profile & Details ─────────────────────────────────────────────────

  static String? get userId => getString(StorageKeys.userId);
  static String? get userEmail => getString(StorageKeys.userEmail);
  static String? get userName => getString(StorageKeys.userName);
  static String? get userRole => getString(StorageKeys.userRole);

  static Map<String, dynamic>? get userProfile {
    final raw = getString(StorageKeys.userProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUserProfile(Map<String, dynamic> userMap) async {
    await put(StorageKeys.userProfile, jsonEncode(userMap));
    if (userMap['id'] != null) {
      await put(StorageKeys.userId, userMap['id'].toString());
    }
    if (userMap['email'] != null) {
      await put(StorageKeys.userEmail, userMap['email'].toString());
    }
    if (userMap['name'] != null) {
      await put(StorageKeys.userName, userMap['name'].toString());
    }
    if (userMap['role'] != null) {
      await put(StorageKeys.userRole, userMap['role'].toString());
    }
  }

  /// Clears all credentials and session state on logout.
  static Future<void> clearAuth() async {
    await delete(StorageKeys.authToken);
    await delete(StorageKeys.sessionCookie);
    await delete(StorageKeys.csrfToken);
    await delete(StorageKeys.userProfile);
    await delete(StorageKeys.userId);
    await delete(StorageKeys.userEmail);
    await delete(StorageKeys.userName);
    await delete(StorageKeys.userRole);
  }

  // ── App State Flags ────────────────────────────────────────────────────────

  static bool get isOnboardingSeen =>
      getBool(StorageKeys.isOnboardingSeen);

  static Future<void> markOnboardingSeen() =>
      put(StorageKeys.isOnboardingSeen, true);

  // ── Recent Emails (Max 5, Unique) ──────────────────────────────────────────

  static List<String> get recentEmails {
    final raw = _box.get(StorageKeys.recentEmails);
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  static Future<void> saveRecentEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) return;

    final current = recentEmails;
    // Remove duplicate case-insensitively
    current.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    // Prepend the latest email
    current.insert(0, trimmed);
    // Keep max 5
    final updated = current.take(5).toList();
    await put(StorageKeys.recentEmails, updated);
  }

  static Future<void> removeRecentEmail(String email) async {
    final current = recentEmails;
    current.removeWhere((e) => e.toLowerCase() == email.trim().toLowerCase());
    await put(StorageKeys.recentEmails, current);
  }

  static Future<void> clearRecentEmails() async {
    await delete(StorageKeys.recentEmails);
  }
}
