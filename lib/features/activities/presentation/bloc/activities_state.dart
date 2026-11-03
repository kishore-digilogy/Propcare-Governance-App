import 'package:equatable/equatable.dart';

import '../../data/models/activity_detail_model.dart';
import '../../data/models/activity_site_summary_model.dart';
import '../../data/models/site_activity_item_model.dart';

abstract class ActivitiesState extends Equatable {
  const ActivitiesState();

  @override
  List<Object?> get props => [];
}

class ActivitiesInitial extends ActivitiesState {
  const ActivitiesInitial();
}

class ActivitiesLoading extends ActivitiesState {
  const ActivitiesLoading();
}

class ActivitiesLoaded extends ActivitiesState {
  final ActivitiesBySiteResponseModel response;
  final String view; // 'mine' or 'below'
  final String? selectedZoneId;
  final String? selectedClusterId;
  final String? selectedStatus;
  final String? selectedRole;
  final String searchQuery;
  final ActivitySiteItemModel? selectedSite;
  final SiteActivitiesResponseModel? selectedSiteActivities;
  final bool isLoadingDetail;
  final ActivityDetailModel? selectedActivityDetail;
  final bool isLoadingActivity;
  final bool isSubmittingVisit;
  final bool isSendingMom;
  final String? actionSuccessMessage;
  final String? actionErrorMessage;

  const ActivitiesLoaded({
    required this.response,
    required this.view,
    this.selectedZoneId,
    this.selectedClusterId,
    this.selectedStatus,
    this.selectedRole,
    this.searchQuery = '',
    this.selectedSite,
    this.selectedSiteActivities,
    this.isLoadingDetail = false,
    this.selectedActivityDetail,
    this.isLoadingActivity = false,
    this.isSubmittingVisit = false,
    this.isSendingMom = false,
    this.actionSuccessMessage,
    this.actionErrorMessage,
  });

  ActivitiesLoaded copyWith({
    ActivitiesBySiteResponseModel? response,
    String? view,
    String? Function()? selectedZoneId,
    String? Function()? selectedClusterId,
    String? Function()? selectedStatus,
    String? Function()? selectedRole,
    String? searchQuery,
    ActivitySiteItemModel? Function()? selectedSite,
    SiteActivitiesResponseModel? Function()? selectedSiteActivities,
    bool? isLoadingDetail,
    ActivityDetailModel? Function()? selectedActivityDetail,
    bool? isLoadingActivity,
    bool? isSubmittingVisit,
    bool? isSendingMom,
    String? Function()? actionSuccessMessage,
    String? Function()? actionErrorMessage,
  }) {
    return ActivitiesLoaded(
      response: response ?? this.response,
      view: view ?? this.view,
      selectedZoneId: selectedZoneId != null ? selectedZoneId() : this.selectedZoneId,
      selectedClusterId: selectedClusterId != null ? selectedClusterId() : this.selectedClusterId,
      selectedStatus: selectedStatus != null ? selectedStatus() : this.selectedStatus,
      selectedRole: selectedRole != null ? selectedRole() : this.selectedRole,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSite: selectedSite != null ? selectedSite() : this.selectedSite,
      selectedSiteActivities: selectedSiteActivities != null ? selectedSiteActivities() : this.selectedSiteActivities,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      selectedActivityDetail: selectedActivityDetail != null ? selectedActivityDetail() : this.selectedActivityDetail,
      isLoadingActivity: isLoadingActivity ?? this.isLoadingActivity,
      isSubmittingVisit: isSubmittingVisit ?? this.isSubmittingVisit,
      isSendingMom: isSendingMom ?? this.isSendingMom,
      actionSuccessMessage: actionSuccessMessage != null ? actionSuccessMessage() : this.actionSuccessMessage,
      actionErrorMessage: actionErrorMessage != null ? actionErrorMessage() : this.actionErrorMessage,
    );
  }

  List<ActivitySiteItemModel> get filteredSites {
    var list = response.items;

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((s) {
        return s.siteName.toLowerCase().contains(q) ||
            s.siteCode.toLowerCase().contains(q) ||
            s.siteCity.toLowerCase().contains(q) ||
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

    if (selectedStatus != null && selectedStatus!.isNotEmpty && selectedStatus != 'ALL') {
      list = list.where((s) => s.siteStatus.toUpperCase() == selectedStatus!.toUpperCase()).toList();
    }

    return list;
  }

  @override
  List<Object?> get props => [
        response,
        view,
        selectedZoneId,
        selectedClusterId,
        selectedStatus,
        selectedRole,
        searchQuery,
        selectedSite,
        selectedSiteActivities,
        isLoadingDetail,
        selectedActivityDetail,
        isLoadingActivity,
        isSubmittingVisit,
        isSendingMom,
        actionSuccessMessage,
        actionErrorMessage,
      ];
}

class ActivitiesError extends ActivitiesState {
  final String message;

  const ActivitiesError(this.message);

  @override
  List<Object?> get props => [message];
}

