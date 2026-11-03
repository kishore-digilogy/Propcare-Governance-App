import 'package:equatable/equatable.dart';

abstract class SitesEvent extends Equatable {
  const SitesEvent();

  @override
  List<Object?> get props => [];
}

class LoadSites extends SitesEvent {
  final bool isRefresh;

  const LoadSites({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class ChangeSitesTab extends SitesEvent {
  final String tab;

  const ChangeSitesTab(this.tab);

  @override
  List<Object?> get props => [tab];
}

class ChangeZoneFilter extends SitesEvent {
  final String? zoneId;

  const ChangeZoneFilter(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

class ChangeClusterFilter extends SitesEvent {
  final String? clusterId;

  const ChangeClusterFilter(this.clusterId);

  @override
  List<Object?> get props => [clusterId];
}

class ChangeStatusFilter extends SitesEvent {
  final String? status;

  const ChangeStatusFilter(this.status);

  @override
  List<Object?> get props => [status];
}

class ChangeClientTypeFilter extends SitesEvent {
  final String? clientType;

  const ChangeClientTypeFilter(this.clientType);

  @override
  List<Object?> get props => [clientType];
}

class ChangeModeFilter extends SitesEvent {
  final String? mode;

  const ChangeModeFilter(this.mode);

  @override
  List<Object?> get props => [mode];
}

class SearchQueryChanged extends SitesEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ChangeSitesPage extends SitesEvent {
  final int page;

  const ChangeSitesPage(this.page);

  @override
  List<Object?> get props => [page];
}

class ResetSitesFilters extends SitesEvent {
  const ResetSitesFilters();
}

