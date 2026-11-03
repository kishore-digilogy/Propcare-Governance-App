import 'package:equatable/equatable.dart';

class EmailRecipientModel extends Equatable {
  final String value;
  final String label;
  final String name;
  final String role;

  const EmailRecipientModel({
    required this.value,
    required this.label,
    required this.name,
    required this.role,
  });

  factory EmailRecipientModel.fromJson(Map<String, dynamic> json) {
    return EmailRecipientModel(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? (json['value']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'name': name,
        'role': role,
      };

  @override
  List<Object?> get props => [value, label, name, role];
}

class ActivityItemDetailModel extends Equatable {
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
  final String statusLabel;
  final String clientType;
  final String code;
  final String functionLabel;
  final String roleLabel;
  final String frequencyLabel;
  final String priority;
  final String? visitDate;
  final bool? clientMet;
  final String? completionNote;
  final String? completedById;
  final String? completedAt;
  final Map<String, dynamic> mom;
  final Map<String, dynamic> requirements;

  const ActivityItemDetailModel({
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
    required this.statusLabel,
    required this.clientType,
    required this.code,
    required this.functionLabel,
    required this.roleLabel,
    required this.frequencyLabel,
    required this.priority,
    this.visitDate,
    this.clientMet,
    this.completionNote,
    this.completedById,
    this.completedAt,
    this.mom = const {},
    this.requirements = const {},
  });

  bool get isCompleted =>
      status.toUpperCase() == 'COMPLETED' ||
      completedAt != null ||
      statusLabel.toLowerCase().contains('mom');

  bool get isMomSent =>
      mom['sentAt'] != null ||
      status.toUpperCase() == 'CLOSED' ||
      statusLabel.toLowerCase().contains('closed') ||
      statusLabel.toLowerCase().contains('completed');

  factory ActivityItemDetailModel.fromJson(Map<String, dynamic> json) {
    // Parse clientMet from completionNote if not directly present
    bool? clientMetParsed;
    final note = json['completionNote']?.toString() ?? '';
    if (json.containsKey('clientMet') && json['clientMet'] is bool) {
      clientMetParsed = json['clientMet'] as bool;
    } else if (note.contains('Client met: Yes')) {
      clientMetParsed = true;
    } else if (note.contains('Client met: No')) {
      clientMetParsed = false;
    }

    return ActivityItemDetailModel(
      id: json['id']?.toString() ?? '',
      siteId: json['siteId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'GOVERNANCE',
      title: json['title']?.toString() ?? 'Governance Visit',
      assignedToId: json['assignedToId']?.toString(),
      assignedToName: json['assignedToName']?.toString(),
      scheduledDate: json['scheduledDate']?.toString(),
      dueDate: json['dueDate']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      statusLabel: json['statusLabel']?.toString() ??
          (json['status']?.toString().toUpperCase() == 'COMPLETED' ? 'Completed' : 'Scheduled'),
      clientType: json['clientType']?.toString() ?? 'A',
      code: json['code']?.toString() ?? 'ACT-00000',
      functionLabel: json['functionLabel']?.toString() ?? 'CRRM',
      roleLabel: json['roleLabel']?.toString() ?? 'CRRM / Super Admin',
      frequencyLabel: json['frequencyLabel']?.toString() ?? 'Quarterly',
      priority: json['priority']?.toString() ?? 'Medium',
      visitDate: json['visitDate']?.toString(),
      clientMet: clientMetParsed,
      completionNote: json['completionNote']?.toString(),
      completedById: json['completedById']?.toString(),
      completedAt: json['completedAt']?.toString(),
      mom: json['mom'] is Map ? Map<String, dynamic>.from(json['mom'] as Map) : const {},
      requirements: json['requirements'] is Map
          ? Map<String, dynamic>.from(json['requirements'] as Map)
          : const {},
    );
  }

  ActivityItemDetailModel copyWith({
    String? status,
    String? statusLabel,
    String? visitDate,
    bool? clientMet,
    String? completionNote,
    String? completedById,
    String? completedAt,
    Map<String, dynamic>? mom,
  }) {
    return ActivityItemDetailModel(
      id: id,
      siteId: siteId,
      role: role,
      kind: kind,
      title: title,
      assignedToId: assignedToId,
      assignedToName: assignedToName,
      scheduledDate: scheduledDate,
      dueDate: dueDate,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      clientType: clientType,
      code: code,
      functionLabel: functionLabel,
      roleLabel: roleLabel,
      frequencyLabel: frequencyLabel,
      priority: priority,
      visitDate: visitDate ?? this.visitDate,
      clientMet: clientMet ?? this.clientMet,
      completionNote: completionNote ?? this.completionNote,
      completedById: completedById ?? this.completedById,
      completedAt: completedAt ?? this.completedAt,
      mom: mom ?? this.mom,
      requirements: requirements,
    );
  }

  @override
  List<Object?> get props => [
        id,
        siteId,
        role,
        title,
        status,
        statusLabel,
        code,
        visitDate,
        clientMet,
        completionNote,
        completedAt,
        mom,
      ];
}

class ActivitySiteDetailModel extends Equatable {
  final String id;
  final String name;
  final String code;
  final String clientName;
  final String? clientGroupId;
  final String? clientEmail;
  final String? contactPersonName;
  final String? contactPhone;
  final String city;
  final String state;
  final String? zoneId;
  final String? groupId;
  final String? clusterId;
  final String status;
  final List<EmailRecipientModel> contactEmails;
  final List<EmailRecipientModel> ccEmails;

  const ActivitySiteDetailModel({
    required this.id,
    required this.name,
    required this.code,
    required this.clientName,
    this.clientGroupId,
    this.clientEmail,
    this.contactPersonName,
    this.contactPhone,
    required this.city,
    required this.state,
    this.zoneId,
    this.groupId,
    this.clusterId,
    required this.status,
    this.contactEmails = const [],
    this.ccEmails = const [],
  });

  factory ActivitySiteDetailModel.fromJson(Map<String, dynamic> json) {
    final contacts = <EmailRecipientModel>[];
    if (json['contactEmails'] is List) {
      for (final c in json['contactEmails'] as List) {
        if (c is Map) {
          contacts.add(EmailRecipientModel.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    // Fallback if contactEmails empty but clientEmail present
    if (contacts.isEmpty && json['clientEmail'] != null && json['clientEmail'].toString().isNotEmpty) {
      contacts.add(EmailRecipientModel(
        value: json['clientEmail'].toString(),
        label: '${json['contactPersonName'] ?? json['clientName'] ?? 'Client'} · ${json['clientEmail']}',
        name: json['contactPersonName']?.toString() ?? '',
        role: 'CLIENT',
      ));
    }

    final ccs = <EmailRecipientModel>[];
    if (json['ccEmails'] is List) {
      for (final c in json['ccEmails'] as List) {
        if (c is Map) {
          ccs.add(EmailRecipientModel.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    return ActivitySiteDetailModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? (json['name']?.toString() ?? ''),
      clientGroupId: json['clientGroupId']?.toString(),
      clientEmail: json['clientEmail']?.toString(),
      contactPersonName: json['contactPersonName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      city: json['city']?.toString() ?? 'NA',
      state: json['state']?.toString() ?? 'NA',
      zoneId: json['zoneId']?.toString(),
      groupId: json['groupId']?.toString(),
      clusterId: json['clusterId']?.toString(),
      status: json['status']?.toString() ?? 'LIVE',
      contactEmails: contacts,
      ccEmails: ccs,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        clientName,
        clientEmail,
        contactPersonName,
        zoneId,
        contactEmails,
        ccEmails,
      ];
}

class ActivityDetailModel extends Equatable {
  final ActivityItemDetailModel activity;
  final ActivitySiteDetailModel site;
  final List<dynamic> approvals;
  final List<dynamic> openItems;

  const ActivityDetailModel({
    required this.activity,
    required this.site,
    this.approvals = const [],
    this.openItems = const [],
  });

  factory ActivityDetailModel.fromJson(Map<String, dynamic> json) {
    return ActivityDetailModel(
      activity: ActivityItemDetailModel.fromJson(
        json['activity'] is Map ? Map<String, dynamic>.from(json['activity'] as Map) : const {},
      ),
      site: ActivitySiteDetailModel.fromJson(
        json['site'] is Map ? Map<String, dynamic>.from(json['site'] as Map) : const {},
      ),
      approvals: json['approvals'] is List ? List.from(json['approvals'] as List) : const [],
      openItems: json['openItems'] is List ? List.from(json['openItems'] as List) : const [],
    );
  }

  ActivityDetailModel copyWith({
    ActivityItemDetailModel? activity,
    ActivitySiteDetailModel? site,
    List<dynamic>? approvals,
    List<dynamic>? openItems,
  }) {
    return ActivityDetailModel(
      activity: activity ?? this.activity,
      site: site ?? this.site,
      approvals: approvals ?? this.approvals,
      openItems: openItems ?? this.openItems,
    );
  }

  @override
  List<Object?> get props => [activity, site, approvals, openItems];
}

