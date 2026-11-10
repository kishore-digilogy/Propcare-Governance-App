import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/meta_service.dart';
import '../../data/datasources/sites_remote_datasource.dart';
import 'sites_event.dart';
import 'sites_state.dart';

class SitesBloc extends Bloc<SitesEvent, SitesState> {
  final SitesRemoteDataSource dataSource;

  SitesBloc({required this.dataSource}) : super(const SitesInitial()) {
    on<LoadSites>(_onLoadSites);
    on<ChangeSitesTab>(_onChangeSitesTab);
    on<ChangeZoneFilter>(_onChangeZoneFilter);
    on<ChangeClusterFilter>(_onChangeClusterFilter);
    on<ChangeStatusFilter>(_onChangeStatusFilter);
    on<ChangeClientTypeFilter>(_onChangeClientTypeFilter);
    on<ChangeModeFilter>(_onChangeModeFilter);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ChangeSitesPage>(_onChangeSitesPage);
    on<ResetSitesFilters>((event, emit) {
      if (state is SitesLoaded) {
        final current = state as SitesLoaded;
        emit(current.copyWith(
          selectedZoneId: () => null,
          selectedClusterId: () => null,
          selectedStatus: () => null,
          selectedClientType: () => null,
          selectedMode: () => null,
          currentPage: 1,
        ));
        add(const LoadSites(isRefresh: true));
      }
    });
  }

