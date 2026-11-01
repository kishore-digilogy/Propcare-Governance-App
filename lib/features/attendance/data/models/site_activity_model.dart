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

  const ActivityGeoModel({
    this.checkIn,
    this.checkOut,
    this.checkInAt,
    this.checkOutAt,
    this.attendanceMarkedAt,
  });

  factory ActivityGeoModel.fromJson(Map<String, dynamic> json) {
    return ActivityGeoModel(
      checkIn: json['checkIn'] is Map<String, dynamic>
          ? GeoPointInfo.fromJson(json['checkIn'] as Map<String, dynamic>)
          : null,
      checkOut: json['checkOut'] is Map<String, dynamic>
          ? GeoPointInfo.fromJson(json['checkOut'] as Map<String, dynamic>)
          : null,
      checkInAt: json['checkInAt']?.toString(),
      checkOutAt: json['checkOutAt']?.toString(),
      attendanceMarkedAt: json['attendanceMarkedAt']?.toString(),
    );
  }

  bool get hasCheckedIn => checkIn != null || checkInAt != null;
  bool get hasCheckedOut => checkOut != null || checkOutAt != null;
  bool get isOnSite => hasCheckedIn && !hasCheckedOut;
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
      geo: json['geo'] is Map<String, dynamic>
          ? ActivityGeoModel.fromJson(json['geo'] as Map<String, dynamic>)
          : const ActivityGeoModel(),
      completedAt: json['completedAt']?.toString(),
      visitDate: json['visitDate']?.toString(),
      completionNote: json['completionNote']?.toString(),
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
    final parsedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map(ActivityVisitModel.fromJson)
        .toList();

    int pending = 0;
    int completed = 0;

    // Read counts from counts map if present, or count from items
    if (json['counts'] is Map<String, dynamic>) {
      final counts = json['counts'] as Map<String, dynamic>;
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
}
