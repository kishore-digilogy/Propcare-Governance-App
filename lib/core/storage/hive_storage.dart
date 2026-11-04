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

  static T? get<T>(String key) {
    try {
      return _box.get(key) as T?;
    } catch (_) {
      return null;
    }
  }

  static String? getString(String key) {
    try {
      return _box.get(key) as String?;
    } catch (_) {
      return null;
    }
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _box.get(key, defaultValue: defaultValue) as bool;
    } catch (_) {
      return defaultValue;
    }
  }

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
  static String? _mockUserRole;
  static set mockUserRole(String? role) => _mockUserRole = role;

  static String? get userEmail => getString(StorageKeys.userEmail);
  static String? get userName => getString(StorageKeys.userName);
  static String? get userRole {
    if (_mockUserRole != null) return _mockUserRole;
    final r = getString(StorageKeys.userRole);
    if (r != null && r.trim().isNotEmpty) return r;
    final profile = userProfile;
    if (profile != null) {
      final pr = profile['role'] ?? profile['roleLabel'] ?? profile['userRole'];
      if (pr != null && pr.toString().trim().isNotEmpty) return pr.toString();
    }
    return null;
  }

  /// Known roles map matching backend role definitions
  static const Map<String, String> knownRoles = {
    'CRRM': 'CRRM / Super Admin',
    'SUPER_ADMIN': 'CRRM / Super Admin',
    'SUPERADMIN': 'CRRM / Super Admin',
    'ADMIN': 'CRRM / Super Admin',
    'CEO': 'CEO',
    'COO': 'COO',
    'OPERATIONS_HEAD': 'Operations Head',
    'ZONAL_HEAD': 'Zonal Head',
    'GROUP_CLUSTER_HEAD': 'Group Cluster Head',
    'CLUSTER_HEAD': 'Cluster Head',
    'CLUSTER_LEAD': 'Cluster Lead',
    'CLUSTER_EXECUTIVE': 'Cluster Executive',
    'FIELD_EXECUTIVE': 'Field Executive',
    'LD': 'Transition',
    'LD_HEAD': 'L&D Head',
    'LD_LEAD': 'L&D Lead',
    'LD_TRAINER': 'L&D Trainer',
    'L_D_ASSIT_MANAGER': 'L&D-Assit-Manager',
    'L_D_DEPUTY_MANAGER': 'L&D-Deputy-manager',
    'L_D_EXECUTIVE': 'L&D-Executive',
    'L_D_SR_EXECUTIVE': 'L&D-Sr.Executive',
    'HR': 'HR',
    'EHS': 'EHS',
    'MACHINE_TECHNICIAN': 'Machine Technician',
    'SALES': 'Sales',
  };

  /// Display role string for the logged-in user.
  /// CRRM is treated with full Super Admin parity across PropCare Governance.
  static String get displayRole {
    final raw = userRole;
    if (raw == null || raw.trim().isEmpty) return 'CRRM / Super Admin';
    final upper = raw.trim().toUpperCase();
    if (knownRoles.containsKey(upper)) {
      return knownRoles[upper]!;
    }
    if (upper == 'CRRM' ||
        upper == 'SUPER_ADMIN' ||
        upper == 'SUPERADMIN' ||
        upper == 'ADMIN' ||
        upper == 'CRRM / SUPER ADMIN' ||
        upper == 'CRRM/SUPER ADMIN') {
      return 'CRRM / Super Admin';
    }
    if (isLdRole) {
      if (upper == 'LD_HEAD' || upper == 'LD HEAD' || upper == 'L&D_HEAD' || upper == 'L&D HEAD') {
        return 'L&D Head';
      }
      if (upper == 'LD_LEAD' || upper == 'LD LEAD' || upper == 'L&D_LEAD' || upper == 'L&D LEAD') {
        return 'L&D Lead';
      }
      return 'L&D';
    }
    return raw;
  }

  /// Whether the logged-in user has an L&D (Learning & Development) role.
  /// (e.g. LD, LD_HEAD, LD_LEAD, LD_TRAINER, L_D_ASSIT_MANAGER, etc.).
  static bool get isLdRole {
    final raw = userRole;
    if (raw == null || raw.trim().isEmpty) return false;
    final upper = raw.trim().toUpperCase();
    return upper.startsWith('LD') ||
        upper.startsWith('L_D') ||
        upper.startsWith('L&D') ||
        upper.contains('L&D') ||
        upper.contains('TRANSITION') ||
        upper.contains(RegExp(r'(^|[_\s\W])(LD|L_D|L&D)([_\s\W]|$)'));
  }

  /// Whether the logged-in user specifically has an L&D Head role (or Super Admin).
  static bool get isLdHead {
    final raw = userRole;
    if (raw == null || raw.trim().isEmpty) return false;
    final upper = raw.trim().toUpperCase();
    if (isSuperAdmin) return true;
    return upper == 'LD_HEAD' ||
        upper == 'L&D_HEAD' ||
        upper == 'L&D HEAD' ||
        upper.contains('LD_HEAD') ||
        (isLdRole && upper.contains('HEAD'));
  }

  /// Whether the logged-in user specifically has a Cluster Lead role.
  static bool get isClusterLead {
    final raw = userRole;
    if (raw == null || raw.trim().isEmpty) return false;
    final upper = raw.trim().toUpperCase();
    return upper == 'CLUSTER_LEAD' ||
        upper == 'CLUSTER LEAD' ||
        upper.contains('CLUSTER_LEAD') ||
        upper.contains('CLUSTER LEAD');
  }

  /// Whether the current logged-in user is a Super Admin / CRRM.
  /// CRRM has equal rights and full access as Super Admin.
  static bool get isSuperAdmin {
    final raw = userRole;
    if (raw == null || raw.trim().isEmpty) return true;
    final upper = raw.trim().toUpperCase();
    return upper == 'CRRM' ||
        upper == 'SUPER_ADMIN' ||
        upper == 'SUPERADMIN' ||
        upper == 'ADMIN' ||
        upper.contains('CRRM') ||
        upper.contains('SUPER');
  }

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
    final r = userMap['role'] ?? userMap['roleLabel'] ?? userMap['userRole'];
    if (r != null) {
      await put(StorageKeys.userRole, r.toString());
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
