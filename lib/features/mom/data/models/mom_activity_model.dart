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

const _kWeekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// Individual major point item in a MOM.
class MomPointModel {
  final String point;
  final String targetDate;

  const MomPointModel({
    required this.point,
    required this.targetDate,
  });

  factory MomPointModel.fromJson(Map<String, dynamic> json) {
    return MomPointModel(
      point: json['point']?.toString() ?? '',
      targetDate: json['targetDate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'point': point,
        'targetDate': targetDate,
      };

  MomPointModel copyWith({
    String? point,
    String? targetDate,
  }) {
    return MomPointModel(
      point: point ?? this.point,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  /// Formatted target date e.g. "2 Nov 2026 MON" or "30 Oct 2026"
  String formattedTargetDate({bool includeWeekday = true}) {
    if (targetDate.isEmpty) return 'Select date';
    try {
      final dt = DateTime.parse(targetDate);
      final monthName = _kMonths[dt.month - 1];
      if (includeWeekday) {
        final weekdayName = _kWeekdays[dt.weekday - 1];
        return '${dt.day} $monthName ${dt.year} $weekdayName';
      }
      return '${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return targetDate;
    }
  }
}

/// MOM container inside an activity.
class MomDetailInfoModel {
  final List<String> to;
  final List<String> cc;
  final String subject;
  final List<MomPointModel> points;
  final String closing;
  final String? sentAt;
  final String? messageId;

  const MomDetailInfoModel({
    this.to = const [],
    this.cc = const [],
    this.subject = '',
    this.points = const [],
    this.closing = '',
    this.sentAt,
    this.messageId,
  });

  factory MomDetailInfoModel.fromJson(Map<String, dynamic> json) {
    final rawTo = json['to'] as List<dynamic>? ?? [];
    final toList = rawTo.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    final rawCc = json['cc'] as List<dynamic>? ?? [];
    final ccList = rawCc.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final pointsList = <MomPointModel>[];
    for (final p in rawPoints) {
      if (p is Map) {
        pointsList.add(MomPointModel.fromJson(Map<String, dynamic>.from(p)));
      }
    }

    return MomDetailInfoModel(
      to: toList,
      cc: ccList,
      subject: json['subject']?.toString() ?? '',
      points: pointsList,
      closing: json['closing']?.toString() ?? '',
      sentAt: json['sentAt']?.toString(),
      messageId: json['messageId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'to': to,
        'cc': cc,
        'subject': subject,
        'points': points.map((p) => p.toJson()).toList(),
        'closing': closing,
        if (sentAt != null) 'sentAt': sentAt,
        if (messageId != null) 'messageId': messageId,
      };

  bool get isSent => sentAt != null || (to.isNotEmpty && points.isNotEmpty);

  MomDetailInfoModel copyWith({
    List<String>? to,
    List<String>? cc,
    String? subject,
    List<MomPointModel>? points,
    String? closing,
    String? sentAt,
    String? messageId,
  }) {
    return MomDetailInfoModel(
      to: to ?? this.to,
      cc: cc ?? this.cc,
      subject: subject ?? this.subject,
      points: points ?? this.points,
      closing: closing ?? this.closing,
      sentAt: sentAt ?? this.sentAt,
      messageId: messageId ?? this.messageId,
    );
  }
}

/// Full activity model for MOM handling.
class MomActivityModel {
  final String id;
  final String siteId;
  final String siteName;
  final String siteCity;
  final String clusterName;
  final String role;
  final String roleLabel;
  final String kind;
  final String title;
  final String code;
  final String scheduledDate;
  final String dueDate;
  final String? visitDate;
  final String status;
  final String statusLabel;
  final String? assignedToName;
  final MomDetailInfoModel mom;
  final List<dynamic> answers;

  const MomActivityModel({
    required this.id,
    required this.siteId,
    required this.siteName,
    this.siteCity = '',
    this.clusterName = '',
    required this.role,
    required this.roleLabel,
    required this.kind,
    required this.title,
    required this.code,
    required this.scheduledDate,
    required this.dueDate,
    this.visitDate,
    required this.status,
    required this.statusLabel,
    this.assignedToName,
    required this.mom,
    this.answers = const [],
  });

  factory MomActivityModel.fromJson(Map<String, dynamic> json) {
    final rawMom = json['mom'];
    final momInfo = rawMom is Map
        ? MomDetailInfoModel.fromJson(Map<String, dynamic>.from(rawMom))
        : const MomDetailInfoModel();

    return MomActivityModel(
      id: json['id']?.toString() ?? '',
      siteId: json['siteId']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? '',
      siteCity: json['siteCity']?.toString() ?? '',
      clusterName: json['clusterName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      roleLabel: json['roleLabel']?.toString() ?? (json['role']?.toString() ?? ''),
      kind: json['kind']?.toString() ?? 'GOVERNANCE',
      title: json['title']?.toString() ?? 'Governance Visit',
      code: json['code']?.toString() ?? '',
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      visitDate: json['visitDate']?.toString() ?? json['scheduledDate']?.toString(),
      status: json['status']?.toString() ?? 'OPEN',
      statusLabel: json['statusLabel']?.toString() ?? '',
      assignedToName: json['assignedToName']?.toString(),
      mom: momInfo,
      answers: json['answers'] as List<dynamic>? ?? const [],
    );
  }

  /// Whether MOM is completed / sent
  bool get isSent =>
      mom.isSent ||
      statusLabel.toLowerCase() == 'sent' ||
      status.toUpperCase() == 'COMPLETED' && mom.points.isNotEmpty;

  /// Whether MOM is pending
  bool get isPending => !isSent;

  /// Formatted visit date e.g. "30 Oct 2026"
  String get formattedVisitDate {
    final raw = visitDate ?? scheduledDate;
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      final monthName = _kMonths[dt.month - 1];
      return '${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Formatted due date e.g. "6 Nov 2026"
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

  /// Default generated subject string
  String generateDefaultSubject(String siteName) {
    final vDate = formattedVisitDate;
    return 'Site walkaround MOM — $siteName — $vDate';
  }
}

