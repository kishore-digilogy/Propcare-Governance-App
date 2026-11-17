// Models for the /api/dashboard response.

class DashboardCountsModel {
  final int sites;
  final int active;
  final int inactive;
  final int draft;
  final int delayed;
  final int live;
  final int transition;
  final int pending;
  final int completed;
  final int overdue;
  final int openIssues;
  final int closedIssues;
  final int openActions;
  final int tatAlerts;
  final int approvals;
  final int dueToday;
  final int special;
  final double? compliance;
  final int? geoCompliance;

  const DashboardCountsModel({
    required this.sites,
    required this.active,
    required this.inactive,
    this.draft = 0,
    this.delayed = 0,
    required this.live,
    required this.transition,
    required this.pending,
    required this.completed,
    required this.overdue,
    required this.openIssues,
    this.closedIssues = 0,
    required this.openActions,
    required this.tatAlerts,
    required this.approvals,
    required this.dueToday,
    this.special = 0,
    this.compliance,
    this.geoCompliance,
  });

  factory DashboardCountsModel.fromJson(Map<String, dynamic> j) =>
      DashboardCountsModel(
        sites: j['sites'] as int? ?? 0,
        active: j['active'] as int? ?? 0,
        inactive: j['inactive'] as int? ?? 0,
        draft: j['draft'] as int? ?? 0,
        delayed: j['delayed'] as int? ?? 0,
        live: j['live'] as int? ?? 0,
        transition: j['transition'] as int? ?? 0,
        pending: j['pending'] as int? ?? 0,
        completed: j['completed'] as int? ?? 0,
        overdue: j['overdue'] as int? ?? 0,
        openIssues: j['openIssues'] as int? ?? 0,
        closedIssues: j['closedIssues'] as int? ?? 0,
        openActions: j['openActions'] as int? ?? 0,
        tatAlerts: j['tatAlerts'] as int? ?? 0,
        approvals: j['approvals'] as int? ?? 0,
        dueToday: j['dueToday'] as int? ?? 0,
        special: j['special'] as int? ?? 0,
        compliance: (j['compliance'] as num?)?.toDouble(),
        geoCompliance: j['geoCompliance'] as int?,
      );
}

class RenewalCountsModel {
  final int d30;
  final int d60;
  final int d90;
  final int pending;
  final List<RenewalItemModel> items30;
  final List<RenewalItemModel> items60;
  final List<RenewalItemModel> items90;
  final List<RenewalItemModel> itemsPending;

  const RenewalCountsModel({
    required this.d30,
    required this.d60,
    required this.d90,
    this.pending = 0,
    required this.items30,
    required this.items60,
    required this.items90,
    this.itemsPending = const [],
  });

  factory RenewalCountsModel.fromJson(Map<String, dynamic> j) {
    final counts = j['counts'] as Map<String, dynamic>? ?? {};
    final items = j['items'] as Map<String, dynamic>? ?? {};

    List<RenewalItemModel> parseList(dynamic raw) {
      if (raw == null) return [];
      return (raw as List)
          .map((e) => RenewalItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return RenewalCountsModel(
      d30: counts['30'] as int? ?? 0,
      d60: counts['60'] as int? ?? 0,
      d90: counts['90'] as int? ?? 0,
      pending: counts['pending'] as int? ?? 0,
      items30: parseList(items['30']),
      items60: parseList(items['60']),
      items90: parseList(items['90']),
      itemsPending: parseList(items['pending']),
    );
  }
}

class RenewalItemModel {
  final String id;
  final String name;
  final String code;
  final String clientName;
  final String contractEndDate;
  final int daysRemaining;
  final String zoneName;
  final String clusterName;

  const RenewalItemModel({
    required this.id,
    required this.name,
    required this.code,
    required this.clientName,
    required this.contractEndDate,
    required this.daysRemaining,
    required this.zoneName,
    required this.clusterName,
  });

  factory RenewalItemModel.fromJson(Map<String, dynamic> j) => RenewalItemModel(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    code: j['code'] as String? ?? '',
    clientName: j['clientName'] as String? ?? '',
    contractEndDate: j['contractEndDate'] as String? ?? '',
    daysRemaining: j['daysRemaining'] as int? ?? 0,
    zoneName: j['zoneName'] as String? ?? '',
    clusterName: j['clusterName'] as String? ?? '',
  );
}

class GeographyItemModel {
  final String id;
  final String name;
  final int sites;
  final int overdue;
  final int openIssues;

  const GeographyItemModel({
    required this.id,
    required this.name,
    required this.sites,
    required this.overdue,
    required this.openIssues,
  });

  factory GeographyItemModel.fromJson(Map<String, dynamic> j) =>
      GeographyItemModel(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        sites: j['sites'] as int? ?? 0,
        overdue: j['overdue'] as int? ?? 0,
        openIssues: j['openIssues'] as int? ?? 0,
      );
}

class SpocPerformanceModel {
  final String userId;
  final String name;
  final String role;
  final String roleLabel;
  final int open;
  final int assigned;

  const SpocPerformanceModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.roleLabel,
    required this.open,
    required this.assigned,
  });

