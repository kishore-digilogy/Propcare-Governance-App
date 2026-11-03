import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/meta_service.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRemoteDataSource dataSource;

  ReportsBloc({required this.dataSource}) : super(const ReportsInitial()) {
    on<LoadReportCatalog>(_onLoadReportCatalog);
    on<ChangeDateRange>(_onChangeDateRange);
    on<ChangeZoneFilter>(_onChangeZoneFilter);
    on<ChangeClusterFilter>(_onChangeClusterFilter);
    on<ChangeClientTypeFilter>(_onChangeClientTypeFilter);
    on<ChangeFunctionFilter>(_onChangeFunctionFilter);
    on<ChangeStatusFilter>(_onChangeStatusFilter);
    on<RunReportCsv>(_onRunReportCsv);
    on<DismissCsvPreview>(_onDismissCsvPreview);
    on<ResetAllReportFilters>(_onResetAllReportFilters);
  }

  Future<void> _onLoadReportCatalog(
    LoadReportCatalog event,
    Emitter<ReportsState> emit,
  ) async {
    final current = state;
    if (!event.isRefresh || current is! ReportsLoaded) {
      emit(const ReportsLoading());
    }

    // Prefetch metadata if needed
    MetaService.instance.fetchMetadata().catchError((_) => MetaService.instance.meta);

    final dateRange = current is ReportsLoaded ? current.selectedDateRange : 'last_30';
    final zoneId = current is ReportsLoaded ? current.selectedZoneId : null;
    final clusterId = current is ReportsLoaded ? current.selectedClusterId : null;
    final clientType = current is ReportsLoaded ? current.selectedClientType : null;
    final function = current is ReportsLoaded ? current.selectedFunction : null;
    final status = current is ReportsLoaded ? current.selectedStatus : null;

    try {
      final res = await dataSource.getReportCatalog(
        dateRange: dateRange,
        zoneId: zoneId,
        clusterId: clusterId,
        clientType: clientType,
        function: function,
        status: status,
      );

      if (state is ReportsLoaded) {
        final latest = state as ReportsLoaded;
        emit(latest.copyWith(catalog: res));
      } else {
        emit(
          ReportsLoaded(
            catalog: res,
            selectedDateRange: dateRange,
            selectedZoneId: zoneId,
            selectedClusterId: clusterId,
            selectedClientType: clientType,
            selectedFunction: function,
            selectedStatus: status,
          ),
        );
      }
    } on DioException catch (e) {
      developer.log('Failed to load reports catalog: ${e.message}', name: 'Reports');
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? e.message)
          : e.message;
      emit(ReportsError(msg?.toString() ?? 'Failed to load reports catalog.'));
    } catch (e) {
      developer.log('Failed to load reports catalog: $e', name: 'Reports');
      emit(ReportsError(e.toString()));
    }
  }

  void _onChangeDateRange(ChangeDateRange event, Emitter<ReportsState> emit) {
    if (state is! ReportsLoaded) return;
    final current = state as ReportsLoaded;
    emit(current.copyWith(selectedDateRange: event.dateRange));
    add(const LoadReportCatalog(isRefresh: true));
  }

  void _onChangeZoneFilter(ChangeZoneFilter event, Emitter<ReportsState> emit) {
    if (state is! ReportsLoaded) return;
    final current = state as ReportsLoaded;
    emit(current.copyWith(
      selectedZoneId: () => event.zoneId,
      selectedClusterId: () => null, // reset dependent cluster
    ));
    add(const LoadReportCatalog(isRefresh: true));
  }

  void _onChangeClusterFilter(ChangeClusterFilter event, Emitter<ReportsState> emit) {
    if (state is! ReportsLoaded) return;
    final current = state as ReportsLoaded;
    emit(current.copyWith(selectedClusterId: () => event.clusterId));
    add(const LoadReportCatalog(isRefresh: true));
  }

  void _onChangeClientTypeFilter(ChangeClientTypeFilter event, Emitter<ReportsState> emit) {
    if (state is! ReportsLoaded) return;
    final current = state as ReportsLoaded;
    emit(current.copyWith(selectedClientType: () => event.clientType));
    add(const LoadReportCatalog(isRefresh: true));
  }

  void _onChangeFunctionFilter(ChangeFunctionFilter event, Emitter<ReportsState> emit) {
    if (state is! ReportsLoaded) return;
    final current = state as ReportsLoaded;
    emit(current.copyWith(selectedFunction: () => event.function));
    add(const LoadReportCatalog(isRefresh: true));
  }

  void _onChangeStatusFilter(ChangeStatusFilter event, Emitter<ReportsState> emit) {
    if (state is! ReportsLoaded) return;
    final current = state as ReportsLoaded;
    emit(current.copyWith(selectedStatus: () => event.status));
    add(const LoadReportCatalog(isRefresh: true));
  }

  Future<void> _onRunReportCsv(RunReportCsv event, Emitter<ReportsState> emit) async {
    if (state is! ReportsLoaded) return;
    final current = state as ReportsLoaded;

    emit(current.copyWith(
      isRunningReport: true,
      runningExportKind: () => event.exportKind,
      downloadError: () => null,
    ));

    try {
      final csv = await dataSource.downloadReportCsv(
        exportKind: event.exportKind,
        dateRange: current.selectedDateRange,
        zoneId: current.selectedZoneId,
        clusterId: current.selectedClusterId,
        clientType: current.selectedClientType,
        function: current.selectedFunction,
        status: current.selectedStatus,
      );

      if (state is ReportsLoaded) {
        final latest = state as ReportsLoaded;
        emit(latest.copyWith(
          isRunningReport: false,
          runningExportKind: () => null,
          downloadedCsvContent: () => csv,
          downloadedReportTitle: () => event.reportTitle,
        ));
      }
    } catch (e) {
      if (state is ReportsLoaded) {
        final latest = state as ReportsLoaded;
        emit(latest.copyWith(
          isRunningReport: false,
          runningExportKind: () => null,
          downloadError: () => 'Failed to export CSV: $e',
        ));
      }
    }
  }

  void _onDismissCsvPreview(DismissCsvPreview event, Emitter<ReportsState> emit) {
    if (state is ReportsLoaded) {
      final current = state as ReportsLoaded;
      emit(current.copyWith(
        downloadedCsvContent: () => null,
        downloadedReportTitle: () => null,
        downloadError: () => null,
      ));
    }
  }

  void _onResetAllReportFilters(ResetAllReportFilters event, Emitter<ReportsState> emit) {
    if (state is! ReportsLoaded) return;
    final current = state as ReportsLoaded;
    emit(current.copyWith(
      selectedDateRange: 'last_30',
      selectedZoneId: () => null,
      selectedClusterId: () => null,
      selectedClientType: () => null,
      selectedFunction: () => null,
      selectedStatus: () => null,
    ));
    add(const LoadReportCatalog(isRefresh: true));
  }
}

