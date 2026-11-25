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
  final List<MomActivityModel> allActivities;
  final int selectedTabIndex; // 0 = All, 1 = Pending, 2 = Completed
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
    this.allActivities = const [],
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

  /// Total count across all activities
  int get allCount => allActivities.isNotEmpty
      ? allActivities.length
      : data.items.fold(0, (sum, item) => sum + item.total);

  /// Pending count (where MOM is pending / not sent)
  int get pendingCount => allActivities.isNotEmpty
      ? allActivities.where((a) => a.isPending).length
      : (data.pending > 0
          ? data.pending
          : data.items.fold(0, (sum, item) => sum + item.pending));

  /// Completed count (where MOM is sent)
  int get completedCount => allActivities.isNotEmpty
      ? allActivities.where((a) => a.isSent).length
      : (data.completed > 0
          ? data.completed
          : data.items.fold(0, (sum, item) => sum + item.completed));

  /// Site roles available for the selected site
  List<String> get siteRoles {
    final roles = <String>{};
    for (final act in siteActivities) {
      final r = act.role.isNotEmpty ? act.role : act.roleLabel;
      if (r.isNotEmpty) roles.add(r);
    }
    return roles.toList();
  }

  /// Filtered activities list for the main table (Image 9)
  List<MomActivityModel> get filteredActivities {
    final query = searchQuery.trim().toLowerCase();

    return allActivities.where((act) {
      // 1. Tab filter: 0 = All, 1 = Pending, 2 = Completed
      if (selectedTabIndex == 1 && !act.isPending) return false;
      if (selectedTabIndex == 2 && !act.isSent) return false;

      // 2. Search query filter
      if (query.isEmpty) return true;

      return act.siteName.toLowerCase().contains(query) ||
          act.siteCode.toLowerCase().contains(query) ||
          act.title.toLowerCase().contains(query) ||
          act.role.toLowerCase().contains(query) ||
          act.roleLabel.toLowerCase().contains(query) ||
          act.clusterName.toLowerCase().contains(query) ||
          act.zoneName.toLowerCase().contains(query);
    }).toList();
  }

  /// Filtered sites list fallback if activities aren't loaded individually
  List<MomSiteItemModel> get filteredItems {
    final query = searchQuery.trim().toLowerCase();

    return data.items.where((item) {
      if (selectedTabIndex == 1 && item.pending <= 0) return false;
      if (selectedTabIndex == 2 && item.completed <= 0) return false;

      if (query.isEmpty) return true;

      return item.siteName.toLowerCase().contains(query) ||
          item.siteCode.toLowerCase().contains(query) ||
          item.clusterName.toLowerCase().contains(query) ||
          item.zoneName.toLowerCase().contains(query) ||
          item.siteCity.toLowerCase().contains(query);
    }).toList();
  }

  /// Site activities filtered by current tab (or all for the site)
  List<MomActivityModel> get currentTabActivities {
    if (selectedTabIndex == 1) {
      return siteActivities.where((a) => a.isPending).toList();
    } else if (selectedTabIndex == 2) {
      return siteActivities.where((a) => a.isSent).toList();
    }
    return siteActivities;
  }

  MomLoaded copyWith({
    MomBySiteModel? data,
    List<MomActivityModel>? allActivities,
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
      allActivities: allActivities ?? this.allActivities,
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
        allActivities,
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