  factory SpocPerformanceModel.fromJson(Map<String, dynamic> j) =>
      SpocPerformanceModel(
        userId: j['userId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        role: j['role'] as String? ?? '',
        roleLabel: j['roleLabel'] as String? ?? '',
        open: j['open'] as int? ?? 0,
        assigned: j['assigned'] as int? ?? 0,
      );
}

class ChartPointModel {
  final String date;
  final int completed;
  final int due;

  const ChartPointModel({
    required this.date,
    required this.completed,
    required this.due,
  });

  factory ChartPointModel.fromJson(Map<String, dynamic> j) => ChartPointModel(
    date: j['date'] as String? ?? '',
    completed: j['completed'] as int? ?? 0,
    due: j['due'] as int? ?? 0,
  );
}

class GroupItemModel {
  final String id;
  final String name;
  final int sites;
  final int live;
  final int overdue;

  const GroupItemModel({
    required this.id,
    required this.name,
    required this.sites,
    required this.live,
    required this.overdue,
  });

  factory GroupItemModel.fromJson(Map<String, dynamic> j) => GroupItemModel(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    sites: j['sites'] as int? ?? 0,
    live: j['live'] as int? ?? 0,
    overdue: j['overdue'] as int? ?? 0,
  );
}

class GovernanceListItemModel {
  final String id;
  final String title;
  final String siteName;
  final String roleLabel;
  final String dueDate;
  final String assigneeName;
  final String state;
  final String? activityLabel;
  final String? href;

  const GovernanceListItemModel({
    required this.id,
    required this.title,
    required this.siteName,
    required this.roleLabel,
    required this.dueDate,
    required this.assigneeName,
    required this.state,
    this.activityLabel,
    this.href,
  });

  factory GovernanceListItemModel.fromJson(Map<String, dynamic> j) =>
      GovernanceListItemModel(
        id: j['id'] as String? ??
            j['activityId'] as String? ??
            j['_id'] as String? ??
            '',
        title: j['title'] as String? ??
            j['activityLabel'] as String? ??
            j['name'] as String? ??
            '',
        siteName: j['siteName'] as String? ?? '',
        roleLabel: j['roleLabel'] as String? ?? j['role'] as String? ?? '',
        dueDate: j['dueDate'] as String? ?? '',
        assigneeName: j['assigneeName'] as String? ?? j['assignee'] as String? ?? '',
        state: j['state'] as String? ?? j['status'] as String? ?? '',
        activityLabel: j['activityLabel'] as String?,
        href: j['href'] as String?,
      );
}

class SurveysSummaryModel {
  final int created;
  final int assigned;
  final int completed;
  final int pending;
  final bool visible;
  final bool clickable;

  const SurveysSummaryModel({
    this.created = 0,
    this.assigned = 0,
    this.completed = 0,
    this.pending = 0,
    this.visible = true,
    this.clickable = true,
  });

  factory SurveysSummaryModel.fromJson(Map<String, dynamic> j) =>
      SurveysSummaryModel(
        created: j['created'] as int? ?? 0,
        assigned: j['assigned'] as int? ?? 0,
        completed: j['completed'] as int? ?? 0,
        pending: j['pending'] as int? ?? 0,
        visible: j['visible'] as bool? ?? true,
        clickable: j['clickable'] as bool? ?? true,
      );
}

class GovernanceParamModel {
  final String key;
  final String label;
  final String icon;
  final int target;
  final int completed;
  final int pending;
  final int due;
  final int momCompleted;
  final int momPending;

