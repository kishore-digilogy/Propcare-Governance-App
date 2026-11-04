import 'dart:developer' as developer;

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

/// Check-in / check-out geolocation and timestamp data.
class GeoPointInfo {
  final String? capturedAt;
  final String? verifiedAt;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? distanceMeters;

  const GeoPointInfo({
    this.capturedAt,
    this.verifiedAt,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.distanceMeters,
  });

  factory GeoPointInfo.fromJson(Map<String, dynamic> json) {
    return GeoPointInfo(
      capturedAt: json['capturedAt']?.toString(),
      verifiedAt: json['verifiedAt']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }
}

/// Geolocation container for an activity.
class ActivityGeoModel {
  final GeoPointInfo? checkIn;
  final GeoPointInfo? checkOut;
  final String? checkInAt;
  final String? checkOutAt;
  final String? attendanceMarkedAt;
  final double? latitude;
  final double? longitude;
  final double? accuracy;

  const ActivityGeoModel({
    this.checkIn,
    this.checkOut,
    this.checkInAt,
    this.checkOutAt,
    this.attendanceMarkedAt,
    this.latitude,
    this.longitude,
    this.accuracy,
  });

  factory ActivityGeoModel.fromJson(Map<String, dynamic> json) {
    GeoPointInfo? checkIn;
    if (json['checkIn'] is Map) {
      checkIn = GeoPointInfo.fromJson(Map<String, dynamic>.from(json['checkIn'] as Map));
    } else if (json['latitude'] != null && json['checkInAt'] != null) {
      checkIn = GeoPointInfo.fromJson(json);
    }

    GeoPointInfo? checkOut;
    if (json['checkOut'] is Map) {
      checkOut = GeoPointInfo.fromJson(Map<String, dynamic>.from(json['checkOut'] as Map));
    }

    return ActivityGeoModel(
      checkIn: checkIn,
      checkOut: checkOut,
      checkInAt: json['checkInAt']?.toString() ?? checkIn?.capturedAt ?? checkIn?.verifiedAt,
      checkOutAt: json['checkOutAt']?.toString() ?? checkOut?.capturedAt ?? checkOut?.verifiedAt,
      attendanceMarkedAt: json['attendanceMarkedAt']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }

  bool get hasCheckedIn =>
      checkIn != null ||
      (checkInAt != null && checkInAt!.isNotEmpty) ||
      (attendanceMarkedAt != null && attendanceMarkedAt!.isNotEmpty);

  bool get hasCheckedOut =>
      checkOut != null || (checkOutAt != null && checkOutAt!.isNotEmpty);

  bool get isOnSite => hasCheckedIn && !hasCheckedOut;
}

/// An individual checklist question or item in an activity visit.
class ActivityChecklistItem {
  final String key;
  final String title;
  final String section;
  final int sortOrder;

  const ActivityChecklistItem({
    required this.key,
    required this.title,
    required this.section,
    this.sortOrder = 0,
  });

