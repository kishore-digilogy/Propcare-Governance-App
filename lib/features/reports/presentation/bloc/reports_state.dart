import 'package:equatable/equatable.dart';

import '../../data/models/report_catalog_model.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  final ReportCatalogResponseModel catalog;
  final String selectedDateRange; // 'last_30', 'last_7', 'last_90', 'this_month', 'all'
  final String? selectedZoneId;
  final String? selectedClusterId;
  final String? selectedClientType; // 'A+', 'A', 'B', 'C'
  final String? selectedFunction;
  final String? selectedStatus;

  // Filter application loading state
  final bool isFiltering;

  // CSV download execution state
  final bool isRunningReport;
  final String? runningExportKind;
  final String? downloadedCsvContent;
  final String? downloadedReportTitle;
  final String? downloadError;

  const ReportsLoaded({
    required this.catalog,
    this.selectedDateRange = 'last_30',
    this.selectedZoneId,
    this.selectedClusterId,
    this.selectedClientType,
    this.selectedFunction,
    this.selectedStatus,
    this.isFiltering = false,
    this.isRunningReport = false,
    this.runningExportKind,
    this.downloadedCsvContent,
    this.downloadedReportTitle,
    this.downloadError,
  });

  ReportsLoaded copyWith({
    ReportCatalogResponseModel? catalog,
    String? selectedDateRange,
    String? Function()? selectedZoneId,
    String? Function()? selectedClusterId,
    String? Function()? selectedClientType,
    String? Function()? selectedFunction,
    String? Function()? selectedStatus,
    bool? isFiltering,
    bool? isRunningReport,
    String? Function()? runningExportKind,
    String? Function()? downloadedCsvContent,
    String? Function()? downloadedReportTitle,
    String? Function()? downloadError,
  }) {
    return ReportsLoaded(
      catalog: catalog ?? this.catalog,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      selectedZoneId: selectedZoneId != null ? selectedZoneId() : this.selectedZoneId,
      selectedClusterId: selectedClusterId != null ? selectedClusterId() : this.selectedClusterId,
      selectedClientType: selectedClientType != null ? selectedClientType() : this.selectedClientType,
      selectedFunction: selectedFunction != null ? selectedFunction() : this.selectedFunction,
      selectedStatus: selectedStatus != null ? selectedStatus() : this.selectedStatus,
      isFiltering: isFiltering ?? this.isFiltering,
      isRunningReport: isRunningReport ?? this.isRunningReport,
      runningExportKind: runningExportKind != null ? runningExportKind() : this.runningExportKind,
      downloadedCsvContent: downloadedCsvContent != null ? downloadedCsvContent() : this.downloadedCsvContent,
      downloadedReportTitle: downloadedReportTitle != null ? downloadedReportTitle() : this.downloadedReportTitle,
      downloadError: downloadError != null ? downloadError() : this.downloadError,
    );
  }

  @override
  List<Object?> get props => [
        catalog,
        selectedDateRange,
        selectedZoneId,
        selectedClusterId,
        selectedClientType,
        selectedFunction,
        selectedStatus,
        isFiltering,
        isRunningReport,
        runningExportKind,
        downloadedCsvContent,
        downloadedReportTitle,
        downloadError,
      ];
}

class ReportsError extends ReportsState {
  final String message;
  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

