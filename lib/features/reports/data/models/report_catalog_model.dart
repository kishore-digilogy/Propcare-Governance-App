class ReportItemModel {
  final String id;
  final String title;
  final String unit;
  final int count;
  final String description;
  final String exportKind;

  const ReportItemModel({
    required this.id,
    required this.title,
    required this.unit,
    required this.count,
    required this.description,
    required this.exportKind,
  });

  factory ReportItemModel.fromJson(Map<String, dynamic> json) {
    return ReportItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      exportKind: json['exportKind']?.toString() ?? json['id']?.toString() ?? '',
    );
  }

  String get countDisplay {
    final capitalizedUnit = unit.isNotEmpty
        ? '${unit[0].toUpperCase()}${unit.substring(1)}'
        : '';
    return '$count $capitalizedUnit';
  }
}

class ReportDateRangeModel {
  final String from;
  final String to;
  final String key;

  const ReportDateRangeModel({
    required this.from,
    required this.to,
    required this.key,
  });

  factory ReportDateRangeModel.fromJson(Map<String, dynamic> json) {
    return ReportDateRangeModel(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      key: json['key']?.toString() ?? 'last_30',
    );
  }

  static const defaultRange = ReportDateRangeModel(
    from: '',
    to: '',
    key: 'last_30',
  );
}

class ReportCatalogResponseModel {
  final String generatedAt;
  final ReportDateRangeModel dateRange;
  final int scopeSites;
  final List<ReportItemModel> reports;

  const ReportCatalogResponseModel({
    required this.generatedAt,
    required this.dateRange,
    required this.scopeSites,
    required this.reports,
  });

  factory ReportCatalogResponseModel.fromJson(Map<String, dynamic> json) {
    final rawDateRange = json['dateRange'] is Map
        ? Map<String, dynamic>.from(json['dateRange'] as Map)
        : <String, dynamic>{};

    final rawReports = json['reports'] as List<dynamic>? ?? [];
    final reportsList = <ReportItemModel>[];
    for (final r in rawReports) {
      if (r is Map) {
        reportsList.add(ReportItemModel.fromJson(Map<String, dynamic>.from(r)));
      }
    }

    return ReportCatalogResponseModel(
      generatedAt: json['generatedAt']?.toString() ?? '',
      dateRange: ReportDateRangeModel.fromJson(rawDateRange),
      scopeSites: (json['scopeSites'] as num?)?.toInt() ?? 0,
      reports: reportsList,
    );
  }

  static const empty = ReportCatalogResponseModel(
    generatedAt: '',
    dateRange: ReportDateRangeModel.defaultRange,
    scopeSites: 0,
    reports: [],
  );
}

