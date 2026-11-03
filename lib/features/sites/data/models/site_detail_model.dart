import 'package:equatable/equatable.dart';

import 'site_model.dart';

class SiteActivityModel extends Equatable {
  final String id;
  final String title;
  final String code;
  final String role;
  final String spocName;
  final String freq;
  final String? dueDate;
  final String? scheduledDate;
  final String status;

  const SiteActivityModel({
    required this.id,
    required this.title,
    required this.code,
    required this.role,
    required this.spocName,
    required this.freq,
    this.dueDate,
    this.scheduledDate,
    required this.status,
  });

  factory SiteActivityModel.fromJson(Map<String, dynamic> json) {
    return SiteActivityModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Activity',
      code: json['code']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      spocName: json['spocName']?.toString() ?? '—',
      freq: json['freq']?.toString() ?? '',
      dueDate: json['dueDate']?.toString(),
      scheduledDate: json['scheduledDate']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
    );
  }

  String get formattedDueDate {
    final raw = dueDate ?? scheduledDate;
    if (raw == null || raw.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(raw);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return raw;
    }
  }

  String get roleLabel {
    if (role.isEmpty) return '—';
    final upper = role.trim().toUpperCase();
    if (upper == 'CRRM' ||
        upper == 'SUPER_ADMIN' ||
        upper == 'SUPERADMIN' ||
        upper == 'ADMIN') {
      return 'CRRM / Super Admin';
    }
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  String get statusDisplay {
    if (status == 'COMPLETED') return 'Completed';
    return 'Scheduled';
  }

  @override
  List<Object?> get props => [id, title, code, role, spocName, freq, dueDate, status];
}

class SiteDetailModel extends Equatable {
  final String id;
  final String name;
  final String code;
  final String clientName;
  final String? clientGroupId;
  final String? clientEmail;
  final String? contactPersonName;
  final String? contactPhone;
  final String? location;
  final String? city;
  final String? state;
  final String? zoneId;
  final String? groupId;
  final String? clusterId;
  final String? billingPm;
  final String clientType;
  final String? contractStartDate;
  final String? contractEndDate;
  final String? contractAwardDate;
  final String? actualStartDate;
  final String? plannedStartDate;
  final String? activationDate;
  final String status;
  final String zone;
  final String zoneName;
  final String cluster;
  final String clusterName;
  final String group;
  final String groupName;
  final String service;
  final String serviceName;
  final String zonalHead;
  final String groupClusterHead;
  final String clusterHead;
  final String clusterLead;
  final String fieldExecutive;
  final String lead;
  final String head;
  final int manpowerRequired;
  final int manpowerDeployed;
  final int shortage;
  final int openIssuesCount;
  final int machineryCount;
  final String? nextActivityDate;
  final String? nextActivityTitle;
  final bool specialAttention;
  final bool specialAttentionActive;
  final String? specialAttentionStart;
  final String? specialAttentionEnd;
  final String? specialReason;
  final List<MachineryItemModel> machinery;

  const SiteDetailModel({
    required this.id,
    required this.name,
    required this.code,
    required this.clientName,
    this.clientGroupId,
    this.clientEmail,
    this.contactPersonName,
    this.contactPhone,
    this.location,
    this.city,
    this.state,
    this.zoneId,
    this.groupId,
    this.clusterId,
    this.billingPm,
    required this.clientType,
    this.contractStartDate,
    this.contractEndDate,
    this.contractAwardDate,
    this.actualStartDate,
    this.plannedStartDate,
    this.activationDate,
    required this.status,
    required this.zone,
    required this.zoneName,
    required this.cluster,
    required this.clusterName,
    required this.group,
    required this.groupName,
    required this.service,
    required this.serviceName,
    this.zonalHead = '—',
    this.groupClusterHead = '—',
    this.clusterHead = '—',
    this.clusterLead = '—',
    this.fieldExecutive = '—',
    this.lead = '—',
    this.head = '—',
    this.manpowerRequired = 0,
    this.manpowerDeployed = 0,
    this.shortage = 0,
    this.openIssuesCount = 0,
    this.machineryCount = 0,
    this.nextActivityDate,
    this.nextActivityTitle,
    this.specialAttention = false,
    this.specialAttentionActive = false,
    this.specialAttentionStart,
    this.specialAttentionEnd,
    this.specialReason,
    this.machinery = const [],
  });

