import 'package:equatable/equatable.dart';

import '../../data/models/attendance_site_model.dart';
import '../../data/models/site_activity_model.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceError extends AttendanceState {
  final String message;
  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}

class AttendanceLoaded extends AttendanceState {
  final AttendanceBySiteModel data;
  final String siteSearchQuery;
  final int sitesCurrentPage;
  final int sitesItemsPerPage;

  final AttendanceSiteItemModel? selectedSite;
  final bool isActivitiesLoading;
  final SiteActivitiesResponseModel? activitiesData;
  final String activitySearchQuery;
  final int activitiesCurrentPage;
  final int activitiesItemsPerPage;

  const AttendanceLoaded({
    required this.data,
    this.siteSearchQuery = '',
    this.sitesCurrentPage = 1,
    this.sitesItemsPerPage = 20,
    this.selectedSite,
    this.isActivitiesLoading = false,
    this.activitiesData,
    this.activitySearchQuery = '',
    this.activitiesCurrentPage = 1,
    this.activitiesItemsPerPage = 20,
  });

  // ── Filtered Sites ──────────────────────────────────────────────────────────
  List<AttendanceSiteItemModel> get filteredSites {
    if (siteSearchQuery.trim().isEmpty) return data.items;
    final q = siteSearchQuery.trim().toLowerCase();
    return data.items.where((s) {
      return s.siteName.toLowerCase().contains(q) ||
          s.siteCode.toLowerCase().contains(q) ||
          s.clusterName.toLowerCase().contains(q) ||
          s.zoneName.toLowerCase().contains(q) ||
          s.siteCity.toLowerCase().contains(q);
    }).toList();
  }

  // Show pagination ONLY if more than 20 elements!
  bool get showSitesPagination => filteredSites.length > 20;

  int get totalSitesPages {
    if (filteredSites.isEmpty) return 1;
    return (filteredSites.length / sitesItemsPerPage).ceil();
  }

  List<AttendanceSiteItemModel> get paginatedSites {
    final list = filteredSites;
    if (list.length <= 20) return list;
    final start = (sitesCurrentPage - 1) * sitesItemsPerPage;
    if (start >= list.length) return [];
    final end = (start + sitesItemsPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  // ── Filtered Activities ─────────────────────────────────────────────────────
  List<ActivityVisitModel> get filteredActivities {
    final items = activitiesData?.items ?? [];
    if (activitySearchQuery.trim().isEmpty) return items;
    final q = activitySearchQuery.trim().toLowerCase();
    return items.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.code.toLowerCase().contains(q) ||
          a.roleLabel.toLowerCase().contains(q) ||
          a.role.toLowerCase().contains(q) ||
          a.assignedToName?.toLowerCase().contains(q) == true ||
          a.dueDate.toLowerCase().contains(q);
    }).toList();
  }

  // Show pagination ONLY if more than 20 elements!
  bool get showActivitiesPagination => filteredActivities.length > 20;

  int get totalActivitiesPages {
    if (filteredActivities.isEmpty) return 1;
    return (filteredActivities.length / activitiesItemsPerPage).ceil();
  }

  List<ActivityVisitModel> get paginatedActivities {
    final list = filteredActivities;
    if (list.length <= 20) return list;
    final start = (activitiesCurrentPage - 1) * activitiesItemsPerPage;
    if (start >= list.length) return [];
    final end = (start + activitiesItemsPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  AttendanceLoaded copyWith({
    AttendanceBySiteModel? data,
    String? siteSearchQuery,
    int? sitesCurrentPage,
    int? sitesItemsPerPage,
    AttendanceSiteItemModel? Function()? selectedSite,
    bool? isActivitiesLoading,
    SiteActivitiesResponseModel? Function()? activitiesData,
    String? activitySearchQuery,
    int? activitiesCurrentPage,
    int? activitiesItemsPerPage,
  }) {
    return AttendanceLoaded(
      data: data ?? this.data,
      siteSearchQuery: siteSearchQuery ?? this.siteSearchQuery,
      sitesCurrentPage: sitesCurrentPage ?? this.sitesCurrentPage,
      sitesItemsPerPage: sitesItemsPerPage ?? this.sitesItemsPerPage,
      selectedSite:
          selectedSite != null ? selectedSite() : this.selectedSite,
      isActivitiesLoading: isActivitiesLoading ?? this.isActivitiesLoading,
      activitiesData:
          activitiesData != null ? activitiesData() : this.activitiesData,
      activitySearchQuery: activitySearchQuery ?? this.activitySearchQuery,
      activitiesCurrentPage:
          activitiesCurrentPage ?? this.activitiesCurrentPage,
      activitiesItemsPerPage:
          activitiesItemsPerPage ?? this.activitiesItemsPerPage,
    );
  }

  @override
  List<Object?> get props => [
        data,
        siteSearchQuery,
        sitesCurrentPage,
        sitesItemsPerPage,
        selectedSite,
        isActivitiesLoading,
        activitiesData,
        activitySearchQuery,
        activitiesCurrentPage,
        activitiesItemsPerPage,
      ];
}