  const GovernanceParamModel({
    required this.key,
    required this.label,
    required this.icon,
    this.target = 0,
    this.completed = 0,
    this.pending = 0,
    this.due = 0,
    this.momCompleted = 0,
    this.momPending = 0,
  });

  factory GovernanceParamModel.fromJson(Map<String, dynamic> j) =>
      GovernanceParamModel(
        key: j['key'] as String? ?? '',
        label: j['label'] as String? ?? '',
        icon: j['icon'] as String? ?? '',
        target: j['target'] as int? ?? 0,
        completed: j['completed'] as int? ?? 0,
        pending: j['pending'] as int? ?? 0,
        due: j['due'] as int? ?? 0,
        momCompleted: j['momCompleted'] as int? ?? 0,
        momPending: j['momPending'] as int? ?? 0,
      );
}

class RoleOptionModel {
  final String role;
  final String label;

  const RoleOptionModel({required this.role, required this.label});

  factory RoleOptionModel.fromJson(Map<String, dynamic> j) => RoleOptionModel(
        role: j['role'] as String? ?? '',
        label: j['label'] as String? ?? j['roleLabel'] as String? ?? '',
      );
}

class KeyAlertModel {
  final String tone;
  final String title;
  final String detail;
  final String href;
  final int count;

  const KeyAlertModel({
    this.tone = 'blue',
    this.title = '',
    this.detail = '',
    this.href = '',
    this.count = 0,
  });

  factory KeyAlertModel.fromJson(dynamic item) {
    if (item is KeyAlertModel) return item;
    if (item is Map<String, dynamic>) {
      final title = item['title'] as String? ?? '';
      final detail = item['detail'] as String? ?? '';
      final tone = item['tone'] as String? ?? 'blue';
      final href = item['href'] as String? ?? '';

      int count = 0;
      final countRaw = item['count'];
      if (countRaw is int) {
        count = countRaw;
      } else if (countRaw is String) {
        count = int.tryParse(countRaw) ?? 0;
      } else {
        final match = RegExp(r'(\d+)').firstMatch(detail) ??
            RegExp(r'(\d+)').firstMatch(title);
        if (match != null) {
          count = int.tryParse(match.group(1)!) ?? 0;
        }
      }
      return KeyAlertModel(
        tone: tone,
        title: title,
        detail: detail,
        href: href,
        count: count,
      );
    }
    final str = item.toString();
    final match = RegExp(r'(\d+)').firstMatch(str);
    final count = match != null ? (int.tryParse(match.group(1)!) ?? 0) : 0;
    return KeyAlertModel(
      title: str,
      detail: str,
      count: count,
    );
  }
}

class UpcomingActivityModel {
  final String id;
  final String title;
  final String activityLabel;
  final String siteName;
  final String roleLabel;
  final String dueDate;
  final int daysUntil;
  final String assigneeName;
  final String state;

  const UpcomingActivityModel({
    required this.id,
    this.title = '',
    this.activityLabel = '',
    this.siteName = '',
    this.roleLabel = '',
    this.dueDate = '',
    this.daysUntil = 0,
    this.assigneeName = '',
    this.state = '',
  });

