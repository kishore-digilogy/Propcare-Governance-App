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
  final String id;
  final String point;
  final String status; // 'OPEN' or 'DONE'
  final String? issueId;
  final String department;
  final String targetDate;
  final String? completedAt;

  const MomPointModel({
    this.id = '',
    required this.point,
    this.status = 'OPEN',
    this.issueId,
    this.department = '',
    required this.targetDate,
    this.completedAt,
  });

  bool get isDone =>
      status.toUpperCase() == 'DONE' || status.toUpperCase() == 'COMPLETED';

  factory MomPointModel.fromJson(Map<String, dynamic> json) {
    return MomPointModel(
      id: json['id']?.toString() ?? '',
      point: json['point']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      issueId: json['issueId']?.toString(),
      department: json['department']?.toString() ?? '',
      targetDate: json['targetDate']?.toString() ?? '',
      completedAt: json['completedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'point': point,
        'status': status,
        if (issueId != null) 'issueId': issueId,
        if (department.isNotEmpty) 'department': department,
        'targetDate': targetDate,
        if (completedAt != null) 'completedAt': completedAt,
      };

  MomPointModel copyWith({
    String? id,
    String? point,
    String? status,
    String? issueId,
    String? department,
    String? targetDate,
    String? completedAt,
  }) {
    return MomPointModel(
      id: id ?? this.id,
      point: point ?? this.point,
      status: status ?? this.status,
      issueId: issueId ?? this.issueId,
      department: department ?? this.department,
      targetDate: targetDate ?? this.targetDate,
      completedAt: completedAt ?? this.completedAt,
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
  final String body;
  final String meetingAttendees;
  final String clientAttendees;
  final List<MomPointModel> points;
  final String closing;
  final String? sentAt;
  final String? messageId;

  const MomDetailInfoModel({
    this.to = const [],
    this.cc = const [],
    this.subject = '',
    this.body = '',
    this.meetingAttendees = '',
    this.clientAttendees = '',
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
      body: json['body']?.toString() ?? '',
      meetingAttendees: json['meetingAttendees']?.toString() ?? '',
      clientAttendees: json['clientAttendees']?.toString() ?? '',
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
        if (body.isNotEmpty) 'body': body,
        if (meetingAttendees.isNotEmpty) 'meetingAttendees': meetingAttendees,
        if (clientAttendees.isNotEmpty) 'clientAttendees': clientAttendees,
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
    String? body,
    String? meetingAttendees,
    String? clientAttendees,
    List<MomPointModel>? points,
    String? closing,
    String? sentAt,
    String? messageId,
  }) {
    return MomDetailInfoModel(
      to: to ?? this.to,
      cc: cc ?? this.cc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      meetingAttendees: meetingAttendees ?? this.meetingAttendees,
      clientAttendees: clientAttendees ?? this.clientAttendees,
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
  final String siteCode;
  final String siteCity;
  final String zoneName;
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
  final String frequencyLabel;
  final String priority;
  final String clientType;
  final MomDetailInfoModel mom;
  final List<dynamic> answers;

  const MomActivityModel({
    required this.id,
    required this.siteId,
    required this.siteName,
    this.siteCode = '',
    this.siteCity = '',
    this.zoneName = '',
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
    this.frequencyLabel = 'Quarterly',
    this.priority = 'Medium',
    this.clientType = 'A',
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
      siteCode: json['siteCode']?.toString() ?? '',
      siteCity: json['siteCity']?.toString() ?? '',
      zoneName: json['zoneName']?.toString() ?? '',
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
      frequencyLabel: json['frequencyLabel']?.toString() ??
          (json['frequency'] is Map
              ? (json['frequency']['count'] == 3 ? 'Quarterly' : 'Monthly')
              : 'Quarterly'),
      priority: json['priority']?.toString() ?? 'Medium',
      clientType: json['siteClientType']?.toString() ?? json['clientType']?.toString() ?? 'A',
      mom: momInfo,
      answers: json['answers'] as List<dynamic>? ?? const [],
    );
  }

  int get totalPoints => mom.points.length;
  int get completedPoints => mom.points.where((p) => p.isDone).length;
  int get pendingPoints => mom.points.where((p) => !p.isDone).length;

  /// Whether MOM is completed / sent
  bool get isSent =>
      mom.sentAt != null ||
      mom.isSent ||
      statusLabel.toLowerCase() == 'sent' ||
      status.toUpperCase() == 'COMPLETED';

  /// Whether MOM is pending
  bool get isPending => !isSent;

  /// Formatted sent at string e.g. "25 Nov 2026, 10:49 Am"
  String get formattedSentAt {
    if (mom.sentAt == null || mom.sentAt!.isEmpty) return '';
    try {
      final dt = DateTime.parse(mom.sentAt!).toLocal();
      final monthName = _kMonths[dt.month - 1];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'Pm' : 'Am';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $monthName ${dt.year}, $hour:$minute $amPm';
    } catch (_) {
      return mom.sentAt!;
    }
  }

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
    return 'Site walkaround MOM - $siteName - $vDate';
  }

  MomActivityModel copyWith({
    String? id,
    String? siteId,
    String? siteName,
    String? siteCode,
    String? siteCity,
    String? zoneName,
    String? clusterName,
    String? role,
    String? roleLabel,
    String? kind,
    String? title,
    String? code,
    String? scheduledDate,
    String? dueDate,
    String? visitDate,
    String? status,
    String? statusLabel,
    String? assignedToName,
    String? frequencyLabel,
    String? priority,
    String? clientType,
    MomDetailInfoModel? mom,
    List<dynamic>? answers,
  }) {
    return MomActivityModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      siteCode: siteCode ?? this.siteCode,
      siteCity: siteCity ?? this.siteCity,
      zoneName: zoneName ?? this.zoneName,
      clusterName: clusterName ?? this.clusterName,
      role: role ?? this.role,
      roleLabel: roleLabel ?? this.roleLabel,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      code: code ?? this.code,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      dueDate: dueDate ?? this.dueDate,
      visitDate: visitDate ?? this.visitDate,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      assignedToName: assignedToName ?? this.assignedToName,
      frequencyLabel: frequencyLabel ?? this.frequencyLabel,
      priority: priority ?? this.priority,
      clientType: clientType ?? this.clientType,
      mom: mom ?? this.mom,
      answers: answers ?? this.answers,
    );
  }
}