  Future<void> _fetchAndEmit({
    required Emitter<SitesState> emit,
    required int page,
    required String tab,
    String? zoneId,
    String? clusterId,
    String? status,
    String? clientType,
    String? mode,
    String searchQuery = '',
  }) async {
    const limit = 20;
    final offset = (page - 1) * limit;

    try {
      final response = await dataSource.getSites(
        offset: offset,
        limit: limit,
        zoneId: zoneId,
        clusterId: clusterId,
        clientType: clientType,
        mode: mode,
        status: status,
        search: searchQuery,
        tab: tab,
      );

      emit(SitesLoaded(
        response: response,
        selectedTab: tab,
        selectedZoneId: zoneId,
        selectedClusterId: clusterId,
        selectedStatus: status,
        selectedClientType: clientType,
        selectedMode: mode,
        searchQuery: searchQuery,
        currentPage: page,
        pageSize: limit,
        isLoadingPage: false,
      ));
    } catch (e) {
      emit(SitesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadSites(LoadSites event, Emitter<SitesState> emit) async {
    MetaService.instance.fetchMetadata().catchError((_) => MetaService.instance.meta);
    final current = state;
    if (current is SitesLoaded && !event.isRefresh) {
      emit(current.copyWith(isLoadingPage: true));
      await _fetchAndEmit(
        emit: emit,
        page: current.currentPage,
        tab: current.selectedTab,
        zoneId: event.initialZoneId ?? current.selectedZoneId,
        clusterId: event.initialClusterId ?? current.selectedClusterId,
        status: event.initialStatus ?? current.selectedStatus,
        clientType: current.selectedClientType,
        mode: current.selectedMode,
        searchQuery: current.searchQuery,
      );
    } else {
      emit(const SitesLoading());
      await _fetchAndEmit(
        emit: emit,
        page: 1,
        tab: 'All',
        zoneId: event.initialZoneId,
        clusterId: event.initialClusterId,
        status: event.initialStatus,
      );
    }
  }

  Future<void> _onChangeSitesTab(ChangeSitesTab event, Emitter<SitesState> emit) async {
    final current = state;
    if (current is SitesLoaded) {
      emit(current.copyWith(selectedTab: event.tab, currentPage: 1, isLoadingPage: true));
      await _fetchAndEmit(
        emit: emit,
        page: 1,
        tab: event.tab,
        zoneId: current.selectedZoneId,
        clusterId: current.selectedClusterId,
        status: current.selectedStatus,
        clientType: current.selectedClientType,
        mode: current.selectedMode,
        searchQuery: current.searchQuery,
      );
    }
  }

  Future<void> _onChangeZoneFilter(ChangeZoneFilter event, Emitter<SitesState> emit) async {
    final current = state;
    if (current is SitesLoaded) {
      emit(current.copyWith(
        selectedZoneId: () => event.zoneId,
        selectedClusterId: () => null,
        currentPage: 1,
        isLoadingPage: true,
      ));
      await _fetchAndEmit(
        emit: emit,
        page: 1,
        tab: current.selectedTab,
        zoneId: event.zoneId,
        clusterId: null,
        status: current.selectedStatus,
        clientType: current.selectedClientType,
        mode: current.selectedMode,
        searchQuery: current.searchQuery,
      );
    }
  }

  Future<void> _onChangeClusterFilter(ChangeClusterFilter event, Emitter<SitesState> emit) async {
    final current = state;
    if (current is SitesLoaded) {
      emit(current.copyWith(
        selectedClusterId: () => event.clusterId,
        currentPage: 1,
        isLoadingPage: true,
      ));
      await _fetchAndEmit(
        emit: emit,
        page: 1,
        tab: current.selectedTab,
        zoneId: current.selectedZoneId,
        clusterId: event.clusterId,
        status: current.selectedStatus,
        clientType: current.selectedClientType,
        mode: current.selectedMode,
        searchQuery: current.searchQuery,
      );
    }
  }

  Future<void> _onChangeStatusFilter(ChangeStatusFilter event, Emitter<SitesState> emit) async {
    final current = state;
    if (current is SitesLoaded) {
      emit(current.copyWith(
        selectedStatus: () => event.status,
        currentPage: 1,
        isLoadingPage: true,
      ));
      await _fetchAndEmit(
        emit: emit,
        page: 1,
        tab: current.selectedTab,
        zoneId: current.selectedZoneId,
        clusterId: current.selectedClusterId,
        status: event.status,
        clientType: current.selectedClientType,
        mode: current.selectedMode,
        searchQuery: current.searchQuery,
      );
    }
  }

  Future<void> _onChangeClientTypeFilter(ChangeClientTypeFilter event, Emitter<SitesState> emit) async {
    final current = state;
    if (current is SitesLoaded) {
      emit(current.copyWith(
        selectedClientType: () => event.clientType,
        currentPage: 1,
        isLoadingPage: true,
      ));
      await _fetchAndEmit(
        emit: emit,
        page: 1,
        tab: current.selectedTab,
        zoneId: current.selectedZoneId,
        clusterId: current.selectedClusterId,
        status: current.selectedStatus,
        clientType: event.clientType,
        mode: current.selectedMode,
        searchQuery: current.searchQuery,
      );
    }
  }

  Future<void> _onChangeModeFilter(ChangeModeFilter event, Emitter<SitesState> emit) async {
    final current = state;
    if (current is SitesLoaded) {
      emit(current.copyWith(
        selectedMode: () => event.mode,
        currentPage: 1,
        isLoadingPage: true,
      ));
      await _fetchAndEmit(
        emit: emit,
        page: 1,
        tab: current.selectedTab,
        zoneId: current.selectedZoneId,
        clusterId: current.selectedClusterId,
        status: current.selectedStatus,
        clientType: current.selectedClientType,
        mode: event.mode,
        searchQuery: current.searchQuery,
      );
    }
  }

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<SitesState> emit) {
    final current = state;
    if (current is SitesLoaded) {
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onChangeSitesPage(ChangeSitesPage event, Emitter<SitesState> emit) async {
    final current = state;
    if (current is SitesLoaded && event.page != current.currentPage) {
      emit(current.copyWith(currentPage: event.page, isLoadingPage: true));
      await _fetchAndEmit(
        emit: emit,
        page: event.page,
        tab: current.selectedTab,
        zoneId: current.selectedZoneId,
        clusterId: current.selectedClusterId,
        status: current.selectedStatus,
        clientType: current.selectedClientType,
        mode: current.selectedMode,
        searchQuery: current.searchQuery,
      );
    }
  }
}
