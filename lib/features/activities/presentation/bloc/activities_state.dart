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
  final SiteActivitiesResponseModel activitiesResponse;
  final String? view; // 'mine' or 'below' or null
  final String? kind; // e.g. 'MIS,MMR'
  final String? selectedSiteId;
  final String? selectedZoneId;
  final String? selectedClusterId;
  final String? selectedStatus;
  final String? selectedRole;
  final String searchQuery;
  final List<ActivitySiteOptionModel> knownSites;
  final bool isLoadingActivities;
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
    this.response = const ActivitiesBySiteResponseModel(
      items: [],
      pending: 0,
      completed: 0,
      total: 0,
      view: 'mine',
      myRoleLabel: 'CRRM / Super Admin',
    ),
    this.activitiesResponse = const SiteActivitiesResponseModel(
      items: [],
      total: 0,
      limit: 10,
      offset: 0,
      counts: SiteActivityCountsModel(
        today: 0,
        upcoming: 0,
        pending: 0,
        overdue: 0,
        all: 0,
        scheduled: 0,
        assigned: 0,
        completed: 0,
        summaryOverdue: 0,
        summaryPending: 0,
      ),
      view: 'mine',
      myRole: '',
      myRoleLabel: 'CRRM / Super Admin',
    ),
    this.view,
    this.kind,
    this.selectedSiteId,
    this.selectedZoneId,
    this.selectedClusterId,
    this.selectedStatus,
    this.selectedRole,
    this.searchQuery = '',
    this.knownSites = const [],
    this.isLoadingActivities = false,
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
    SiteActivitiesResponseModel? activitiesResponse,
    String? Function()? view,
    String? Function()? kind,
    String? Function()? selectedSiteId,
    String? Function()? selectedZoneId,
    String? Function()? selectedClusterId,
    String? Function()? selectedStatus,
    String? Function()? selectedRole,
    String? searchQuery,
    List<ActivitySiteOptionModel>? knownSites,
    bool? isLoadingActivities,
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
      activitiesResponse: activitiesResponse ?? this.activitiesResponse,
      view: view != null ? view() : this.view,
      kind: kind != null ? kind() : this.kind,
      selectedSiteId: selectedSiteId != null ? selectedSiteId() : this.selectedSiteId,
      selectedZoneId: selectedZoneId != null ? selectedZoneId() : this.selectedZoneId,
      selectedClusterId: selectedClusterId != null ? selectedClusterId() : this.selectedClusterId,
      selectedStatus: selectedStatus != null ? selectedStatus() : this.selectedStatus,
      selectedRole: selectedRole != null ? selectedRole() : this.selectedRole,
      searchQuery: searchQuery ?? this.searchQuery,
      knownSites: knownSites ?? this.knownSites,
      isLoadingActivities: isLoadingActivities ?? this.isLoadingActivities,
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

  List<SiteActivityItemModel> get filteredActivities {
    var list = activitiesResponse.items;

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.siteName.toLowerCase().contains(q) ||
            a.siteCity.toLowerCase().contains(q) ||
            a.code.toLowerCase().contains(q) ||
            a.roleLabel.toLowerCase().contains(q) ||
            a.statusLabel.toLowerCase().contains(q) ||
            a.priority.toLowerCase().contains(q);
      }).toList();
    }

    if (selectedStatus != null && selectedStatus!.isNotEmpty && selectedStatus != 'ALL') {
      final s = selectedStatus!.toLowerCase();
      list = list.where((a) {
        if (s == 'pending') {
          return a.status.toLowerCase() == 'pending' ||
              a.status.toLowerCase() == 'open' ||
              a.statusLabel.toLowerCase() == 'pending' ||
              a.statusLabel.toLowerCase() == 'assigned';
        } else if (s == 'completed') {
          return a.status.toLowerCase() == 'completed' ||
              a.status.toLowerCase() == 'closed' ||
              a.statusLabel.toLowerCase() == 'completed';
        } else if (s == 'due') {
          final isPastDue = a.dueDate != null &&
              DateTime.tryParse(a.dueDate!)?.isBefore(DateTime.now()) == true &&
              a.status.toUpperCase() != 'COMPLETED' &&
              a.status.toUpperCase() != 'CLOSED';
          return isPastDue || a.status.toLowerCase() == 'due' || a.statusLabel.toLowerCase() == 'due';
        }
        return a.status.toLowerCase() == s ||
            a.statusLabel.toLowerCase() == s;
      }).toList();
    }

    if (selectedSiteId != null && selectedSiteId!.isNotEmpty && selectedSiteId != 'ALL') {
      list = list.where((a) => a.siteId == selectedSiteId).toList();
    }

    return list;
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
        activitiesResponse,
        view,
        kind,
        selectedSiteId,
        selectedZoneId,
        selectedClusterId,
        selectedStatus,
        selectedRole,
        searchQuery,
        knownSites,
        isLoadingActivities,
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

