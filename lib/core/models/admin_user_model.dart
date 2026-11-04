import 'package:equatable/equatable.dart';

import '../storage/hive_storage.dart';

/// Scope definition for an admin user containing geography and site allocations.
class AdminUserScopeModel extends Equatable {
  final List<String> siteIds;
  final List<String> zoneIds;
  final List<String> groupIds;
  final List<String> clusterIds;

  const AdminUserScopeModel({
    this.siteIds = const [],
    this.zoneIds = const [],
    this.groupIds = const [],
    this.clusterIds = const [],
  });

  factory AdminUserScopeModel.fromJson(Map<String, dynamic> json) {
    return AdminUserScopeModel(
      siteIds: _parseStringList(json['siteIds']),
      zoneIds: _parseStringList(json['zoneIds']),
      groupIds: _parseStringList(json['groupIds']),
      clusterIds: _parseStringList(json['clusterIds']),
    );
  }

  static List<String> _parseStringList(dynamic list) {
    if (list is List) {
      return list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'siteIds': siteIds,
      'zoneIds': zoneIds,
      'groupIds': groupIds,
      'clusterIds': clusterIds,
    };
  }

  AdminUserScopeModel copyWith({
    List<String>? siteIds,
    List<String>? zoneIds,
    List<String>? groupIds,
    List<String>? clusterIds,
  }) {
    return AdminUserScopeModel(
      siteIds: siteIds ?? this.siteIds,
      zoneIds: zoneIds ?? this.zoneIds,
      groupIds: groupIds ?? this.groupIds,
      clusterIds: clusterIds ?? this.clusterIds,
    );
  }

  bool get isEmpty =>
      siteIds.isEmpty && zoneIds.isEmpty && groupIds.isEmpty && clusterIds.isEmpty;

  bool get isGlobal => isEmpty;

  @override
  List<Object?> get props => [siteIds, zoneIds, groupIds, clusterIds];
}

/// Represents an administrative/governance user from GET /api/admin/users
class AdminUserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final AdminUserScopeModel scope;
  final bool active;
  final bool mustChangePassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.scope = const AdminUserScopeModel(),
    this.active = true,
    this.mustChangePassword = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      scope: json['scope'] is Map<String, dynamic>
          ? AdminUserScopeModel.fromJson(json['scope'] as Map<String, dynamic>)
          : json['scope'] is Map
              ? AdminUserScopeModel.fromJson(Map<String, dynamic>.from(json['scope'] as Map))
              : const AdminUserScopeModel(),
      active: json['active'] as bool? ?? true,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'scope': scope.toJson(),
      'active': active,
      'mustChangePassword': mustChangePassword,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Formatted role string: e.g. "CLUSTER_LEAD" -> "Cluster Lead", "CRRM" -> "CRRM / Super Admin"
  String get roleLabel {
    if (role.isEmpty) return '';
    final upper = role.trim().toUpperCase();
    if (HiveStorage.knownRoles.containsKey(upper)) {
      return HiveStorage.knownRoles[upper]!;
    }
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  /// Department derived from role
  String get department {
    final upper = role.toUpperCase();
    if (upper.contains('L&D') ||
        upper.startsWith('LD_') ||
        upper.startsWith('L_D_') ||
        upper.endsWith('_LD') ||
        upper == 'LD' ||
        upper.contains('TRANSITION') ||
        upper.contains('TRAIN')) {
      return 'L&D';
    }
    if (upper == 'HR') return 'HR';
    if (upper == 'EHS') return 'EHS';
    if (upper == 'SALES') return 'Sales';
    if (upper == 'CRRM' || upper.contains('ADMIN')) return 'CRRM';
    if (upper == 'MACHINE_TECHNICIAN') return 'Machine';
    return 'Operations';
  }

  bool get isLdDepartment {
    final upper = role.toUpperCase();
    return upper.contains('L&D') ||
        upper.startsWith('LD_') ||
        upper.startsWith('L_D_') ||
        upper.endsWith('_LD') ||
        upper == 'LD' ||
        upper.contains('TRANSITION') ||
        upper.contains('TRAIN');
  }

  /// Formatted display: "Abhimanyu · Cluster Lead"
  String get displayWithRole {
    final formatted = roleLabel;
    if (formatted.isEmpty) return name;
    return '$name · $formatted';
  }

  /// Initials e.g. "Abhimanyu" -> "A" or "Abhimanyu Patel" -> "AP"
  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Check if user has access to a specific site
  bool hasSiteAccess(String siteId) {
    if (scope.isGlobal) return true;
    return scope.siteIds.contains(siteId);
  }

  /// Check if user has access to a specific zone
  bool hasZoneAccess(String zoneId) {
    if (scope.isGlobal) return true;
    return scope.zoneIds.contains(zoneId);
  }

  /// Check if user has access to a specific cluster
  bool hasClusterAccess(String clusterId) {
    if (scope.isGlobal) return true;
    return scope.clusterIds.contains(clusterId);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        scope,
        active,
        mustChangePassword,
        createdAt,
        updatedAt,
      ];
}

/// Paginated response from GET /api/admin/users
class AdminUsersResponseModel extends Equatable {
  final List<AdminUserModel> items;
  final int total;

  const AdminUsersResponseModel({
    this.items = const [],
    this.total = 0,
  });

  factory AdminUsersResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = <AdminUserModel>[];
    for (final it in rawItems) {
      if (it is Map) {
        itemsList.add(AdminUserModel.fromJson(Map<String, dynamic>.from(it)));
      }
    }

    return AdminUsersResponseModel(
      items: itemsList,
      total: (json['total'] as num?)?.toInt() ?? itemsList.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }

  @override
  List<Object?> get props => [items, total];
}

