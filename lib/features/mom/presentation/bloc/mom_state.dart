import 'package:equatable/equatable.dart';

import '../../data/models/mom_by_site_model.dart';

abstract class MomState extends Equatable {
  const MomState();

  @override
  List<Object?> get props => [];
}

class MomInitial extends MomState {
  const MomInitial();
}

class MomLoading extends MomState {
  const MomLoading();
}

class MomLoaded extends MomState {
  final MomBySiteModel data;
  final int selectedTabIndex; // 0 = Pending, 1 = Completed
  final String searchQuery;

  const MomLoaded({
    required this.data,
    this.selectedTabIndex = 0,
    this.searchQuery = '',
  });

  /// Pending count (from root API response or calculated)
  int get pendingCount => data.pending > 0
      ? data.pending
      : data.items.fold(0, (sum, item) => sum + item.pending);

  /// Completed count (from root API response or calculated)
  int get completedCount => data.completed > 0
      ? data.completed
      : data.items.fold(0, (sum, item) => sum + item.completed);

  /// Items filtered by the active tab and search query
  List<MomSiteItemModel> get filteredItems {
    final query = searchQuery.trim().toLowerCase();

    return data.items.where((item) {
      // 1. Tab filter
      final matchesTab = selectedTabIndex == 0
          ? item.pending > 0
          : item.completed > 0;

      if (!matchesTab) return false;

      // 2. Search query filter
      if (query.isEmpty) return true;

      return item.siteName.toLowerCase().contains(query) ||
          item.siteCode.toLowerCase().contains(query) ||
          item.clusterName.toLowerCase().contains(query) ||
          item.zoneName.toLowerCase().contains(query) ||
          item.siteCity.toLowerCase().contains(query);
    }).toList();
  }

  MomLoaded copyWith({
    MomBySiteModel? data,
    int? selectedTabIndex,
    String? searchQuery,
  }) {
    return MomLoaded(
      data: data ?? this.data,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [data, selectedTabIndex, searchQuery];
}

class MomError extends MomState {
  final String message;
  const MomError(this.message);

  @override
  List<Object?> get props => [message];
}

