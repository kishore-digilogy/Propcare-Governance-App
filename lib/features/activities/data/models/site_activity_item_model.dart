import 'package:equatable/equatable.dart';

class SiteActivityCountsModel extends Equatable {
  final int today;
  final int upcoming;
  final int pending;
  final int overdue;
  final int all;
  final int scheduled;
  final int assigned;
  final int completed;
  final int summaryOverdue;
  final int summaryPending;

  const SiteActivityCountsModel({
    required this.today,
    required this.upcoming,
    required this.pending,
    required this.overdue,
    required this.all,
    required this.scheduled,
    required this.assigned,
    required this.completed,
    required this.summaryOverdue,
    this.summaryPending = 0,
  });

  factory SiteActivityCountsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SiteActivityCountsModel(
        today: 0,
        upcoming: 0,
        pending: 0,
        overdue: 0,
        all: 0,
        scheduled: 0,
        assigned: 0,
        completed: 0,
        summaryOverdue: 0,
        summaryPending: 0,
      );
    }

    final scheduled = (json['scheduled'] as num?)?.toInt() ?? 0;
    final assigned = (json['assigned'] as num?)?.toInt() ?? 0;

    return SiteActivityCountsModel(
      today: (json['today'] as num?)?.toInt() ?? 0,
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      all: (json['all'] as num?)?.toInt() ?? 0,
      scheduled: scheduled,
      assigned: assigned,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      summaryOverdue: (json['summaryOverdue'] as num?)?.toInt() ?? 0,
      summaryPending: (json['summaryPending'] as num?)?.toInt() ?? (scheduled + assigned),
    );
  }

  @override
  List<Object?> get props => [
        today,
        upcoming,
        pending,
        overdue,
        all,
        scheduled,
        assigned,
        completed,
        summaryOverdue,
        summaryPending,
      ];
}

class SiteActivityItemModel extends Equatable {
  final String id;
  final String siteId;
  final String role;
  final String kind;
  final String title;
  final String? assignedToId;
  final String? assignedToName;
  final String? scheduledDate;
  final String? dueDate;
  final String status;
  final String clientType;
  final String code;
  final String siteName;
  final String siteCity;
  final String zoneName;
  final String clusterName;
  final String functionLabel;
  final String roleLabel;
  final String frequencyLabel;
  final String priority;
  final String statusLabel;

  const SiteActivityItemModel({
    required this.id,
    required this.siteId,
    required this.role,
    required this.kind,
    required this.title,
    this.assignedToId,
    this.assignedToName,
    this.scheduledDate,
    this.dueDate,
    required this.status,
    required this.clientType,
    required this.code,
    required this.siteName,
    required this.siteCity,
    this.zoneName = '',
    required this.clusterName,
    required this.functionLabel,
    required this.roleLabel,
    required this.frequencyLabel,
    required this.priority,
    required this.statusLabel,
  });

  factory SiteActivityItemModel.fromJson(Map<String, dynamic> json) {
    return SiteActivityItemModel(
      id: json['id']?.toString() ?? '',
      siteId: json['siteId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'GOVERNANCE',
      title: json['title']?.toString() ?? 'Visit',
      assignedToId: json['assignedToId']?.toString(),
      assignedToName: json['assignedToName']?.toString(),
      scheduledDate: json['scheduledDate']?.toString(),
      dueDate: json['dueDate']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      clientType: json['clientType']?.toString().toUpperCase() ?? 'A',
      code: json['code']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? '',
      siteCity: json['siteCity']?.toString() ?? 'NA',
      zoneName: json['zoneName']?.toString() ?? '',
      clusterName: json['clusterName']?.toString() ?? '',
      functionLabel: json['functionLabel']?.toString() ?? '',
      roleLabel: (json['roleLabel'] != null && json['roleLabel'].toString().isNotEmpty)
          ? json['roleLabel'].toString()
          : (json['role']?.toString().toUpperCase() == 'CRRM'
              ? 'CRRM / Super Admin'
              : (json['role']?.toString() ?? '')),
      frequencyLabel: json['frequencyLabel']?.toString() ?? 'Quarterly',
      priority: json['priority']?.toString() ?? 'Medium',
      statusLabel: json['statusLabel']?.toString() ?? 'Scheduled',
    );
  }

  /// Formatted date e.g. "2027-02-02" -> "2 Feb 2027"
  String get formattedDate {
    final d = scheduledDate ?? dueDate;
    if (d == null || d.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(d);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return d;
    }
  }

  @override
  List<Object?> get props => [id, siteId, title, scheduledDate, status, role, zoneName];
}

class BelowRoleItemModel extends Equatable {
  final String role;
  final String label;

  const BelowRoleItemModel({required this.role, required this.label});

  factory BelowRoleItemModel.fromJson(Map<String, dynamic> json) =>
      BelowRoleItemModel(
        role: json['role']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );

  @override
  List<Object?> get props => [role, label];
}

class ActivitySiteOptionModel extends Equatable {
  final String siteId;
  final String siteName;

  const ActivitySiteOptionModel({required this.siteId, required this.siteName});

  @override
  List<Object?> get props => [siteId, siteName];
}

class SiteActivitiesResponseModel extends Equatable {
  final List<SiteActivityItemModel> items;
  final int total;
  final int limit;
  final int offset;
  final SiteActivityCountsModel counts;
  final String view;
  final String myRole;
  final String myRoleLabel;
  final List<BelowRoleItemModel> belowRoles;
  final int mineTotal;
  final int belowTotal;

  const SiteActivitiesResponseModel({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.counts,
    required this.view,
    required this.myRole,
    required this.myRoleLabel,
    this.belowRoles = const [],
    this.mineTotal = 0,
    this.belowTotal = 0,
  });

  factory SiteActivitiesResponseModel.fromJson(Map<String, dynamic> json) {
    final list = <SiteActivityItemModel>[];
    if (json['items'] is List) {
      for (final it in json['items']) {
        if (it is Map<String, dynamic>) {
          list.add(SiteActivityItemModel.fromJson(it));
        }
      }
    }

    final belowRolesList = <BelowRoleItemModel>[];
    if (json['belowRoles'] is List) {
      for (final r in json['belowRoles']) {
        if (r is Map<String, dynamic>) {
          belowRolesList.add(BelowRoleItemModel.fromJson(r));
        }
      }
    }

    return SiteActivitiesResponseModel(
      items: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      counts: SiteActivityCountsModel.fromJson(json['counts'] as Map<String, dynamic>?),
      view: json['view']?.toString() ?? 'mine',
      myRole: json['myRole']?.toString() ?? '',
      myRoleLabel: json['myRoleLabel']?.toString() ?? '',
      belowRoles: belowRolesList,
      mineTotal: (json['mineTotal'] as num?)?.toInt() ?? 0,
      belowTotal: (json['belowTotal'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [items, total, limit, offset, counts, view, myRole, belowRoles, mineTotal, belowTotal];
}