  factory UpcomingActivityModel.fromJson(dynamic item) {
    if (item is UpcomingActivityModel) return item;
    if (item is Map<String, dynamic>) {
      return UpcomingActivityModel(
        id: item['id'] as String? ??
            item['activityId'] as String? ??
            item['_id'] as String? ??
            '',
        title: item['title'] as String? ??
            item['activityLabel'] as String? ??
            item['name'] as String? ??
            '',
        activityLabel: item['activityLabel'] as String? ?? '',
        siteName: item['siteName'] as String? ?? '',
        roleLabel: item['roleLabel'] as String? ?? item['role'] as String? ?? '',
        dueDate: item['dueDate'] as String? ?? '',
        daysUntil: item['daysUntil'] as int? ?? 0,
        assigneeName: item['assigneeName'] as String? ?? '',
        state: item['state'] as String? ?? item['status'] as String? ?? '',
      );
    }
    return UpcomingActivityModel(id: '', title: item.toString());
  }
}

class OverviewModel {
  final int sites;
  final int live;
  final int draft;
  final int inactive;
  final int special;
  final int transition;
  final int users;
  final int governancePending;
  final int governanceCompleted;
  final int governanceDue;
  final int governanceEscalated;
  final int governanceOpen;
  final double compliancePct;
  final SurveysSummaryModel surveys;
  final List<GovernanceParamModel> governanceParams;
  final String selectedRole;
  final List<RoleOptionModel> roleFilterRoles;
  final List<KeyAlertModel> alerts;
  final List<UpcomingActivityModel> upcoming;
  final List<GovernanceListItemModel> governanceList;

  const OverviewModel({
    required this.sites,
    required this.live,
    this.draft = 0,
    this.inactive = 0,
    this.special = 0,
    required this.transition,
    required this.users,
    required this.governancePending,
    required this.governanceCompleted,
    required this.governanceDue,
    this.governanceEscalated = 0,
    this.governanceOpen = 0,
    this.compliancePct = 0.0,
    this.surveys = const SurveysSummaryModel(),
    this.governanceParams = const [],
    this.selectedRole = '',
    this.roleFilterRoles = const [],
    this.alerts = const [],
    this.upcoming = const [],
    required this.governanceList,
  });

  factory OverviewModel.fromJson(Map<String, dynamic> j) {
    final gov = j['governance'] as Map<String, dynamic>? ?? {};
    final list = (j['governanceList'] as List? ?? [])
        .map((e) => GovernanceListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final roleFilter = j['roleFilter'] as Map<String, dynamic>? ?? {};
    final rolesRaw = roleFilter['roles'] as List? ?? [];

    return OverviewModel(
      sites: j['sites'] as int? ?? 0,
      live: j['live'] as int? ?? 0,
      draft: j['draft'] as int? ?? 0,
      inactive: j['inactive'] as int? ?? 0,
      special: j['special'] as int? ?? 0,
      transition: j['transition'] as int? ?? 0,
      users: j['users'] as int? ?? 0,
      governancePending: gov['pending'] as int? ?? 0,
      governanceCompleted: gov['completed'] as int? ?? 0,
      governanceDue: gov['due'] as int? ?? 0,
      governanceEscalated: gov['escalated'] as int? ?? 0,
      governanceOpen: gov['open'] as int? ?? 0,
      compliancePct: (gov['compliancePct'] as num?)?.toDouble() ?? 0.0,
      surveys: SurveysSummaryModel.fromJson(
        j['surveys'] as Map<String, dynamic>? ?? {},
      ),
      governanceParams: (j['governanceParams'] as List? ?? [])
          .map((e) => GovernanceParamModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedRole: roleFilter['selected'] as String? ?? '',
      roleFilterRoles: rolesRaw
          .map((e) => RoleOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      alerts: (j['alerts'] as List? ?? [])
          .map((e) => KeyAlertModel.fromJson(e))
          .toList(),
      upcoming: (j['upcoming'] as List? ?? [])
          .map((e) => UpcomingActivityModel.fromJson(e))
          .toList(),
      governanceList: list,
    );
  }
}

class WorkspaceViewerModel {
  final String id;
  final String name;
  final String role;
  final String roleLabel;

  const WorkspaceViewerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.roleLabel,
  });

  factory WorkspaceViewerModel.fromJson(Map<String, dynamic> j) =>
      WorkspaceViewerModel(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        role: j['role'] as String? ?? '',
        roleLabel: j['roleLabel'] as String? ?? '',
      );
}

class ZoneModel {
  final String id;
  final String name;
  final int sites;
  final int live;
  final int transition;
  final int clusters;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.sites,
    required this.live,
    required this.transition,
    required this.clusters,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> j) => ZoneModel(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    sites: j['sites'] as int? ?? 0,
    live: j['live'] as int? ?? 0,
    transition: j['transition'] as int? ?? 0,
    clusters: j['clusters'] as int? ?? 0,
  );
}

class ClusterModel {
  final String id;
  final String name;
  final String zoneName;
  final int sites;
  final int live;
  final int transition;

