import 'package:equatable/equatable.dart';

class MachineryItemModel extends Equatable {
  final String code;
  final String name;
  final String masterId;
  final int quantity;
  final String frequency;
  final bool ppmApplicable;

  const MachineryItemModel({
    required this.code,
    required this.name,
    required this.masterId,
    required this.quantity,
    required this.frequency,
    required this.ppmApplicable,
  });

  factory MachineryItemModel.fromJson(Map<String, dynamic> json) {
    return MachineryItemModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      masterId: json['masterId']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      frequency: json['frequency']?.toString() ?? '—',
      ppmApplicable: json['ppmApplicable'] == true,
    );
  }

  @override
  List<Object?> get props => [code, name, masterId, quantity, frequency, ppmApplicable];
}

class SiteItemModel extends Equatable {
  final String id;
  final String name;
  final String code;
  final String clientName;
  final String? clientGroupId;
  final String? clientEmail;
  final String? contactPersonName;
  final String? contactPhone;
  final String? location;
  final String? city;
  final String? state;
  final String? zoneId;
  final String? groupId;
  final String? clusterId;
  final String? billingPm;
  final String clientType;
  final String? contractStartDate;
  final String? contractEndDate;
  final String mode;
  final String? plannedStartDate;
  final String? actualStartDate;
  final String? activationDate;
  final String status;
  final String primaryServiceId;
  final int manpowerRequired;
  final int manpowerDeployed;
  final int shortage;
  final bool specialAttention;
  final bool specialAttentionActive;
  final bool special;
  final String zone;
  final String zoneName;
  final String cluster;
  final String clusterName;
  final String group;
  final String groupName;
  final String service;
  final String serviceName;
  final String lead;
  final String leadName;
  final String head;
  final String headName;
  final String? ldStatus;
  final bool ldTransitionComplete;
  final bool transitionClosed;
  final List<MachineryItemModel> machinery;
  final int? daysRemaining;

  const SiteItemModel({
    required this.id,
    required this.name,
    required this.code,
    required this.clientName,
    this.clientGroupId,
    this.clientEmail,
    this.contactPersonName,
    this.contactPhone,
    this.location,
    this.city,
    this.state,
    this.zoneId,
    this.groupId,
    this.clusterId,
    this.billingPm,
    required this.clientType,
    this.contractStartDate,
    this.contractEndDate,
    required this.mode,
    this.plannedStartDate,
    this.actualStartDate,
    this.activationDate,
    required this.status,
    required this.primaryServiceId,
    required this.manpowerRequired,
    required this.manpowerDeployed,
    required this.shortage,
    required this.specialAttention,
    required this.specialAttentionActive,
    required this.special,
    required this.zone,
    required this.zoneName,
    required this.cluster,
    required this.clusterName,
    required this.group,
    required this.groupName,
    required this.service,
    required this.serviceName,
    required this.lead,
    required this.leadName,
    required this.head,
    required this.headName,
    this.ldStatus,
    this.ldTransitionComplete = false,
    this.transitionClosed = false,
    this.machinery = const [],
    this.daysRemaining,
  });

