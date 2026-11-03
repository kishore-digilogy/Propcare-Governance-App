import 'package:equatable/equatable.dart';

/// Formatter utility for Transition dates.
class TransitionDateHelper {
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '—';
    try {
      final parsed = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// Site info in transition details response.
class TransitionSiteInfoModel extends Equatable {
  final String id;
  final String name;
  final String code;
  final String clientName;
  final String? clientEmail;
  final String? contactPersonName;
  final String? contactPhone;
  final String city;
  final String state;
  final String zoneName;
  final String clusterName;
  final String groupName;
  final String serviceName;
  final String billingPm;
  final String clientType;
  final String? contractAwardDate;
  final String? contractStartDate;
  final String? contractEndDate;
  final String mode;
  final String status;
  final int manpowerRequired;
  final int manpowerDeployed;
  final int shortage;
  final String ldStatus;
  final bool ldTransitionComplete;
  final String? ldVerifiedAt;
  final String? zonalHead;
  final String? groupClusterHead;
  final String? clusterHead;
  final String? clusterLead;
  final String? fieldExecutive;

  const TransitionSiteInfoModel({
    required this.id,
    required this.name,
    required this.code,
    required this.clientName,
    this.clientEmail,
    this.contactPersonName,
    this.contactPhone,
    this.city = 'NA',
    this.state = 'NA',
    this.zoneName = '',
    this.clusterName = '',
    this.groupName = '',
    this.serviceName = '',
    this.billingPm = '0.00',
    this.clientType = 'A',
    this.contractAwardDate,
    this.contractStartDate,
    this.contractEndDate,
    this.mode = 'NEW',
    this.status = 'LIVE',
    this.manpowerRequired = 0,
    this.manpowerDeployed = 0,
    this.shortage = 0,
    this.ldStatus = 'OPEN',
    this.ldTransitionComplete = false,
    this.ldVerifiedAt,
    this.zonalHead,
    this.groupClusterHead,
    this.clusterHead,
    this.clusterLead,
    this.fieldExecutive,
  });

  factory TransitionSiteInfoModel.fromJson(Map<String, dynamic> json) {
    return TransitionSiteInfoModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',
      clientEmail: json['clientEmail']?.toString(),
      contactPersonName: json['contactPersonName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      city: json['city']?.toString() ?? 'NA',
      state: json['state']?.toString() ?? 'NA',
      zoneName: json['zoneName']?.toString() ?? (json['zone']?.toString() ?? ''),
      clusterName: json['clusterName']?.toString() ?? (json['cluster']?.toString() ?? ''),
      groupName: json['groupName']?.toString() ?? (json['group']?.toString() ?? ''),
      serviceName: json['serviceName']?.toString() ?? (json['service']?.toString() ?? ''),
      billingPm: json['billingPm']?.toString() ?? '0.00',
      clientType: json['clientType']?.toString() ?? 'A',
      contractAwardDate: json['contractAwardDate']?.toString(),
      contractStartDate: json['contractStartDate']?.toString(),
      contractEndDate: json['contractEndDate']?.toString(),
      mode: json['mode']?.toString() ?? 'NEW',
      status: json['status']?.toString() ?? 'LIVE',
      manpowerRequired: (json['manpowerRequired'] as num?)?.toInt() ?? 0,
      manpowerDeployed: (json['manpowerDeployed'] as num?)?.toInt() ?? 0,
      shortage: (json['shortage'] as num?)?.toInt() ?? 0,
      ldStatus: json['ldStatus']?.toString() ?? 'OPEN',
      ldTransitionComplete: json['ldTransitionComplete'] == true,
      ldVerifiedAt: json['ldVerifiedAt']?.toString(),
      zonalHead: json['zonalHead']?.toString(),
      groupClusterHead: json['groupClusterHead']?.toString(),
      clusterHead: json['clusterHead']?.toString(),
      clusterLead: json['clusterLead']?.toString(),
      fieldExecutive: json['fieldExecutive']?.toString(),
    );
  }

  String get formattedAwardDate => TransitionDateHelper.formatDate(contractAwardDate);
  String get formattedStartDate => TransitionDateHelper.formatDate(contractStartDate);
  String get formattedEndDate => TransitionDateHelper.formatDate(contractEndDate);

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        status,
        contractAwardDate,
        contractStartDate,
        contractEndDate,
      ];
}

/// Kickoff details inside ldPreview.
class TransitionKickoffModel extends Equatable {
  final String withClient;
  final String date;
  final List<String> participants;
  final String meeting;
  final String? contractAwardDate;
  final String? contractStartDate;
  final String? contractEndDate;

  const TransitionKickoffModel({
    this.withClient = 'NO',
    this.date = '',
    this.participants = const [],
    this.meeting = '',
    this.contractAwardDate,
    this.contractStartDate,
    this.contractEndDate,
  });

  factory TransitionKickoffModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    final participantsList = <String>[];
    if (rawParticipants is List) {
      for (final p in rawParticipants) {
        if (p != null) participantsList.add(p.toString());
      }
    }

    return TransitionKickoffModel(
      withClient: json['withClient']?.toString() ?? 'NO',
      date: json['date']?.toString() ?? '',
      participants: participantsList,
      meeting: json['meeting']?.toString() ?? '',
      contractAwardDate: json['contractAwardDate']?.toString(),
      contractStartDate: json['contractStartDate']?.toString(),
      contractEndDate: json['contractEndDate']?.toString(),
    );
  }

  bool get isWithClientYes => withClient.toUpperCase() == 'YES';
  bool get isPreTransitionMeetingYes =>
      meeting.toUpperCase() == 'COMPLETED' || meeting.toUpperCase() == 'YES';

  String get formattedDate => TransitionDateHelper.formatDate(date);

