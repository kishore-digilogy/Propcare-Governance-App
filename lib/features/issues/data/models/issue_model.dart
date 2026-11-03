const _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Action point associated with an issue
class IssueActionModel {
  final String id;
  final String? issueId;
  final String? siteId;
  final String title;
  final String status;
  final String? ownerId;
  final String? owner;
  final String? dueDate;
  final String? closureNotes;
  final String? closedAt;

  const IssueActionModel({
    required this.id,
    this.issueId,
    this.siteId,
    required this.title,
    this.status = 'OPEN',
    this.ownerId,
    this.owner,
    this.dueDate,
    this.closureNotes,
    this.closedAt,
  });

  factory IssueActionModel.fromJson(Map<String, dynamic> json) {
    return IssueActionModel(
      id: json['id']?.toString() ?? '',
      issueId: json['issueId']?.toString(),
      siteId: json['siteId']?.toString(),
      title: json['title']?.toString() ?? json['action']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      ownerId: json['ownerId']?.toString(),
      owner: json['owner']?.toString() ?? json['ownerName']?.toString(),
      dueDate: json['dueDate']?.toString() ?? json['due']?.toString(),
      closureNotes: json['closureNotes']?.toString(),
      closedAt: json['closedAt']?.toString(),
    );
  }

  String get formattedStatus {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'Open';
      case 'CLOSED':
        return 'Closed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      default:
        return status;
    }
  }

  String get formattedDueDate {
    if (dueDate == null || dueDate!.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dueDate!);
      final monthName = _kMonths[dt.month - 1];
      return '${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return dueDate!;
    }
  }
}

/// Core model for a Site Issue
class IssueModel {
  final String id;
  final String siteId;
  final String? activityId;
  final String department;
  final String title;
  final String description;
  final String priority;
  final String ownerId;
  final String dueDate;
  final String status;
  final String? resolution;
  final String? closedAt;
  final String? createdById;
  final String? createdAt;
  final String? updatedAt;
  final String? origin;
  final String? checklistTitle;

  const IssueModel({
    required this.id,
    required this.siteId,
    this.activityId,
    this.department = 'OPERATIONS',
    required this.title,
    this.description = '',
    required this.priority,
    required this.ownerId,
    required this.dueDate,
    this.status = 'OPEN',
    this.resolution,
    this.closedAt,
    this.createdById,
    this.createdAt,
    this.updatedAt,
    this.origin,
    this.checklistTitle,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id']?.toString() ?? '',
      siteId: json['siteId']?.toString() ?? '',
      activityId: json['activityId']?.toString(),
      department: json['department']?.toString() ?? 'OPERATIONS',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      ownerId: json['ownerId']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      resolution: json['resolution']?.toString(),
      closedAt: json['closedAt']?.toString(),
      createdById: json['createdById']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      origin: json['origin']?.toString(),
      checklistTitle: json['checklistTitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'siteId': siteId,
        if (activityId != null) 'activityId': activityId,
        'department': department,
        'title': title,
        'description': description,
        'priority': priority,
        'ownerId': ownerId,
        'dueDate': dueDate,
        'status': status,
        if (resolution != null) 'resolution': resolution,
        if (closedAt != null) 'closedAt': closedAt,
      };

  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isClosed => status.toUpperCase() == 'CLOSED';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';

  /// Formatted status: "Open", "Closed", "In Progress", "Resolved"
  String get formattedStatus {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'Open';
      case 'CLOSED':
        return 'Closed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      default:
        return status;
    }
  }

  /// Formatted priority: "Low", "Medium", "High", "Critical"
  String get formattedPriority {
    final p = priority.toUpperCase();
    if (p == 'MEDIUM') return 'Medium';
    if (p == 'HIGH') return 'High';
    if (p == 'LOW') return 'Low';
    if (p == 'CRITICAL') return 'Critical';
    return priority;
  }

  /// Formatted due date e.g. "30 Oct 2026"
  String get formattedDueDate {
    if (dueDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dueDate);
      final monthName = _kMonths[dt.month - 1];
      return '${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return dueDate;
    }
  }

  /// Formatted department: "Operations"
  String get formattedDepartment {
    if (department.isEmpty) return 'Operations';
    return '${department[0].toUpperCase()}${department.substring(1).toLowerCase()}';
  }

  /// Subtitle: "Manual · Medium" or "Operations · Medium priority"
  String get subtitle {
    final orig = origin != null && origin!.isNotEmpty ? origin! : 'Manual';
    return '$orig · $formattedPriority';
  }
}

/// Detail container with issue and actions
class IssueDetailModel {
  final IssueModel issue;
  final List<IssueActionModel> actions;

  const IssueDetailModel({
    required this.issue,
    this.actions = const [],
  });

  factory IssueDetailModel.fromJson(Map<String, dynamic> json) {
    final issueJson = json['issue'] is Map
        ? Map<String, dynamic>.from(json['issue'] as Map)
        : json;
    final rawActions = json['actions'] as List<dynamic>? ?? [];
    final actionsList = <IssueActionModel>[];
    for (final a in rawActions) {
      if (a is Map) {
        actionsList.add(IssueActionModel.fromJson(Map<String, dynamic>.from(a)));
      }
    }

    return IssueDetailModel(
      issue: IssueModel.fromJson(issueJson),
      actions: actionsList,
    );
  }
}

/// Paginated issues list response
class IssuesResponseModel {
  final List<IssueModel> items;
  final int total;

  const IssuesResponseModel({
    required this.items,
    required this.total,
  });

  factory IssuesResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final list = <IssueModel>[];
    for (final it in rawItems) {
      if (it is Map) {
        list.add(IssueModel.fromJson(Map<String, dynamic>.from(it)));
      }
    }

    return IssuesResponseModel(
      items: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
    );
  }

  static const empty = IssuesResponseModel(items: [], total: 0);
}
