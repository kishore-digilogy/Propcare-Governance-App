import 'package:equatable/equatable.dart';

import '../../data/models/mom_activity_model.dart';
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

  // Selected site and activities
  final MomSiteItemModel? selectedSite;
  final bool isSiteActivitiesLoading;
  final List<MomActivityModel> siteActivities;
  final MomActivityModel? selectedActivity;

  // Sending MOM status
  final bool isSendingMom;
  final bool momSendSuccess;
  final String? actionMessage;
  final String? actionError;

  const MomLoaded({
    required this.data,
    this.selectedTabIndex = 0,
    this.searchQuery = '',
    this.selectedSite,
    this.isSiteActivitiesLoading = false,
    this.siteActivities = const [],
    this.selectedActivity,
    this.isSendingMom = false,
    this.momSendSuccess = false,
    this.actionMessage,
    this.actionError,
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

  /// Site activities filtered by current tab (Pending vs Completed)
  List<MomActivityModel> get currentTabActivities {
    if (selectedTabIndex == 0) {
      return siteActivities.where((a) => a.isPending).toList();
    } else {
      return siteActivities.where((a) => a.isSent).toList();
    }
  }

  MomLoaded copyWith({
    MomBySiteModel? data,
    int? selectedTabIndex,
    String? searchQuery,
    MomSiteItemModel? Function()? selectedSite,
    bool? isSiteActivitiesLoading,
    List<MomActivityModel>? siteActivities,
    MomActivityModel? Function()? selectedActivity,
    bool? isSendingMom,
    bool? momSendSuccess,
    String? Function()? actionMessage,
    String? Function()? actionError,
  }) {
    return MomLoaded(
      data: data ?? this.data,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSite:
          selectedSite != null ? selectedSite() : this.selectedSite,
      isSiteActivitiesLoading:
          isSiteActivitiesLoading ?? this.isSiteActivitiesLoading,
      siteActivities: siteActivities ?? this.siteActivities,
      selectedActivity:
          selectedActivity != null ? selectedActivity() : this.selectedActivity,
      isSendingMom: isSendingMom ?? this.isSendingMom,
      momSendSuccess: momSendSuccess ?? this.momSendSuccess,
      actionMessage:
          actionMessage != null ? actionMessage() : this.actionMessage,
      actionError:
          actionError != null ? actionError() : this.actionError,
    );
  }

  @override
  List<Object?> get props => [
        data,
        selectedTabIndex,
        searchQuery,
        selectedSite,
        isSiteActivitiesLoading,
        siteActivities,
        selectedActivity,
        isSendingMom,
        momSendSuccess,
        actionMessage,
        actionError,
      ];
}

class MomError extends MomState {
  final String message;
  const MomError(this.message);

  @override
  List<Object?> get props => [message];
}