  @override
  List<Object?> get props => [withClient, date, participants, meeting];
}

/// Review details inside ldPreview.
class TransitionReviewModel extends Equatable {
  final String status;
  final String? submittedAt;
  final String? verifiedAt;
  final String note;

  const TransitionReviewModel({
    this.status = 'OPEN',
    this.submittedAt,
    this.verifiedAt,
    this.note = '',
  });

  factory TransitionReviewModel.fromJson(Map<String, dynamic> json) {
    return TransitionReviewModel(
      status: json['status']?.toString() ?? 'OPEN',
      submittedAt: json['submittedAt']?.toString(),
      verifiedAt: json['verifiedAt']?.toString(),
      note: json['note']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [status, submittedAt, verifiedAt, note];
}

/// Checklist item in internal or ldTransition lists.
class TransitionChecklistItemModel extends Equatable {
  final String id;
  final String phase;
  final String key;
  final String title;
  final int sortOrder;
  final bool canRaiseTicket;
  final String status;
  final bool done;
  final String? startDate;
  final String? endDate;
  final String? targetDate;
  final String? remarks;
  final String? issue;

  const TransitionChecklistItemModel({
    required this.id,
    this.phase = '',
    this.key = '',
    this.title = '',
    this.sortOrder = 0,
    this.canRaiseTicket = false,
    this.status = '',
    this.done = false,
    this.startDate,
    this.endDate,
    this.targetDate,
    this.remarks,
    this.issue,
  });

  factory TransitionChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return TransitionChecklistItemModel(
      id: json['id']?.toString() ?? '',
      phase: json['phase']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      canRaiseTicket: json['canRaiseTicket'] == true,
      status: json['status']?.toString() ?? '',
      done: json['done'] == true,
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      targetDate: json['targetDate']?.toString() ?? json['endDate']?.toString(),
      remarks: json['remarks']?.toString() ?? json['remark']?.toString(),
      issue: json['issue']?.toString(),
    );
  }

  String get formattedStartDate => TransitionDateHelper.formatDate(startDate);
  String get formattedTargetDate =>
      TransitionDateHelper.formatDate(targetDate ?? endDate);

  /// Status badge label: 'Completed' | 'Pending' | 'In progress'
  String get displayStatus {
    final upper = status.toUpperCase();
    if (done || upper == 'DONE' || upper == 'COMPLETED') {
      return 'Completed';
    }
    if (upper == 'IN_PROGRESS' || upper == 'IN PROGRESS') {
      return 'In progress';
    }
    return 'Pending';
  }

  @override
  List<Object?> get props => [id, phase, key, title, status, done, startDate, endDate];
}

/// The ldPreview container in response.
class LdPreviewModel extends Equatable {
  final TransitionKickoffModel kickoff;
  final TransitionReviewModel review;
  final List<TransitionChecklistItemModel> internal;
  final List<TransitionChecklistItemModel> ldTransition;

  const LdPreviewModel({
    this.kickoff = const TransitionKickoffModel(),
    this.review = const TransitionReviewModel(),
    this.internal = const [],
    this.ldTransition = const [],
  });

  factory LdPreviewModel.fromJson(Map<String, dynamic> json) {
    final kickoff = json['kickoff'] is Map<String, dynamic>
        ? TransitionKickoffModel.fromJson(json['kickoff'])
        : (json['kickoff'] is Map
            ? TransitionKickoffModel.fromJson(Map<String, dynamic>.from(json['kickoff']))
            : const TransitionKickoffModel());

    final review = json['review'] is Map<String, dynamic>
        ? TransitionReviewModel.fromJson(json['review'])
        : (json['review'] is Map
            ? TransitionReviewModel.fromJson(Map<String, dynamic>.from(json['review']))
            : const TransitionReviewModel());

    final internalList = <TransitionChecklistItemModel>[];
    if (json['internal'] is List) {
      for (final item in json['internal']) {
        if (item is Map) {
          internalList.add(TransitionChecklistItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final ldTransitionList = <TransitionChecklistItemModel>[];
    if (json['ldTransition'] is List) {
      for (final item in json['ldTransition']) {
        if (item is Map) {
          ldTransitionList.add(TransitionChecklistItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return LdPreviewModel(
      kickoff: kickoff,
      review: review,
      internal: internalList,
      ldTransition: ldTransitionList,
    );
  }

  @override
  List<Object?> get props => [kickoff, review, internal, ldTransition];
}

/// Top-level response model for GET /api/sites/{id}?view=transition.
class TransitionSiteDetailResponseModel extends Equatable {
  final TransitionSiteInfoModel site;
  final LdPreviewModel ldPreview;
  final List<TransitionChecklistItemModel> transitions;

  const TransitionSiteDetailResponseModel({
    required this.site,
    this.ldPreview = const LdPreviewModel(),
    this.transitions = const [],
  });

  factory TransitionSiteDetailResponseModel.fromJson(Map<String, dynamic> json) {
    final siteMap = json['site'] is Map
        ? Map<String, dynamic>.from(json['site'])
        : <String, dynamic>{};

    final ldPreviewMap = json['ldPreview'] is Map
        ? Map<String, dynamic>.from(json['ldPreview'])
        : <String, dynamic>{};

    final transitionsList = <TransitionChecklistItemModel>[];
    if (json['transitions'] is List) {
      for (final item in json['transitions']) {
        if (item is Map) {
          transitionsList.add(TransitionChecklistItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return TransitionSiteDetailResponseModel(
      site: TransitionSiteInfoModel.fromJson(siteMap),
      ldPreview: LdPreviewModel.fromJson(ldPreviewMap),
      transitions: transitionsList,
    );
  }

  @override
  List<Object?> get props => [site, ldPreview, transitions];
}

