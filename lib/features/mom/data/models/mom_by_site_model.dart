/// Model representing an individual site's MOM status.
class MomSiteItemModel {
  final String siteId;
  final String siteName;
  final String siteCode;
  final String siteCity;
  final String siteClientType;
  final String zoneName;
  final String clusterName;
  final String siteStatus;
  final int pending;
  final int completed;
  final int total;

  const MomSiteItemModel({
    required this.siteId,
    required this.siteName,
    required this.siteCode,
    required this.siteCity,
    required this.siteClientType,
    required this.zoneName,
    required this.clusterName,
    required this.siteStatus,
    required this.pending,
    required this.completed,
    required this.total,
  });

  factory MomSiteItemModel.fromJson(Map<String, dynamic> json) {
    return MomSiteItemModel(
      siteId: json['siteId']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? '',
      siteCode: json['siteCode']?.toString() ?? '',
      siteCity: json['siteCity']?.toString() ?? '',
      siteClientType: json['siteClientType']?.toString() ?? '',
      zoneName: json['zoneName']?.toString() ?? '',
      clusterName: json['clusterName']?.toString() ?? '',
      siteStatus: json['siteStatus']?.toString() ?? 'LIVE',
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'siteId': siteId,
        'siteName': siteName,
        'siteCode': siteCode,
        'siteCity': siteCity,
        'siteClientType': siteClientType,
        'zoneName': zoneName,
        'clusterName': clusterName,
        'siteStatus': siteStatus,
        'pending': pending,
        'completed': completed,
        'total': total,
      };

  bool get isLive => siteStatus.toUpperCase() == 'LIVE';

  String get formattedSubtitle {
    final parts = <String>[];
    if (siteCode.isNotEmpty) parts.add(siteCode);
    if (siteCity.isNotEmpty && siteCity.toUpperCase() != 'NA') {
      parts.add(siteCity);
    }
    if (zoneName.isNotEmpty) parts.add(zoneName);
    return parts.join(' · ');
  }
}

/// Root response model for GET /activities/mom-by-site.
class MomBySiteModel {
  final List<MomSiteItemModel> items;
  final int pending;
  final int completed;

  const MomBySiteModel({
    required this.items,
    required this.pending,
    required this.completed,
  });

  factory MomBySiteModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map(MomSiteItemModel.fromJson)
        .toList();

    return MomBySiteModel(
      items: parsedItems,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'pending': pending,
        'completed': completed,
      };

  /// Empty fallback instance.
  static const empty = MomBySiteModel(
    items: [],
    pending: 0,
    completed: 0,
  );
}

