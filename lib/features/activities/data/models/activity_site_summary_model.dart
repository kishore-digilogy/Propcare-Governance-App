import 'package:equatable/equatable.dart';

class RoleOptionModel extends Equatable {
  final String role;
  final String label;

  const RoleOptionModel({
    required this.role,
    required this.label,
  });

  factory RoleOptionModel.fromJson(Map<String, dynamic> json) {
    return RoleOptionModel(
      role: json['role']?.toString() ?? '',
      label: json['label']?.toString() ?? (json['role']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [role, label];
}

class ActivitySiteItemModel extends Equatable {
  final String siteId;
  final String siteName;
  final String siteCode;
  final String siteCity;
  final String siteClientType;
  final String? zoneId;
  final String zoneName;
  final String? clusterId;
  final String clusterName;
  final String siteStatus;
  final int pending;
  final int completed;
  final int total;

  const ActivitySiteItemModel({
    required this.siteId,
    required this.siteName,
    required this.siteCode,
    required this.siteCity,
    required this.siteClientType,
    this.zoneId,
    required this.zoneName,
    this.clusterId,
    required this.clusterName,
    required this.siteStatus,
    required this.pending,
    required this.completed,
    required this.total,
  });

  factory ActivitySiteItemModel.fromJson(Map<String, dynamic> json) {
    return ActivitySiteItemModel(
      siteId: json['siteId']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? 'Unnamed Site',
      siteCode: json['siteCode']?.toString() ?? '',
      siteCity: json['siteCity']?.toString() ?? 'NA',
      siteClientType: json['siteClientType']?.toString().toUpperCase() ?? 'A',
      zoneId: json['zoneId']?.toString(),
      zoneName: json['zoneName']?.toString() ?? '',
      clusterId: json['clusterId']?.toString(),
      clusterName: json['clusterName']?.toString() ?? '',
      siteStatus: json['siteStatus']?.toString().toUpperCase() ?? 'LIVE',
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  int get completionPercent {
    if (total <= 0) return 0;
    return ((completed * 100) / total).round();
  }

  String get subtitleDisplay {
    final parts = <String>[];
    if (clusterName.isNotEmpty) parts.add(clusterName);
    if (zoneName.isNotEmpty) parts.add(zoneName);
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  @override
  List<Object?> get props => [
        siteId,
        siteName,
        siteCode,
        siteCity,
        zoneId,
        zoneName,
        clusterId,
        clusterName,
        siteStatus,
        pending,
        completed,
        total,
      ];
}

class ActivitiesBySiteResponseModel extends Equatable {
  final List<ActivitySiteItemModel> items;
  final int pending;
  final int completed;
  final int total;
  final String view;
  final String myRoleLabel;
  final List<RoleOptionModel> belowRoles;

  const ActivitiesBySiteResponseModel({
    required this.items,
    required this.pending,
    required this.completed,
    required this.total,
    required this.view,
    required this.myRoleLabel,
    this.belowRoles = const [],
  });

  factory ActivitiesBySiteResponseModel.fromJson(Map<String, dynamic> json) {
    final list = <ActivitySiteItemModel>[];
    if (json['items'] is List) {
      for (final it in json['items']) {
        if (it is Map<String, dynamic>) {
          list.add(ActivitySiteItemModel.fromJson(it));
        }
      }
    }

    final roles = <RoleOptionModel>[];
    if (json['belowRoles'] is List) {
      for (final r in json['belowRoles']) {
        if (r is Map<String, dynamic>) {
          roles.add(RoleOptionModel.fromJson(r));
        }
      }
    }

    return ActivitiesBySiteResponseModel(
      items: list,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      view: json['view']?.toString() ?? 'mine',
      myRoleLabel: json['myRoleLabel']?.toString() ?? 'CRRM / Super Admin',
      belowRoles: roles,
    );
  }

  @override
  List<Object?> get props => [items, pending, completed, total, view, myRoleLabel, belowRoles];
}

