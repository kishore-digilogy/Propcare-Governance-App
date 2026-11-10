import 'package:equatable/equatable.dart';

/// Response model for GET /api/activities/checklist-by-site
class ChecklistReportResponseModel extends Equatable {
  final List<ChecklistReportItemModel> items;
  final int pending;
  final int completed;
  final int activities;
  final int sites;

  const ChecklistReportResponseModel({
    required this.items,
    this.pending = 0,
    this.completed = 0,
    this.activities = 0,
    this.sites = 0,
  });

  int get allCount => completed + pending;

  factory ChecklistReportResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((e) => ChecklistReportItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ChecklistReportResponseModel(
      items: itemsList,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      activities: (json['activities'] as num?)?.toInt() ?? itemsList.length,
      sites: (json['sites'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'pending': pending,
        'completed': completed,
        'activities': activities,
        'sites': sites,
      };

  @override
  List<Object?> get props => [items, pending, completed, activities, sites];
}

/// Represents an item in the Checklist Report summary list
class ChecklistReportItemModel extends Equatable {
  final String id;
  final String siteId;
  final String siteName;
  final String siteCity;
  final String siteClientType;
  final String zoneName;
  final String clusterName;
  final String siteStatus;
  final String activityLabel;
  final String role;
  final String roleLabel;
  final String frequencyLabel;
  final String visitDate;
  final int pending;
  final int completed;

  const ChecklistReportItemModel({
    required this.id,
    required this.siteId,
    required this.siteName,
    this.siteCity = '',
    this.siteClientType = '',
    this.zoneName = '',
    this.clusterName = '',
    this.siteStatus = '',
    this.activityLabel = '',
    this.role = '',
    this.roleLabel = '',
    this.frequencyLabel = '',
    this.visitDate = '',
    this.pending = 0,
    this.completed = 0,
  });

  int get total => pending + completed;

  factory ChecklistReportItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistReportItemModel(
      id: json['id']?.toString() ?? '',
      siteId: json['siteId']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? '',
      siteCity: json['siteCity']?.toString() ?? '',
      siteClientType: json['siteClientType']?.toString() ?? '',
      zoneName: json['zoneName']?.toString() ?? '',
      clusterName: json['clusterName']?.toString() ?? '',
      siteStatus: json['siteStatus']?.toString() ?? '',
      activityLabel: json['activityLabel']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      roleLabel: json['roleLabel']?.toString() ?? '',
      frequencyLabel: json['frequencyLabel']?.toString() ?? '',
      visitDate: json['visitDate']?.toString() ?? '',
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'siteId': siteId,
        'siteName': siteName,
        'siteCity': siteCity,
        'siteClientType': siteClientType,
        'zoneName': zoneName,
        'clusterName': clusterName,
        'siteStatus': siteStatus,
        'activityLabel': activityLabel,
        'role': role,
        'roleLabel': roleLabel,
        'frequencyLabel': frequencyLabel,
        'visitDate': visitDate,
        'pending': pending,
        'completed': completed,
      };

  @override
  List<Object?> get props => [
        id,
        siteId,
        siteName,
        siteCity,
        siteClientType,
        zoneName,
        clusterName,
        siteStatus,
        activityLabel,
        role,
        roleLabel,
        frequencyLabel,
        visitDate,
        pending,
        completed,
      ];
}

/// Response model for GET /api/activities/checklist-by-site/{siteId}
class SiteChecklistDetailResponseModel extends Equatable {
  final String siteId;
  final String siteName;
  final String siteClientType;
  final int pending;
  final List<SiteChecklistActivityItemModel> items;

  const SiteChecklistDetailResponseModel({
    required this.siteId,
    required this.siteName,
    this.siteClientType = '',
    this.pending = 0,
    required this.items,
  });

  factory SiteChecklistDetailResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return SiteChecklistDetailResponseModel(
      siteId: json['siteId']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? '',
      siteClientType: json['siteClientType']?.toString() ?? '',
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      items: rawItems
          .map((e) =>
              SiteChecklistActivityItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'siteId': siteId,
        'siteName': siteName,
        'siteClientType': siteClientType,
        'pending': pending,
        'items': items.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [siteId, siteName, siteClientType, pending, items];
}

/// A specific activity visit under a site's checklist report
class SiteChecklistActivityItemModel extends Equatable {
  final String id;
  final String title;
  final String role;
  final String roleLabel;
  final String visitDate;
  final String scheduledDate;
  final String dueDate;
  final String code;
  final String clientType;
  final String status;
  final String frequencyLabel;
  final int pending;
  final int completed;
  final String? spoc;
  final String? mom;
  final List<ChecklistTemplateItemModel> template;
  final List<ChecklistAnswerItemModel> answers;

  const SiteChecklistActivityItemModel({
    required this.id,
    this.title = '',
    this.role = '',
    this.roleLabel = '',
    this.visitDate = '',
    this.scheduledDate = '',
    this.dueDate = '',
    this.code = '',
    this.clientType = '',
    this.status = '',
    this.frequencyLabel = '',
    this.pending = 0,
    this.completed = 0,
    this.spoc,
    this.mom,
    this.template = const [],
    this.answers = const [],
  });

  factory SiteChecklistActivityItemModel.fromJson(Map<String, dynamic> json) {
    final rawTemplate = json['template'] as List<dynamic>? ?? [];
    final rawAnswers = json['answers'] as List<dynamic>? ?? [];

    String freqLabel = json['frequencyLabel']?.toString() ?? '';
    if (freqLabel.isEmpty && json['frequency'] is Map) {
      final freqMap = json['frequency'] as Map<String, dynamic>;
      final unit = freqMap['unit']?.toString() ?? '';
      final count = freqMap['count']?.toString() ?? '';
      freqLabel = unit.isNotEmpty ? '$count $unit' : '';
    }

    return SiteChecklistActivityItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      roleLabel: json['roleLabel']?.toString() ?? json['role']?.toString() ?? '',
      visitDate: json['visitDate']?.toString() ?? '',
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      clientType: json['clientType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      frequencyLabel: freqLabel,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      spoc: json['spoc']?.toString() ?? json['assignedToName']?.toString(),
      mom: json['momStatus']?.toString() ?? (json['mom'] is Map && (json['mom'] as Map).isNotEmpty ? 'Sent' : 'Pending'),
      template: rawTemplate
          .map((e) => ChecklistTemplateItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      answers: rawAnswers
          .map((e) => ChecklistAnswerItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'role': role,
        'roleLabel': roleLabel,
        'visitDate': visitDate,
        'scheduledDate': scheduledDate,
        'dueDate': dueDate,
        'code': code,
        'clientType': clientType,
        'status': status,
        'frequencyLabel': frequencyLabel,
        'pending': pending,
        'completed': completed,
        'spoc': spoc,
        'mom': mom,
        'template': template.map((e) => e.toJson()).toList(),
        'answers': answers.map((e) => e.toJson()).toList(),
      };

  SiteChecklistActivityItemModel copyWith({
    String? id,
    String? title,
    String? role,
    String? roleLabel,
    String? visitDate,
    String? scheduledDate,
    String? dueDate,
    String? code,
    String? clientType,
    String? status,
    String? frequencyLabel,
    int? pending,
    int? completed,
    String? spoc,
    String? mom,
    List<ChecklistTemplateItemModel>? template,
    List<ChecklistAnswerItemModel>? answers,
  }) {
    return SiteChecklistActivityItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      role: role ?? this.role,
      roleLabel: roleLabel ?? this.roleLabel,
      visitDate: visitDate ?? this.visitDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      dueDate: dueDate ?? this.dueDate,
      code: code ?? this.code,
      clientType: clientType ?? this.clientType,
      status: status ?? this.status,
      frequencyLabel: frequencyLabel ?? this.frequencyLabel,
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
      spoc: spoc ?? this.spoc,
      mom: mom ?? this.mom,
      template: template ?? this.template,
      answers: answers ?? this.answers,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        role,
        roleLabel,
        visitDate,
        scheduledDate,
        dueDate,
        code,
        clientType,
        status,
        frequencyLabel,
        pending,
        completed,
        spoc,
        mom,
        template,
        answers,
      ];
}

/// A line in the walkaround checklist template
class ChecklistTemplateItemModel extends Equatable {
  final String key;
  final String title;
  final String section;
  final int sortOrder;

  const ChecklistTemplateItemModel({
    required this.key,
    required this.title,
    this.section = 'General',
    this.sortOrder = 0,
  });

  factory ChecklistTemplateItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistTemplateItemModel(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      section: json['section']?.toString() ?? 'General',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'section': section,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [key, title, section, sortOrder];
}

/// An answer item for a checklist template key
/// status values: 'OK' (Yes), 'ISSUE' (No), 'NA' (NA)
class ChecklistAnswerItemModel extends Equatable {
  final String key;
  final String status;
  final String remarks;

  const ChecklistAnswerItemModel({
    required this.key,
    required this.status,
    this.remarks = '',
  });

  factory ChecklistAnswerItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistAnswerItemModel(
      key: json['key']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OK',
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'status': status,
        'remarks': remarks,
      };

  ChecklistAnswerItemModel copyWith({
    String? key,
    String? status,
    String? remarks,
  }) {
    return ChecklistAnswerItemModel(
      key: key ?? this.key,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }

  @override
  List<Object?> get props => [key, status, remarks];
}

