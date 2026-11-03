class GovernanceColumnConfig {
  final String key;
  final String label;

  const GovernanceColumnConfig({
    required this.key,
    required this.label,
  });

  factory GovernanceColumnConfig.fromJson(Map<String, dynamic> json) {
    return GovernanceColumnConfig(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
      };
}

class GovernanceMatrixItemModel {
  final String id;
  final String tabKey;
  final String tabName;
  final String clientType;
  final String billingPm;
  final Map<String, String> frequencies;
  final List<GovernanceColumnConfig> columnsConfig;
  final int sortOrder;
  final bool active;
  final String? createdAt;
  final String? updatedAt;

  const GovernanceMatrixItemModel({
    required this.id,
    required this.tabKey,
    required this.tabName,
    required this.clientType,
    required this.billingPm,
    required this.frequencies,
    required this.columnsConfig,
    required this.sortOrder,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory GovernanceMatrixItemModel.fromJson(Map<String, dynamic> json) {
    final rawFreq = json['frequencies'];
    final freqMap = <String, String>{};
    if (rawFreq is Map) {
      rawFreq.forEach((k, v) {
        if (k != null && v != null) {
          freqMap[k.toString()] = v.toString();
        }
      });
    }

    final rawCols = json['columnsConfig'] as List<dynamic>? ?? [];
    final cols = <GovernanceColumnConfig>[];
    for (final c in rawCols) {
      if (c is Map) {
        cols.add(GovernanceColumnConfig.fromJson(Map<String, dynamic>.from(c)));
      }
    }

    return GovernanceMatrixItemModel(
      id: json['id']?.toString() ?? '',
      tabKey: json['tabKey']?.toString() ?? '',
      tabName: json['tabName']?.toString() ?? '',
      clientType: json['clientType']?.toString() ?? '',
      billingPm: json['billingPm']?.toString() ?? '',
      frequencies: freqMap,
      columnsConfig: cols,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  /// Label for tab display e.g. "ld_training" -> "L & D"
  String get displayTabName {
    if (tabKey == 'ld_training') return 'L & D';
    if (tabName.isNotEmpty) return tabName;
    switch (tabKey) {
      case 'operations':
        return 'Operations';
      case 'ehs_audit':
        return 'EHS Audit';
      case 'hr_compliance':
        return 'HR & Compliance';
      case 'machine_technician':
        return 'Machine Technician';
      case 'crrm':
        return 'CRRM';
      default:
        return tabKey;
    }
  }
}

class GovernanceMatrixResponseModel {
  final List<GovernanceMatrixItemModel> items;

  const GovernanceMatrixResponseModel({required this.items});

  factory GovernanceMatrixResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final list = <GovernanceMatrixItemModel>[];
    for (final it in rawItems) {
      if (it is Map) {
        list.add(
          GovernanceMatrixItemModel.fromJson(Map<String, dynamic>.from(it)),
        );
      }
    }
    return GovernanceMatrixResponseModel(items: list);
  }

  static const empty = GovernanceMatrixResponseModel(items: []);

  /// Unique tabs sorted in canonical order:
  /// Operations, L & D, EHS Audit, HR & Compliance, Machine Technician, CRRM
  List<({String key, String name})> get uniqueTabs {
    const canonicalOrder = [
      'operations',
      'ld_training',
      'ehs_audit',
      'hr_compliance',
      'machine_technician',
      'crrm',
    ];

    final found = <String, String>{};
    for (final it in items) {
      if (!found.containsKey(it.tabKey)) {
        found[it.tabKey] = it.displayTabName;
      }
    }

    final result = <({String key, String name})>[];
    for (final key in canonicalOrder) {
      if (found.containsKey(key)) {
        result.add((key: key, name: found[key]!));
      }
    }
    // Add any unexpected tabs
    found.forEach((k, v) {
      if (!canonicalOrder.contains(k)) {
        result.add((key: k, name: v));
      }
    });

    return result;
  }

  /// Get items for a given tabKey sorted by sortOrder
  List<GovernanceMatrixItemModel> getItemsForTab(String tabKey) {
    final list = items.where((it) => it.tabKey == tabKey).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// Get column config for a tabKey (first non-empty config, or generated from frequencies keys)
  List<GovernanceColumnConfig> getColumnsConfigForTab(String tabKey) {
    final tabItems = getItemsForTab(tabKey);
    for (final it in tabItems) {
      if (it.columnsConfig.isNotEmpty) {
        return it.columnsConfig;
      }
    }

    if (tabKey == 'operations') {
      return const [
        GovernanceColumnConfig(key: 'fieldExecutive', label: 'Field Executive'),
        GovernanceColumnConfig(key: 'clusterExecutive', label: 'Cluster Executive'),
        GovernanceColumnConfig(key: 'clusterLead', label: 'Cluster Lead'),
        GovernanceColumnConfig(key: 'clusterHead', label: 'Cluster Head'),
        GovernanceColumnConfig(key: 'groupClusterHead', label: 'Group Cluster Head'),
        GovernanceColumnConfig(key: 'zonalHead', label: 'Zonal Head'),
        GovernanceColumnConfig(key: 'coo', label: 'COO'),
        GovernanceColumnConfig(key: 'mmr', label: 'MMR'),
        GovernanceColumnConfig(key: 'mis', label: 'MIS'),
        GovernanceColumnConfig(key: 'rr', label: 'R&R'),
      ];
    }

    return const [
      GovernanceColumnConfig(key: 'frequency', label: 'Frequency'),
    ];
  }
}