  factory SiteDetailModel.fromJson(Map<String, dynamic> json) {
    final machineryList = <MachineryItemModel>[];
    if (json['machinery'] is List) {
      for (final m in json['machinery']) {
        if (m is Map<String, dynamic>) {
          machineryList.add(MachineryItemModel.fromJson(m));
        }
      }
    }

    final manpowerReq = (json['manpowerRequired'] as num?)?.toInt() ?? 0;
    final manpowerDep = (json['manpowerDeployed'] as num?)?.toInt() ?? 0;
    final shortageVal = (json['shortage'] as num?)?.toInt() ?? (manpowerReq - manpowerDep);

    final isSpecial = json['special'] == true || json['special']?.toString() == 'true';

    return SiteDetailModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Site',
      code: json['code']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',
      clientGroupId: json['clientGroupId']?.toString(),
      clientEmail: json['clientEmail']?.toString(),
      contactPersonName: json['contactPersonName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      location: json['location']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zoneId: json['zoneId']?.toString(),
      groupId: json['groupId']?.toString(),
      clusterId: json['clusterId']?.toString(),
      billingPm: json['billingPm']?.toString(),
      clientType: json['effectiveClientType']?.toString().toUpperCase() ??
          json['clientType']?.toString().toUpperCase() ??
          'A',
      contractStartDate: json['contractStartDate']?.toString(),
      contractEndDate: json['contractEndDate']?.toString(),
      contractAwardDate: json['contractAwardDate']?.toString(),
      actualStartDate: json['actualStartDate']?.toString(),
      plannedStartDate: json['plannedStartDate']?.toString(),
      activationDate: json['activationDate']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'LIVE',
      zone: json['zone']?.toString() ?? '',
      zoneName: json['zoneName']?.toString() ?? (json['zone']?.toString() ?? ''),
      cluster: json['cluster']?.toString() ?? '',
      clusterName: json['clusterName']?.toString() ?? (json['cluster']?.toString() ?? ''),
      group: json['group']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? '',
      service: json['service']?.toString() ?? 'HK',
      serviceName: json['serviceName']?.toString() ?? 'HK',
      zonalHead: json['zonalHead']?.toString() ?? '—',
      groupClusterHead: json['groupClusterHead']?.toString() ?? '—',
      clusterHead: json['clusterHead']?.toString() ?? '—',
      clusterLead: json['clusterLead']?.toString() ?? (json['lead']?.toString() ?? '—'),
      fieldExecutive: json['fieldExecutive']?.toString() ?? '—',
      lead: json['lead']?.toString() ?? '—',
      head: json['head']?.toString() ?? '—',
      manpowerRequired: manpowerReq,
      manpowerDeployed: manpowerDep,
      shortage: shortageVal > 0 ? shortageVal : 0,
      openIssuesCount: (json['openIssuesCount'] as num?)?.toInt() ?? 0,
      machineryCount: (json['machineryCount'] as num?)?.toInt() ?? machineryList.length,
      nextActivityDate: json['nextActivityDate']?.toString(),
      nextActivityTitle: json['nextActivityTitle']?.toString(),
      specialAttention: isSpecial,
      specialAttentionActive: json['specialAttentionActive'] == true,
      specialAttentionStart: json['specialAttentionStart']?.toString(),
      specialAttentionEnd: json['specialAttentionEnd']?.toString(),
      specialReason: json['specialReason']?.toString(),
      machinery: machineryList,
    );
  }

  /// Formatted billing string, e.g. "₹7.40L"
  String get formattedBillingPm {
    if (billingPm == null || billingPm!.isEmpty) return '—';
    final parsed = double.tryParse(billingPm!);
    if (parsed == null) return '₹$billingPm';

    if (parsed >= 100000) {
      final inLakhs = parsed / 100000.0;
      return '₹${inLakhs.toStringAsFixed(2)}L';
    } else if (parsed >= 1000) {
      final inK = parsed / 1000.0;
      return '₹${inK.toStringAsFixed(1)}K';
    }
    return '₹${parsed.toStringAsFixed(0)}';
  }

  /// Formatted start date, e.g. "2 Nov 2026"
  String get formattedActualStartDate {
    final raw = actualStartDate ?? plannedStartDate ?? contractStartDate;
    if (raw == null || raw.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(raw);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return raw;
    }
  }

  String get formattedContractAwardDate {
    if (contractAwardDate == null || contractAwardDate!.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(contractAwardDate!);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return contractAwardDate!;
    }
  }

  String get formattedNextActivityDay {
    if (nextActivityDate == null || nextActivityDate!.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(nextActivityDate!);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]}';
    } catch (_) {
      return nextActivityDate!;
    }
  }

  String get zoneAndClusterBreadcrumb {
    final z = zoneName.isNotEmpty ? zoneName : zone;
    final c = clusterName.isNotEmpty ? clusterName : cluster;
    if (z.isNotEmpty && c.isNotEmpty) return '$z Zone  >  $c';
    if (z.isNotEmpty) return '$z Zone';
    return c;
  }

  String get zoneGroupDisplay {
    final z = zone.isNotEmpty ? zone : '—';
    final g = group.isNotEmpty ? group : cluster;
    return '$z - ${g.isNotEmpty ? g : '—'}';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        clientName,
        clientType,
        status,
        billingPm,
        specialAttention,
        openIssuesCount,
        manpowerRequired,
        manpowerDeployed,
      ];
}

class SiteDetailResponseModel extends Equatable {
  final SiteDetailModel site;
  final List<SiteActivityModel> activities;
  final List<dynamic> spocs;
  final List<dynamic> issues;

  const SiteDetailResponseModel({
    required this.site,
    this.activities = const [],
    this.spocs = const [],
    this.issues = const [],
  });

  factory SiteDetailResponseModel.fromJson(Map<String, dynamic> json) {
    final siteMap = json['site'] is Map<String, dynamic>
        ? json['site'] as Map<String, dynamic>
        : json['site'] is Map
            ? Map<String, dynamic>.from(json['site'] as Map)
            : <String, dynamic>{};

    final activitiesList = <SiteActivityModel>[];
    if (json['activities'] is List) {
      for (final a in json['activities']) {
        if (a is Map) {
          activitiesList.add(SiteActivityModel.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }

    return SiteDetailResponseModel(
      site: SiteDetailModel.fromJson(siteMap),
      activities: activitiesList,
      spocs: json['spocs'] as List<dynamic>? ?? [],
      issues: json['issues'] as List<dynamic>? ?? [],
    );
  }

  @override
  List<Object?> get props => [site, activities, spocs, issues];
}

