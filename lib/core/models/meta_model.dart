import '../storage/hive_storage.dart';

/// Model for a unit in metadata (ZONE or CLUSTER)
class MetaUnitModel {
  final String id;
  final String name;
  final String code;
  final String kind; // 'ZONE' or 'CLUSTER'
  final String? parentId;
  final String? zoneId;
  final bool active;

  const MetaUnitModel({
    required this.id,
    required this.name,
    required this.code,
    required this.kind,
    this.parentId,
    this.zoneId,
    this.active = true,
  });

  factory MetaUnitModel.fromJson(Map<String, dynamic> json) {
    return MetaUnitModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'ZONE',
      parentId: json['parentId']?.toString(),
      zoneId: json['zoneId']?.toString() ?? json['parentId']?.toString(),
      active: json['active'] as bool? ?? true,
    );
  }

  bool get isZone => kind == 'ZONE';
  bool get isCluster => kind == 'CLUSTER';
}

/// Model for a user in metadata
class MetaUserModel {
  final String id;
  final String name;
  final String role;
  final String email;

  const MetaUserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
  });

  factory MetaUserModel.fromJson(Map<String, dynamic> json) {
    return MetaUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
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

  /// Displays "PropCare Administrator · CRRM / Super Admin" or "Arun Kumar · Cluster Executive"
  String get displayWithRole {
    final upper = role.trim().toUpperCase();
    final formattedRole = HiveStorage.knownRoles[upper] ??
        role
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
                : '')
            .join(' ');
    return '$name · $formattedRole';
  }
}

/// Model for a site in metadata
class MetaSiteModel {
  final String id;
  final String name;
  final String? code;
  final String? zoneId;
  final String? zoneName;
  final String? clusterId;
  final String? clusterName;
  final String status;

  const MetaSiteModel({
    required this.id,
    required this.name,
    this.code,
    this.zoneId,
    this.zoneName,
    this.clusterId,
    this.clusterName,
    this.status = 'LIVE',
  });

  factory MetaSiteModel.fromJson(Map<String, dynamic> json) {
    return MetaSiteModel(
      id: json['id']?.toString() ?? json['siteId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['siteName']?.toString() ?? '',
      code: json['code']?.toString() ?? json['siteCode']?.toString(),
      zoneId: json['zoneId']?.toString(),
      zoneName: json['zoneName']?.toString(),
      clusterId: json['clusterId']?.toString() ?? json['groupId']?.toString(),
      clusterName: json['clusterName']?.toString(),
      status: json['status']?.toString() ?? json['siteStatus']?.toString() ?? 'LIVE',
    );
  }

  bool get isLive => status.toUpperCase() == 'LIVE';

  String get displayName => code != null && code!.isNotEmpty ? '$name ($code)' : name;
}

/// Root metadata container for /api/meta
class MetaDataModel {
  final Map<String, String> roles;
  final List<MetaUnitModel> units;
  final List<MetaUserModel> users;
  final List<MetaSiteModel> sites;

  const MetaDataModel({
    this.roles = const {},
    this.units = const [],
    this.users = const [],
    this.sites = const [],
  });

  factory MetaDataModel.fromJson(Map<String, dynamic> json) {
    // Roles
    final rolesMap = <String, String>{};
    if (json['roles'] is Map) {
      (json['roles'] as Map).forEach((k, v) {
        rolesMap[k.toString()] = v.toString();
      });
    }

    // Units
    final rawUnits = json['units'] as List<dynamic>? ?? [];
    final unitsList = <MetaUnitModel>[];
    for (final u in rawUnits) {
      if (u is Map) {
        unitsList.add(MetaUnitModel.fromJson(Map<String, dynamic>.from(u)));
      }
    }

    // Users
    final rawUsers = json['users'] as List<dynamic>? ?? [];
    final usersList = <MetaUserModel>[];
    for (final user in rawUsers) {
      if (user is Map) {
        usersList.add(MetaUserModel.fromJson(Map<String, dynamic>.from(user)));
      }
    }

    // Sites
    final rawSites = json['sites'] as List<dynamic>? ?? [];
    final sitesList = <MetaSiteModel>[];
    for (final s in rawSites) {
      if (s is Map) {
        sitesList.add(MetaSiteModel.fromJson(Map<String, dynamic>.from(s)));
      }
    }

    return MetaDataModel(
      roles: rolesMap,
      units: unitsList,
      users: usersList,
      sites: sitesList,
    );
  }

  static const empty = MetaDataModel();

  // Helper getters
  List<MetaUnitModel> get zones => units.where((u) => u.isZone).toList();
  List<MetaUnitModel> get clusters => units.where((u) => u.isCluster).toList();

  /// Live sites only (status == 'LIVE')
  List<MetaSiteModel> get liveSites => sites.where((s) => s.isLive).toList();

  List<MetaUnitModel> clustersForZone(String? zoneId) {
    if (zoneId == null || zoneId.isEmpty) return clusters;
    return clusters.where((c) => c.zoneId == zoneId || c.parentId == zoneId).toList();
  }

  List<MetaSiteModel> sitesForZone(String? zoneId) {
    final list = liveSites;
    if (zoneId == null || zoneId.isEmpty) return list;
    return list.where((s) => s.zoneId == zoneId).toList();
  }

  List<MetaSiteModel> sitesForCluster(String? clusterId) {
    final list = liveSites;
    if (clusterId == null || clusterId.isEmpty) return list;
    return list.where((s) => s.clusterId == clusterId).toList();
  }

  String getSiteName(String siteId) {
    final match = sites.where((s) => s.id == siteId).firstOrNull;
    return match?.name ?? 'Site';
  }

  String getUserName(String userId) {
    final match = users.where((u) => u.id == userId).firstOrNull;
    return match?.name ?? 'Admin';
  }

  String getZoneName(String? zoneId) {
    if (zoneId == null) return '—';
    final match = zones.where((z) => z.id == zoneId).firstOrNull;
    return match?.name ?? '—';
  }

  String getClusterName(String? clusterId) {
    if (clusterId == null) return '—';
    final match = clusters.where((c) => c.id == clusterId).firstOrNull;
    return match?.name ?? '—';
  }

  MetaDataModel mergeSites(List<MetaSiteModel> additionalSites) {
    final existingIds = sites.map((s) => s.id).toSet();
    final merged = List<MetaSiteModel>.from(sites);
    for (final s in additionalSites) {
      if (!existingIds.contains(s.id)) {
        merged.add(s);
        existingIds.add(s.id);
      }
    }
    return MetaDataModel(
      roles: roles,
      units: units,
      users: users,
      sites: merged,
    );
  }
}

