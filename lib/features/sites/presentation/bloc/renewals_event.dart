import 'package:equatable/equatable.dart';

abstract class RenewalsEvent extends Equatable {
  const RenewalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadRenewalSites extends RenewalsEvent {
  final bool isRefresh;
  final String? window;

  const LoadRenewalSites({this.isRefresh = false, this.window});

  @override
  List<Object?> get props => [isRefresh, window];
}

class ChangeRenewalWindow extends RenewalsEvent {
  final String window;

  const ChangeRenewalWindow(this.window);

  @override
  List<Object?> get props => [window];
}

class ChangeRenewalZoneFilter extends RenewalsEvent {
  final String? zoneId;

  const ChangeRenewalZoneFilter(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

class ChangeRenewalClusterFilter extends RenewalsEvent {
  final String? clusterId;

  const ChangeRenewalClusterFilter(this.clusterId);

  @override
  List<Object?> get props => [clusterId];
}

class ChangeRenewalClientTypeFilter extends RenewalsEvent {
  final String? clientType;

  const ChangeRenewalClientTypeFilter(this.clientType);

  @override
  List<Object?> get props => [clientType];
}

class SearchRenewalQueryChanged extends RenewalsEvent {
  final String query;

  const SearchRenewalQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ChangeRenewalPage extends RenewalsEvent {
  final int page;

  const ChangeRenewalPage(this.page);

  @override
  List<Object?> get props => [page];
}

class ResetRenewalFilters extends RenewalsEvent {
  const ResetRenewalFilters();
}

