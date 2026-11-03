import 'package:equatable/equatable.dart';

import '../../data/models/site_model.dart';

abstract class RenewalsState extends Equatable {
  const RenewalsState();

  @override
  List<Object?> get props => [];
}

class RenewalsInitial extends RenewalsState {
  const RenewalsInitial();
}

class RenewalsLoading extends RenewalsState {
  const RenewalsLoading();
}

class RenewalsLoaded extends RenewalsState {
  final RenewalSitesResponseModel response;
  final String selectedWindow; // '30', '60', '90', 'pending'
  final String? selectedZoneId;
  final String? selectedClusterId;
  final String? selectedClientType;
  final String searchQuery;
  final int currentPage;
  final int pageSize;
  final bool isLoadingPage;

  const RenewalsLoaded({
    required this.response,
    this.selectedWindow = '30',
    this.selectedZoneId,
    this.selectedClusterId,
    this.selectedClientType,
    this.searchQuery = '',
    this.currentPage = 1,
    this.pageSize = 20,
    this.isLoadingPage = false,
  });

  RenewalsLoaded copyWith({
    RenewalSitesResponseModel? response,
    String? selectedWindow,
    String? Function()? selectedZoneId,
    String? Function()? selectedClusterId,
    String? Function()? selectedClientType,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
    bool? isLoadingPage,
  }) {
    return RenewalsLoaded(
      response: response ?? this.response,
      selectedWindow: selectedWindow ?? this.selectedWindow,
      selectedZoneId: selectedZoneId != null ? selectedZoneId() : this.selectedZoneId,
      selectedClusterId: selectedClusterId != null ? selectedClusterId() : this.selectedClusterId,
      selectedClientType: selectedClientType != null ? selectedClientType() : this.selectedClientType,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      isLoadingPage: isLoadingPage ?? this.isLoadingPage,
    );
  }

  int get totalPages {
    if (response.total <= 0) return 1;
    return (response.total / pageSize).ceil();
  }

  List<SiteItemModel> get filteredItems {
    var list = response.items;

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q) ||
            s.clientName.toLowerCase().contains(q) ||
            s.zoneName.toLowerCase().contains(q) ||
            s.clusterName.toLowerCase().contains(q);
      }).toList();
    }

    if (selectedZoneId != null && selectedZoneId!.isNotEmpty && selectedZoneId != 'ALL') {
      list = list.where((s) => s.zoneId == selectedZoneId).toList();
    }

    if (selectedClusterId != null && selectedClusterId!.isNotEmpty && selectedClusterId != 'ALL') {
      list = list.where((s) => s.clusterId == selectedClusterId).toList();
    }

    if (selectedClientType != null && selectedClientType!.isNotEmpty && selectedClientType != 'ALL') {
      list = list.where((s) => s.clientType.toUpperCase() == selectedClientType!.toUpperCase()).toList();
    }

    return list;
  }

  @override
  List<Object?> get props => [
        response,
        selectedWindow,
        selectedZoneId,
        selectedClusterId,
        selectedClientType,
        searchQuery,
        currentPage,
        pageSize,
        isLoadingPage,
      ];
}

class RenewalsError extends RenewalsState {
  final String message;

  const RenewalsError(this.message);

  @override
  List<Object?> get props => [message];
}

