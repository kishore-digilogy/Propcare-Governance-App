import 'package:equatable/equatable.dart';

import '../../data/models/site_model.dart';

abstract class SitesState extends Equatable {
  const SitesState();

  @override
  List<Object?> get props => [];
}

class SitesInitial extends SitesState {
  const SitesInitial();
}

class SitesLoading extends SitesState {
  const SitesLoading();
}

class SitesLoaded extends SitesState {
  final SitesResponseModel response;
  final String selectedTab; // 'All', 'LIVE', 'Transition', 'Special', 'Draft'
  final String? selectedZoneId;
  final String? selectedClusterId;
  final String? selectedStatus;
  final String? selectedClientType;
  final String? selectedMode;
  final String searchQuery;
  final int currentPage;
  final int pageSize;
  final bool isLoadingPage;

  const SitesLoaded({
    required this.response,
    this.selectedTab = 'All',
    this.selectedZoneId,
    this.selectedClusterId,
    this.selectedStatus,
    this.selectedClientType,
    this.selectedMode,
    this.searchQuery = '',
    this.currentPage = 1,
    this.pageSize = 20,
    this.isLoadingPage = false,
  });

  SitesLoaded copyWith({
    SitesResponseModel? response,
    String? selectedTab,
    String? Function()? selectedZoneId,
    String? Function()? selectedClusterId,
    String? Function()? selectedStatus,
    String? Function()? selectedClientType,
    String? Function()? selectedMode,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
    bool? isLoadingPage,
  }) {
    return SitesLoaded(
      response: response ?? this.response,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedZoneId: selectedZoneId != null ? selectedZoneId() : this.selectedZoneId,
      selectedClusterId: selectedClusterId != null ? selectedClusterId() : this.selectedClusterId,
      selectedStatus: selectedStatus != null ? selectedStatus() : this.selectedStatus,
      selectedClientType: selectedClientType != null ? selectedClientType() : this.selectedClientType,
      selectedMode: selectedMode != null ? selectedMode() : this.selectedMode,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      isLoadingPage: isLoadingPage ?? this.isLoadingPage,
    );
  }

  /// Total count considering response total
  int get totalCount => response.total;

  int get totalPages {
    if (totalCount <= 0) return 1;
    return (totalCount / pageSize).ceil();
  }

  /// Items filtered for view display
  List<SiteItemModel> get displayItems {
    var list = response.items;

    // Filter by tab
    if (selectedTab == 'LIVE') {
      list = list.where((s) => s.status.toUpperCase() == 'LIVE').toList();
    } else if (selectedTab == 'Transition') {
      list = list
          .where((s) =>
              s.status.toUpperCase().contains('TRANSITION') ||
              (s.ldStatus != null && s.ldStatus!.isNotEmpty))
          .toList();
    } else if (selectedTab == 'Special') {
      list = list.where((s) => s.special).toList();
    } else if (selectedTab == 'Draft') {
      list = list.where((s) => s.status.toUpperCase() == 'DRAFT').toList();
    }

    // Filter by search query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q) ||
            s.clientName.toLowerCase().contains(q) ||
            (s.city != null && s.city!.toLowerCase().contains(q)) ||
            s.zoneName.toLowerCase().contains(q) ||
            s.clusterName.toLowerCase().contains(q);
      }).toList();
    }

    // Filter by status
    if (selectedStatus != null && selectedStatus!.isNotEmpty && selectedStatus != 'ALL') {
      list = list.where((s) => s.status.toUpperCase() == selectedStatus!.toUpperCase()).toList();
    }

    // Filter by client type
    if (selectedClientType != null && selectedClientType!.isNotEmpty && selectedClientType != 'ALL') {
      list = list.where((s) => s.clientType.toUpperCase() == selectedClientType!.toUpperCase()).toList();
    }

    // Filter by mode
    if (selectedMode != null && selectedMode!.isNotEmpty && selectedMode != 'ALL') {
      list = list.where((s) => s.mode.toUpperCase() == selectedMode!.toUpperCase()).toList();
    }

    // Filter by zone
    if (selectedZoneId != null && selectedZoneId!.isNotEmpty && selectedZoneId != 'ALL') {
      list = list.where((s) => s.zoneId == selectedZoneId).toList();
    }

    // Filter by cluster
    if (selectedClusterId != null && selectedClusterId!.isNotEmpty && selectedClusterId != 'ALL') {
      list = list.where((s) => s.clusterId == selectedClusterId).toList();
    }

    return list;
  }

  @override
  List<Object?> get props => [
        response,
        selectedTab,
        selectedZoneId,
        selectedClusterId,
        selectedStatus,
        selectedClientType,
        selectedMode,
        searchQuery,
        currentPage,
        pageSize,
        isLoadingPage,
      ];
}

class SitesError extends SitesState {
  final String message;

  const SitesError(this.message);

  @override
  List<Object?> get props => [message];
}