  factory SiteItemModel.fromJson(Map<String, dynamic> json) {
    final machineryList = <MachineryItemModel>[];
    if (json['machinery'] is List) {
      for (final m in json['machinery']) {
        if (m is Map<String, dynamic>) {
          machineryList.add(MachineryItemModel.fromJson(m));
        }
      }
    }

    final manpowerReq = (json['manpowerRequired'] as num?)?.toInt() ?? 0;
    final manpowerDep = (json['manpowerDeployed'] as num?)?.toInt() ?? 0;
    final shortageVal = (json['shortage'] as num?)?.toInt() ?? (manpowerReq - manpowerDep);

    final isSpecial = json['special'] == true || json['special']?.toString() == 'true';

    return SiteItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Site',
      code: json['code']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',
      clientGroupId: json['clientGroupId']?.toString(),
      clientEmail: json['clientEmail']?.toString(),
      contactPersonName: json['contactPersonName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      location: json['location']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zoneId: json['zoneId']?.toString(),
      groupId: json['groupId']?.toString(),
      clusterId: json['clusterId']?.toString(),
      billingPm: json['billingPm']?.toString(),
      clientType: json['clientType']?.toString().toUpperCase() ?? 'A',
      contractStartDate: json['contractStartDate']?.toString(),
      contractEndDate: json['contractEndDate']?.toString(),
      mode: json['mode']?.toString() ?? 'NEW',
      plannedStartDate: json['plannedStartDate']?.toString(),
      actualStartDate: json['actualStartDate']?.toString(),
      activationDate: json['activationDate']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'LIVE',
      primaryServiceId: json['primaryServiceId']?.toString() ?? '',
      manpowerRequired: manpowerReq,
      manpowerDeployed: manpowerDep,
      shortage: shortageVal > 0 ? shortageVal : 0,
      specialAttention: isSpecial,
      specialAttentionActive: json['specialAttentionActive'] == true,
      special: isSpecial,
      zone: json['zone']?.toString() ?? '',
      zoneName: json['zoneName']?.toString() ?? (json['zone']?.toString() ?? ''),
      cluster: json['cluster']?.toString() ?? '',
      clusterName: json['clusterName']?.toString() ?? (json['cluster']?.toString() ?? ''),
      group: json['group']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? '',
      service: json['service']?.toString() ?? 'HK',
      serviceName: json['serviceName']?.toString() ?? 'HK',
      lead: json['lead']?.toString() ?? '—',
      leadName: json['leadName']?.toString() ?? (json['lead']?.toString() ?? '—'),
      head: json['head']?.toString() ?? '—',
      headName: json['headName']?.toString() ?? (json['head']?.toString() ?? '—'),
      ldStatus: json['ldStatus']?.toString(),
      ldTransitionComplete: json['ldTransitionComplete'] == true,
      transitionClosed: json['transitionClosed'] == true,
      machinery: machineryList,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
    );
  }

  String get daysRemainingDisplay {
    if (daysRemaining == null) return '—';
    if (daysRemaining! <= 0) return 'Expired';
    return '$daysRemaining days left';
  }

  String get formattedContractEndDate {
    if (contractEndDate == null || contractEndDate!.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(contractEndDate!);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return contractEndDate!;
    }
  }

  /// Formats raw billing string (e.g. "740000.00") to "₹7.40L"
  String get formattedBillingPm {
    if (billingPm == null || billingPm!.isEmpty) return '—';
    final parsed = double.tryParse(billingPm!);
    if (parsed == null) return '₹$billingPm';

    if (parsed >= 100000) {
      final inLakhs = parsed / 100000.0;
      // e.g. 7.4 -> "₹7.40L" or 40.4 -> "₹40.40L"
      return '₹${inLakhs.toStringAsFixed(2)}L';
    } else if (parsed >= 1000) {
      final inK = parsed / 1000.0;
      return '₹${inK.toStringAsFixed(1)}K';
    }
    return '₹${parsed.toStringAsFixed(0)}';
  }

  String get sublineDisplay {
    final parts = <String>[];
    if (code.isNotEmpty) parts.add(code);
    if (service.isNotEmpty) parts.add(service);
    return parts.join(' · ');
  }

  // ── Transition Stage Helpers (Matching Transition & Start-Up UI) ───────────

  /// Transition is complete if closed or verified
  bool get isTransitionComplete =>
      transitionClosed || ldTransitionComplete || ldStatus == 'VERIFIED';

  /// Site is in draft / creation phase
  bool get isSiteCreation => status == 'DRAFT';

  /// Site is in active Site Live transition verification phase
  bool get isSiteLive => !isSiteCreation && !isTransitionComplete;

  /// Human-readable transition stage
  String get transitionStageLabel {
    if (isSiteCreation) return '1. Site Creation';
    if (isSiteLive) return '2. Site Live';
    return 'Live · Transition Closed';
  }

