import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/meta_service.dart';
import '../../data/datasources/sites_remote_datasource.dart';
import 'renewals_event.dart';
import 'renewals_state.dart';

class RenewalsBloc extends Bloc<RenewalsEvent, RenewalsState> {
  final SitesRemoteDataSource dataSource;

  RenewalsBloc({required this.dataSource}) : super(const RenewalsInitial()) {
    on<LoadRenewalSites>(_onLoadRenewalSites);
    on<ChangeRenewalWindow>(_onChangeRenewalWindow);
    on<ChangeRenewalZoneFilter>(_onChangeZoneFilter);
    on<ChangeRenewalClusterFilter>(_onChangeClusterFilter);
    on<ChangeRenewalClientTypeFilter>(_onChangeClientTypeFilter);
    on<SearchRenewalQueryChanged>(_onSearchQueryChanged);
    on<ChangeRenewalPage>(_onChangePage);
    on<ResetRenewalFilters>((event, emit) {
      if (state is RenewalsLoaded) {
        final current = state as RenewalsLoaded;
        emit(current.copyWith(
          selectedZoneId: () => null,
          selectedClusterId: () => null,
          selectedClientType: () => null,
          currentPage: 1,
        ));
        add(const LoadRenewalSites(isRefresh: true));
      }
    });
  }

  Future<void> _fetchAndEmit({
    required Emitter<RenewalsState> emit,
    required String window,
    required int page,
    String? zoneId,
    String? clusterId,
    String? clientType,
    String searchQuery = '',
  }) async {
    const limit = 20;
    final offset = (page - 1) * limit;

    try {
      final res = await dataSource.getRenewalSites(
        window: window,
        offset: offset,
        limit: limit,
        zoneId: zoneId,
        clusterId: clusterId,
        clientType: clientType,
        search: searchQuery,
      );

      emit(RenewalsLoaded(
        response: res,
        selectedWindow: window,
        selectedZoneId: zoneId,
        selectedClusterId: clusterId,
        selectedClientType: clientType,
        searchQuery: searchQuery,
        currentPage: page,
        pageSize: limit,
        isLoadingPage: false,
      ));
    } catch (e) {
      emit(RenewalsError(e.toString()));
    }
  }

  Future<void> _onLoadRenewalSites(
    LoadRenewalSites event,
    Emitter<RenewalsState> emit,
  ) async {
    MetaService.instance.fetchMetadata().catchError((_) => MetaService.instance.meta);
    final current = state;
    final window = event.window ?? (current is RenewalsLoaded ? current.selectedWindow : '30');
    final page = current is RenewalsLoaded && event.isRefresh ? current.currentPage : 1;
    final zoneId = current is RenewalsLoaded ? current.selectedZoneId : null;
    final clusterId = current is RenewalsLoaded ? current.selectedClusterId : null;
    final clientType = current is RenewalsLoaded ? current.selectedClientType : null;
    final search = current is RenewalsLoaded ? current.searchQuery : '';

    if (!event.isRefresh && current is! RenewalsLoaded) {
      emit(const RenewalsLoading());
    }

    await _fetchAndEmit(
      emit: emit,
      window: window,
      page: page,
      zoneId: zoneId,
      clusterId: clusterId,
      clientType: clientType,
      searchQuery: search,
    );
  }

  Future<void> _onChangeRenewalWindow(
    ChangeRenewalWindow event,
    Emitter<RenewalsState> emit,
  ) async {
    final current = state;
    final zoneId = current is RenewalsLoaded ? current.selectedZoneId : null;
    final clusterId = current is RenewalsLoaded ? current.selectedClusterId : null;
    final clientType = current is RenewalsLoaded ? current.selectedClientType : null;
    final search = current is RenewalsLoaded ? current.searchQuery : '';

    if (current is RenewalsLoaded) {
      emit(current.copyWith(isLoadingPage: true, selectedWindow: event.window));
    } else {
      emit(const RenewalsLoading());
    }

    await _fetchAndEmit(
      emit: emit,
      window: event.window,
      page: 1,
      zoneId: zoneId,
      clusterId: clusterId,
      clientType: clientType,
      searchQuery: search,
    );
  }

  Future<void> _onChangeZoneFilter(
    ChangeRenewalZoneFilter event,
    Emitter<RenewalsState> emit,
  ) async {
    final current = state;
    if (current is! RenewalsLoaded) return;

    emit(current.copyWith(
      selectedZoneId: () => event.zoneId,
      selectedClusterId: () => null,
      isLoadingPage: true,
      currentPage: 1,
    ));

    await _fetchAndEmit(
      emit: emit,
      window: current.selectedWindow,
      page: 1,
      zoneId: event.zoneId,
      clusterId: null,
      clientType: current.selectedClientType,
      searchQuery: current.searchQuery,
    );
  }

  Future<void> _onChangeClusterFilter(
    ChangeRenewalClusterFilter event,
    Emitter<RenewalsState> emit,
  ) async {
    final current = state;
    if (current is! RenewalsLoaded) return;

    emit(current.copyWith(
      selectedClusterId: () => event.clusterId,
      isLoadingPage: true,
      currentPage: 1,
    ));

    await _fetchAndEmit(
      emit: emit,
      window: current.selectedWindow,
      page: 1,
      zoneId: current.selectedZoneId,
      clusterId: event.clusterId,
      clientType: current.selectedClientType,
      searchQuery: current.searchQuery,
    );
  }

  Future<void> _onChangeClientTypeFilter(
    ChangeRenewalClientTypeFilter event,
    Emitter<RenewalsState> emit,
  ) async {
    final current = state;
    if (current is! RenewalsLoaded) return;

    emit(current.copyWith(
      selectedClientType: () => event.clientType,
      isLoadingPage: true,
      currentPage: 1,
    ));

    await _fetchAndEmit(
      emit: emit,
      window: current.selectedWindow,
      page: 1,
      zoneId: current.selectedZoneId,
      clusterId: current.selectedClusterId,
      clientType: event.clientType,
      searchQuery: current.searchQuery,
    );
  }

  void _onSearchQueryChanged(
    SearchRenewalQueryChanged event,
    Emitter<RenewalsState> emit,
  ) {
    final current = state;
    if (current is RenewalsLoaded) {
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onChangePage(
    ChangeRenewalPage event,
    Emitter<RenewalsState> emit,
  ) async {
    final current = state;
    if (current is! RenewalsLoaded) return;
    if (event.page < 1 || event.page > current.totalPages) return;

    emit(current.copyWith(isLoadingPage: true, currentPage: event.page));

    await _fetchAndEmit(
      emit: emit,
      window: current.selectedWindow,
      page: event.page,
      zoneId: current.selectedZoneId,
      clusterId: current.selectedClusterId,
      clientType: current.selectedClientType,
      searchQuery: current.searchQuery,
    );
  }
}