  factory ActivityChecklistItem.fromJson(Map<String, dynamic> json) {
    return ActivityChecklistItem(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// An answer recorded for a checklist item.
class ActivityAnswerItem {
  final String key;
  final String title;
  final String status; // 'OK', 'NOT_OK', 'NA'
  final String remarks;

  const ActivityAnswerItem({
    required this.key,
    required this.title,
    required this.status,
    this.remarks = '',
  });

  factory ActivityAnswerItem.fromJson(Map<String, dynamic> json) {
    return ActivityAnswerItem(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OK',
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  bool get isOk => status.toUpperCase() == 'OK';
  bool get isNotOk => status.toUpperCase() == 'NOT_OK';
  bool get isNa => status.toUpperCase() == 'NA';
}

/// Individual activity visit item (e.g. Field Executive Visit, Cluster Lead Visit).
class ActivityVisitModel {
  final String id;
  final String siteId;
  final String role;
  final String kind;
  final String title;
  final String? assignedToId;
  final String scheduledDate;
  final String dueDate;
  final String status;
  final String clientType;
  final String code;
  final String? assignedToName;
  final String siteName;
  final String siteCity;
  final String siteClientType;
  final String clusterName;
  final String functionLabel;
  final String roleLabel;
  final String frequencyLabel;
  final String priority;
  final String statusLabel;
  final ActivityGeoModel geo;
  final String? completedAt;
  final String? visitDate;
  final String? completionNote;
  final List<ActivityChecklistItem> template;
  final List<ActivityAnswerItem> answers;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> mom;

  const ActivityVisitModel({
    required this.id,
    required this.siteId,
    required this.role,
    required this.kind,
    required this.title,
    this.assignedToId,
    required this.scheduledDate,
    required this.dueDate,
    required this.status,
    required this.clientType,
    required this.code,
    this.assignedToName,
    required this.siteName,
    required this.siteCity,
    required this.siteClientType,
    required this.clusterName,
    required this.functionLabel,
    required this.roleLabel,
    required this.frequencyLabel,
    required this.priority,
    required this.statusLabel,
    required this.geo,
    this.completedAt,
    this.visitDate,
    this.completionNote,
    this.template = const [],
    this.answers = const [],
    this.requirements = const {},
    this.mom = const {},
  });

  factory ActivityVisitModel.fromJson(Map<String, dynamic> json) {
    return ActivityVisitModel(
      id: json['id']?.toString() ?? '',
      siteId: json['siteId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      assignedToId: json['assignedToId']?.toString(),
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      clientType: json['clientType']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      assignedToName: json['assignedToName']?.toString(),
      siteName: json['siteName']?.toString() ?? '',
      siteCity: json['siteCity']?.toString() ?? '',
      siteClientType: json['siteClientType']?.toString() ?? '',
      clusterName: json['clusterName']?.toString() ?? '',
      functionLabel: json['functionLabel']?.toString() ?? '',
      roleLabel: json['roleLabel']?.toString() ?? '',
      frequencyLabel: json['frequencyLabel']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      statusLabel: json['statusLabel']?.toString() ?? '',
      geo: json['geo'] is Map
          ? ActivityGeoModel.fromJson(Map<String, dynamic>.from(json['geo'] as Map))
          : const ActivityGeoModel(),
      completedAt: json['completedAt']?.toString(),
      visitDate: json['visitDate']?.toString(),
      completionNote: json['completionNote']?.toString(),
      template: (json['template'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((m) => ActivityChecklistItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      answers: (json['answers'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((m) => ActivityAnswerItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      requirements: json['requirements'] is Map
          ? Map<String, dynamic>.from(json['requirements'] as Map)
          : const {},
      mom: json['mom'] is Map
          ? Map<String, dynamic>.from(json['mom'] as Map)
          : const {},
    );
  }

  bool get isCompleted =>
      status.toUpperCase() == 'COMPLETED' || geo.hasCheckedOut;

  bool get isOnSite => geo.isOnSite;

  /// Formatted due date, e.g. "6 Nov 2026"
  String get formattedDueDate {
    if (dueDate.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(dueDate);
      final monthName = _kMonths[parsed.month - 1];
      return '${parsed.day} $monthName ${parsed.year}';
    } catch (_) {
      return dueDate;
    }
  }

  /// Formatted check-in timestamp, e.g. "30 Oct, 12:13 pm In"
  String get formattedCheckIn {
    final raw = geo.checkIn?.capturedAt ?? geo.checkInAt;
    if (raw == null || raw.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(raw).toLocal();
      return '${_formatDateTime(parsed)} In';
    } catch (_) {
      return '—';
    }
  }

  /// Formatted check-out timestamp, e.g. "30 Oct, 12:04 pm Out"
  String get formattedCheckOut {
    final raw = geo.checkOut?.capturedAt ?? geo.checkOutAt;
    if (raw == null || raw.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(raw).toLocal();
      return '${_formatDateTime(parsed)} Out';
    } catch (_) {
      return '—';
    }
  }

  static String _formatDateTime(DateTime dt) {
    final monthName = _kMonths[dt.month - 1];
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'pm' : 'am';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${dt.day} $monthName, $hour12:$minute $amPm';
  }

  /// Calculates duration between checkIn and checkOut
  String get formattedDuration {
    if (isOnSite) return 'On site';

    final inRaw = geo.checkIn?.capturedAt ?? geo.checkInAt;
    final outRaw = geo.checkOut?.capturedAt ?? geo.checkOutAt;
    if (inRaw == null || outRaw == null) return '—';

    try {
      final inTime = DateTime.parse(inRaw);
      final outTime = DateTime.parse(outRaw);
      final diff = outTime.difference(inTime);

      if (diff.isNegative) return '—';
      if (diff.inSeconds < 60) return '${diff.inSeconds}s';
      if (diff.inMinutes < 60) {
        final sec = diff.inSeconds % 60;
        return sec > 0 ? '${diff.inMinutes}m ${sec}s' : '${diff.inMinutes}m';
      }
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } catch (_) {
      return '—';
    }
  }

  /// Merges updated fields from a check-in/check-out response while preserving
  /// any enriched display metadata (code, siteName, roleLabel, etc.).
  ActivityVisitModel mergeWithUpdated(ActivityVisitModel updated) {
    return ActivityVisitModel(
      id: updated.id.isNotEmpty ? updated.id : id,
      siteId: updated.siteId.isNotEmpty ? updated.siteId : siteId,
      role: updated.role.isNotEmpty ? updated.role : role,
      kind: updated.kind.isNotEmpty ? updated.kind : kind,
      title: updated.title.isNotEmpty ? updated.title : title,
      assignedToId: updated.assignedToId ?? assignedToId,
      scheduledDate: updated.scheduledDate.isNotEmpty ? updated.scheduledDate : scheduledDate,
      dueDate: updated.dueDate.isNotEmpty ? updated.dueDate : dueDate,
      status: updated.status.isNotEmpty ? updated.status : status,
      clientType: updated.clientType.isNotEmpty ? updated.clientType : clientType,
      code: updated.code.isNotEmpty ? updated.code : code,
      assignedToName: updated.assignedToName ?? assignedToName,
      siteName: updated.siteName.isNotEmpty ? updated.siteName : siteName,
      siteCity: updated.siteCity.isNotEmpty ? updated.siteCity : siteCity,
      siteClientType: updated.siteClientType.isNotEmpty ? updated.siteClientType : siteClientType,
      clusterName: updated.clusterName.isNotEmpty ? updated.clusterName : clusterName,
      functionLabel: updated.functionLabel.isNotEmpty ? updated.functionLabel : functionLabel,
      roleLabel: updated.roleLabel.isNotEmpty ? updated.roleLabel : roleLabel,
      frequencyLabel: updated.frequencyLabel.isNotEmpty ? updated.frequencyLabel : frequencyLabel,
      priority: updated.priority.isNotEmpty ? updated.priority : priority,
      statusLabel: updated.statusLabel.isNotEmpty ? updated.statusLabel : statusLabel,
      geo: updated.geo,
      completedAt: updated.completedAt ?? completedAt,
      visitDate: updated.visitDate ?? visitDate,
      completionNote: updated.completionNote ?? completionNote,
      template: updated.template.isNotEmpty ? updated.template : template,
      answers: updated.answers.isNotEmpty ? updated.answers : answers,
      requirements: updated.requirements.isNotEmpty ? updated.requirements : requirements,
      mom: updated.mom.isNotEmpty ? updated.mom : mom,
    );
  }

  ActivityVisitModel copyWith({
    String? id,
    String? siteId,
    String? role,
    String? kind,
    String? title,
    String? assignedToId,
    String? scheduledDate,
    String? dueDate,
    String? status,
    String? clientType,
    String? code,
    String? assignedToName,
    String? siteName,
    String? siteCity,
    String? siteClientType,
    String? clusterName,
    String? functionLabel,
    String? roleLabel,
    String? frequencyLabel,
    String? priority,
    String? statusLabel,
    ActivityGeoModel? geo,
    String? completedAt,
    String? visitDate,
    String? completionNote,
    List<ActivityChecklistItem>? template,
    List<ActivityAnswerItem>? answers,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? mom,
  }) {
    return ActivityVisitModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      role: role ?? this.role,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      assignedToId: assignedToId ?? this.assignedToId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      clientType: clientType ?? this.clientType,
      code: code ?? this.code,
      assignedToName: assignedToName ?? this.assignedToName,
      siteName: siteName ?? this.siteName,
      siteCity: siteCity ?? this.siteCity,
      siteClientType: siteClientType ?? this.siteClientType,
      clusterName: clusterName ?? this.clusterName,
      functionLabel: functionLabel ?? this.functionLabel,
      roleLabel: roleLabel ?? this.roleLabel,
      frequencyLabel: frequencyLabel ?? this.frequencyLabel,
      priority: priority ?? this.priority,
      statusLabel: statusLabel ?? this.statusLabel,
      geo: geo ?? this.geo,
      completedAt: completedAt ?? this.completedAt,
      visitDate: visitDate ?? this.visitDate,
      completionNote: completionNote ?? this.completionNote,
      template: template ?? this.template,
      answers: answers ?? this.answers,
      requirements: requirements ?? this.requirements,
      mom: mom ?? this.mom,
    );
  }
}

/// Root response model for GET /activities?kind=GOVERNANCE&siteId=...
class SiteActivitiesResponseModel {
  final List<ActivityVisitModel> items;
  final int total;
  final int limit;
  final int offset;
  final int pending;
  final int completed;

  const SiteActivitiesResponseModel({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.pending,
    required this.completed,
  });

  static const empty = SiteActivitiesResponseModel(
    items: [],
    total: 0,
    limit: 100,
    offset: 0,
    pending: 0,
    completed: 0,
  );

  factory SiteActivitiesResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = <ActivityVisitModel>[];
    for (final raw in rawItems) {
      if (raw is Map) {
        try {
          parsedItems.add(
            ActivityVisitModel.fromJson(Map<String, dynamic>.from(raw)),
          );
        } catch (e, st) {
          developer.log('Failed to parse ActivityVisitModel: $e', error: e, stackTrace: st);
        }
      }
    }

    int pending = 0;
    int completed = 0;

    // Read counts from counts map if present, or count from items
    if (json['counts'] is Map) {
      final counts = Map<String, dynamic>.from(json['counts'] as Map);
      pending = (counts['pending'] as num?)?.toInt() ?? 0;
      completed = (counts['completed'] as num?)?.toInt() ?? 0;
    } else {
      pending = (json['pending'] as num?)?.toInt() ?? 0;
      completed = (json['completed'] as num?)?.toInt() ?? 0;
    }

    if (pending == 0 && completed == 0 && parsedItems.isNotEmpty) {
      for (final item in parsedItems) {
        if (item.isCompleted) {
          completed++;
        } else {
          pending++;
        }
      }
    }

    return SiteActivitiesResponseModel(
      items: parsedItems,
      total: (json['total'] as num?)?.toInt() ?? parsedItems.length,
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      pending: pending,
      completed: completed,
    );
  }

  SiteActivitiesResponseModel copyWith({
    List<ActivityVisitModel>? items,
    int? total,
    int? limit,
    int? offset,
    int? pending,
    int? completed,
  }) {
    return SiteActivitiesResponseModel(
      items: items ?? this.items,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
    );
  }

  /// Updates an activity and recalculates pending/completed counts.
  SiteActivitiesResponseModel updateActivity(ActivityVisitModel updated) {
    final newItems = items.map((item) {
      if (item.id == updated.id) {
        return item.mergeWithUpdated(updated);
      }
      return item;
    }).toList();

    int newCompleted = 0;
    int newPending = 0;
    for (final item in newItems) {
      if (item.isCompleted) {
        newCompleted++;
      } else {
        newPending++;
      }
    }

    return copyWith(
      items: newItems,
      completed: newCompleted,
      pending: newPending,
    );
  }
}