  /// Action required description text
  String get transitionActionRequired {
    if (isSiteCreation) return 'Save and go live from Create Site';
    if (isSiteLive) return 'Awaiting L&D Head Stability Verify';
    return 'Transition complete — governance active';
  }

  /// Button label for transition action
  String get transitionWorkflowButtonLabel {
    if (isSiteCreation) return 'Site Creation →';
    if (isSiteLive) return 'Site Live →';
    return 'View →';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        status,
        clientType,
        zoneId,
        clusterId,
        billingPm,
        specialAttention,
        manpowerRequired,
        manpowerDeployed,
        shortage,
      ];
}

class SiteTabCountsModel extends Equatable {
  final int all;
  final int draft;
  final int live;
  final int transition;
  final int delayed;
  final int special;

  const SiteTabCountsModel({
    required this.all,
    required this.draft,
    required this.live,
    required this.transition,
    required this.delayed,
    required this.special,
  });

  factory SiteTabCountsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SiteTabCountsModel(
        all: 0,
        draft: 0,
        live: 0,
        transition: 0,
        delayed: 0,
        special: 0,
      );
    }
    return SiteTabCountsModel(
      all: (json['All'] as num?)?.toInt() ?? (json['all'] as num?)?.toInt() ?? 0,
      draft: (json['Draft'] as num?)?.toInt() ?? (json['draft'] as num?)?.toInt() ?? 0,
      live: (json['LIVE'] as num?)?.toInt() ?? (json['live'] as num?)?.toInt() ?? 0,
      transition: (json['Transition'] as num?)?.toInt() ?? (json['transition'] as num?)?.toInt() ?? 0,
      delayed: (json['Delayed'] as num?)?.toInt() ?? (json['delayed'] as num?)?.toInt() ?? 0,
      special: (json['Special'] as num?)?.toInt() ?? (json['special'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [all, draft, live, transition, delayed, special];
}

class SitesResponseModel extends Equatable {
  final List<SiteItemModel> items;
  final int total;
  final SiteTabCountsModel tabCounts;

  const SitesResponseModel({
    required this.items,
    required this.total,
    required this.tabCounts,
  });

  factory SitesResponseModel.fromJson(Map<String, dynamic> json) {
    final list = <SiteItemModel>[];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          list.add(SiteItemModel.fromJson(item));
        }
      }
    }

    return SitesResponseModel(
      items: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      tabCounts: SiteTabCountsModel.fromJson(json['tabCounts'] as Map<String, dynamic>?),
    );
  }

  @override
  List<Object?> get props => [items, total, tabCounts];
}

class RenewalWindowCountsModel extends Equatable {
  final int count30;
  final int count60;
  final int count90;
  final int countPending;

  const RenewalWindowCountsModel({
    required this.count30,
    required this.count60,
    required this.count90,
    required this.countPending,
  });

  factory RenewalWindowCountsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RenewalWindowCountsModel(
        count30: 0,
        count60: 0,
        count90: 0,
        countPending: 0,
      );
    }
    return RenewalWindowCountsModel(
      count30: (json['30'] as num?)?.toInt() ?? 0,
      count60: (json['60'] as num?)?.toInt() ?? 0,
      count90: (json['90'] as num?)?.toInt() ?? 0,
      countPending: (json['pending'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [count30, count60, count90, countPending];
}

class RenewalSitesResponseModel extends Equatable {
  final List<SiteItemModel> items;
  final int total;
  final String window;
  final RenewalWindowCountsModel windowCounts;

  const RenewalSitesResponseModel({
    required this.items,
    required this.total,
    required this.window,
    required this.windowCounts,
  });

  factory RenewalSitesResponseModel.fromJson(Map<String, dynamic> json) {
    final list = <SiteItemModel>[];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          list.add(SiteItemModel.fromJson(item));
        }
      }
    }

    return RenewalSitesResponseModel(
      items: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      window: json['window']?.toString() ?? '30',
      windowCounts: RenewalWindowCountsModel.fromJson(json['windowCounts'] as Map<String, dynamic>?),
    );
  }

  @override
  List<Object?> get props => [items, total, window, windowCounts];
}


