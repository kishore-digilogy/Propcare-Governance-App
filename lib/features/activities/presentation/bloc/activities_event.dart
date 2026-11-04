import 'package:equatable/equatable.dart';

import '../../data/models/activity_site_summary_model.dart';

abstract class ActivitiesEvent extends Equatable {
  const ActivitiesEvent();

  @override
  List<Object?> get props => [];
}

class LoadActivities extends ActivitiesEvent {
  final String? view; // 'mine' or 'below' or null
  final String? kind; // e.g. 'MIS,MMR'
  final String? siteId;
  final String? status;
  final String? role;
  final int offset;
  final int limit;
  final bool isRefresh;

  const LoadActivities({
    this.view,
    this.kind,
    this.siteId,
    this.status,
    this.role,
    this.offset = 0,
    this.limit = 10,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [view, kind, siteId, status, role, offset, limit, isRefresh];
}

class ChangeActivitiesSiteFilter extends ActivitiesEvent {
  final String? siteId;

  const ChangeActivitiesSiteFilter(this.siteId);

  @override
  List<Object?> get props => [siteId];
}

class LoadActivitiesPage extends ActivitiesEvent {
  final int offset;
  final int limit;

  const LoadActivitiesPage({
    this.offset = 0,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [offset, limit];
}

class LoadActivitiesBySite extends ActivitiesEvent {
  final String view; // 'mine' or 'below'
  final bool isRefresh;

  const LoadActivitiesBySite({
    required this.view,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [view, isRefresh];
}

class ChangeActivitiesZoneFilter extends ActivitiesEvent {
  final String? zoneId;

  const ChangeActivitiesZoneFilter(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

class ChangeActivitiesClusterFilter extends ActivitiesEvent {
  final String? clusterId;

  const ChangeActivitiesClusterFilter(this.clusterId);

  @override
  List<Object?> get props => [clusterId];
}

class ChangeActivitiesStatusFilter extends ActivitiesEvent {
  final String? status;

  const ChangeActivitiesStatusFilter(this.status);

  @override
  List<Object?> get props => [status];
}

class ChangeActivitiesRoleFilter extends ActivitiesEvent {
  final String? role;

  const ChangeActivitiesRoleFilter(this.role);

  @override
  List<Object?> get props => [role];
}

class ResetActivitiesFilters extends ActivitiesEvent {
  const ResetActivitiesFilters();

  @override
  List<Object?> get props => [];
}

class SearchActivitiesQueryChanged extends ActivitiesEvent {
  final String query;

  const SearchActivitiesQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectSiteForActivities extends ActivitiesEvent {
  final ActivitySiteItemModel site;

  const SelectSiteForActivities(this.site);

  @override
  List<Object?> get props => [site];
}

class CloseSiteActivitiesDetail extends ActivitiesEvent {
  const CloseSiteActivitiesDetail();
}

class LoadSiteActivitiesPage extends ActivitiesEvent {
  final String siteId;
  final int offset;
  final int limit;

  const LoadSiteActivitiesPage({
    required this.siteId,
    this.offset = 0,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [siteId, offset, limit];
}

class SelectActivityForDetail extends ActivitiesEvent {
  final String activityId;

  const SelectActivityForDetail(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class CloseActivityDetail extends ActivitiesEvent {
  const CloseActivityDetail();
}

class SubmitActivityVisit extends ActivitiesEvent {
  final String activityId;
  final String visitDate;
  final bool clientMet;
  final String? note;

  const SubmitActivityVisit({
    required this.activityId,
    required this.visitDate,
    required this.clientMet,
    this.note,
  });

  @override
  List<Object?> get props => [activityId, visitDate, clientMet, note];
}

class SendActivityMomEmail extends ActivitiesEvent {
  final String activityId;
  final Map<String, dynamic> payload;

  const SendActivityMomEmail({
    required this.activityId,
    required this.payload,
  });

  @override
  List<Object?> get props => [activityId, payload];
}

