import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../models/admin_user_model.dart';
import '../network/dio_client.dart';

/// Singleton service responsible for fetching, caching, and querying Admin Users
/// from `GET /api/admin/users?limit=500&offset=0`.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  Dio? _injectedDio;

  /// Visible for testing to inject mock Dio
  void setMockDio(Dio dio) {
    _injectedDio = dio;
  }

  void resetMockDio() {
    _injectedDio = null;
  }

  Dio get _dio => _injectedDio ?? DioClient.instance;

  List<AdminUserModel> _cachedUsers = const [];
  int _cachedTotal = 0;
  bool _isLoaded = false;
  bool _isLoading = false;

  List<AdminUserModel> get users => _cachedUsers;
  int get total => _cachedTotal;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  /// Fetches admin users from `GET /api/admin/users`.
  /// By default requests limit=500 and offset=0.
  Future<AdminUsersResponseModel> getAdminUsers({
    int limit = 500,
    int offset = 0,
    String? role,
    String? search,
    bool? active,
    bool forceRefresh = false,
  }) async {
    if (_isLoaded && !forceRefresh && _cachedUsers.isNotEmpty && offset == 0 && role == null && search == null && active == null) {
      return AdminUsersResponseModel(items: _cachedUsers, total: _cachedTotal);
    }

    if (_isLoading && !forceRefresh) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return AdminUsersResponseModel(items: _cachedUsers, total: _cachedTotal);
    }

    _isLoading = true;
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (role != null && role.isNotEmpty) queryParams['role'] = role;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (active != null) queryParams['active'] = active;

      developer.log('🌐 Fetching Admin Users: /admin/users $queryParams', name: 'UserService');
      final response = await _dio.get('/admin/users', queryParameters: queryParams);

      Map<String, dynamic>? dataMap;
      if (response.data is Map) {
        dataMap = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) {
          dataMap = Map<String, dynamic>.from(decoded);
        }
      }

      final parsed = dataMap != null
          ? AdminUsersResponseModel.fromJson(dataMap)
          : const AdminUsersResponseModel();

      if (offset == 0 && (role == null || role.isEmpty) && (search == null || search.isEmpty)) {
        _cachedUsers = parsed.items;
        _cachedTotal = parsed.total;
        _isLoaded = true;
      }

      developer.log(
        '✅ Admin Users loaded: ${parsed.items.length} items (total: ${parsed.total})',
        name: 'UserService',
      );
      return parsed;
    } catch (e, stack) {
      developer.log('❌ Error fetching admin users: $e', error: e, stackTrace: stack, name: 'UserService');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Synchronous lookup by user ID from cached users
  AdminUserModel? getUserById(String id) {
    if (id.isEmpty) return null;
    return _cachedUsers.where((u) => u.id == id).firstOrNull;
  }

  /// Returns user's display name or fallback
  String getUserName(String id, {String fallback = 'Admin'}) {
    final user = getUserById(id);
    return user?.name ?? fallback;
  }

  /// Filters cached users by role (case-insensitive)
  List<AdminUserModel> getUsersByRole(String role) {
    final lowerRole = role.toLowerCase();
    return _cachedUsers.where((u) => u.role.toLowerCase() == lowerRole).toList();
  }

  /// Filters cached users that have access to the given zone
  List<AdminUserModel> getUsersByZone(String zoneId) {
    return _cachedUsers.where((u) => u.hasZoneAccess(zoneId)).toList();
  }

  /// Filters cached users that have access to the given cluster
  List<AdminUserModel> getUsersByCluster(String clusterId) {
    return _cachedUsers.where((u) => u.hasClusterAccess(clusterId)).toList();
  }

  /// Filters cached users that have access to the given site
  List<AdminUserModel> getUsersBySite(String siteId) {
    return _cachedUsers.where((u) => u.hasSiteAccess(siteId)).toList();
  }

  /// Free-text search by name or email
  List<AdminUserModel> searchUsers(String query) {
    if (query.trim().isEmpty) return _cachedUsers;
    final q = query.trim().toLowerCase();
    return _cachedUsers
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q))
        .toList();
  }
}