  const ClusterModel({
    required this.id,
    required this.name,
    required this.zoneName,
    required this.sites,
    required this.live,
    required this.transition,
  });

  factory ClusterModel.fromJson(Map<String, dynamic> j) => ClusterModel(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    zoneName: j['zoneName'] as String? ?? '',
    sites: j['sites'] as int? ?? 0,
    live: j['live'] as int? ?? 0,
    transition: j['transition'] as int? ?? 0,
  );
}

class SiteModel {
  final String id;
  final String name;
  final String code;
  final String status;
  final String zoneName;
  final String clusterName;

  const SiteModel({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    required this.zoneName,
    required this.clusterName,
  });

  factory SiteModel.fromJson(Map<String, dynamic> j) => SiteModel(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    code: j['code'] as String? ?? '',
    status: j['status'] as String? ?? '',
    zoneName: j['zoneName'] as String? ?? '',
    clusterName: j['clusterName'] as String? ?? '',
  );
}

class WorkspaceModel {
  final WorkspaceViewerModel viewer;
  final bool pan;
  final List<ZoneModel> zones;
  final List<ClusterModel> clusters;
  final List<SiteModel> sites;
  final List<RoleOptionModel> roles;
  final int siteCount;

  const WorkspaceModel({
    required this.viewer,
    required this.pan,
    required this.zones,
    required this.clusters,
    required this.sites,
    this.roles = const [],
    required this.siteCount,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> j) => WorkspaceModel(
    viewer: WorkspaceViewerModel.fromJson(
      j['viewer'] as Map<String, dynamic>? ?? {},
    ),
    pan: j['pan'] as bool? ?? false,
    zones: (j['zones'] as List? ?? [])
        .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    clusters: (j['clusters'] as List? ?? [])
        .map((e) => ClusterModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    sites: (j['sites'] as List? ?? [])
        .map((e) => SiteModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    roles: (j['roles'] as List? ?? [])
        .map((e) => RoleOptionModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    siteCount: j['siteCount'] as int? ?? 0,
  );
}

/// Top-level dashboard model.
class DashboardModel {
  final String date;
  final DashboardCountsModel counts;
  final RenewalCountsModel renewals;
  final List<GeographyItemModel> geography;
  final List<SpocPerformanceModel> spocPerformance;
  final List<ChartPointModel> chart;
  final List<GroupItemModel> groups;
  final OverviewModel overview;
  final WorkspaceModel workspace;
  final String? drillZoneId;

  const DashboardModel({
    required this.date,
    required this.counts,
    required this.renewals,
    required this.geography,
    required this.spocPerformance,
    required this.chart,
    required this.groups,
    required this.overview,
    required this.workspace,
    this.drillZoneId,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> j) => DashboardModel(
    date: j['date'] as String? ?? '',
    drillZoneId: j['drillZoneId'] as String?,
    counts: DashboardCountsModel.fromJson(
      j['counts'] as Map<String, dynamic>? ?? {},
    ),
    renewals: RenewalCountsModel.fromJson(
      j['renewals'] as Map<String, dynamic>? ?? {},
    ),
    geography: (j['geography'] as List? ?? [])
        .map((e) => GeographyItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    spocPerformance: (j['spocPerformance'] as List? ?? [])
        .map((e) => SpocPerformanceModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    chart: (j['chart'] as List? ?? [])
        .map((e) => ChartPointModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    groups: (j['groups'] as List? ?? [])
        .map((e) => GroupItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    overview: OverviewModel.fromJson({
      ...?j['overview'] as Map<String, dynamic>?,
      if (!(j['overview'] as Map<String, dynamic>? ?? {}).containsKey('alerts') &&
          j.containsKey('alerts'))
        'alerts': j['alerts'],
      if (!(j['overview'] as Map<String, dynamic>? ?? {}).containsKey('upcoming') &&
          j.containsKey('upcoming'))
        'upcoming': j['upcoming'],
    }),
    workspace: WorkspaceModel.fromJson(
      j['workspace'] as Map<String, dynamic>? ?? {},
    ),
  );
}
