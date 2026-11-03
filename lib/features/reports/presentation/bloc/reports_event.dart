import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportCatalog extends ReportsEvent {
  final bool isRefresh;
  const LoadReportCatalog({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class ChangeDateRange extends ReportsEvent {
  final String dateRange;
  const ChangeDateRange(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

class ChangeZoneFilter extends ReportsEvent {
  final String? zoneId;
  const ChangeZoneFilter(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

class ChangeClusterFilter extends ReportsEvent {
  final String? clusterId;
  const ChangeClusterFilter(this.clusterId);

  @override
  List<Object?> get props => [clusterId];
}

class ChangeClientTypeFilter extends ReportsEvent {
  final String? clientType;
  const ChangeClientTypeFilter(this.clientType);

  @override
  List<Object?> get props => [clientType];
}

class ChangeFunctionFilter extends ReportsEvent {
  final String? function;
  const ChangeFunctionFilter(this.function);

  @override
  List<Object?> get props => [function];
}

class ChangeStatusFilter extends ReportsEvent {
  final String? status;
  const ChangeStatusFilter(this.status);

  @override
  List<Object?> get props => [status];
}

class RunReportCsv extends ReportsEvent {
  final String exportKind;
  final String reportTitle;
  const RunReportCsv({required this.exportKind, required this.reportTitle});

  @override
  List<Object?> get props => [exportKind, reportTitle];
}

class DismissCsvPreview extends ReportsEvent {
  const DismissCsvPreview();
}

class ResetAllReportFilters extends ReportsEvent {
  const ResetAllReportFilters();
}

