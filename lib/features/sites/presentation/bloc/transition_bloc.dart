import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/sites_remote_datasource.dart';
import '../../data/models/site_model.dart';
import 'transition_event.dart';
import 'transition_state.dart';

class TransitionBloc extends Bloc<TransitionEvent, TransitionState> {
  final SitesRemoteDataSource dataSource;

  TransitionBloc({required this.dataSource}) : super(const TransitionInitial()) {
    on<LoadTransitionSites>(_onLoadSites);
    on<ChangeTransitionTab>(_onChangeTab);
    on<ChangeTransitionSearch>(_onChangeSearch);
    on<ToggleTransitionViewMode>(_onToggleViewMode);
  }

  Future<void> _onLoadSites(
    LoadTransitionSites event,
    Emitter<TransitionState> emit,
  ) async {
    final currentState = state;
    if (!event.isRefresh) {
      emit(const TransitionLoading());
    }

    try {
      final response = await dataSource.getSites(
        limit: 100,
        offset: 0,
      );

      final sites = response.items;

      final countAll = sites.length;
      final countSiteCreation = sites.where((s) => s.isSiteCreation).length;
      final countTransitionComplete = sites.where((s) => s.isTransitionComplete).length;
      final countSiteLive = sites.where((s) => s.isSiteLive).length;

      final activeTab = currentState is TransitionLoaded ? currentState.activeTab : 'All';
      final searchQuery = currentState is TransitionLoaded ? currentState.searchQuery : '';
      final isTableView = currentState is TransitionLoaded ? currentState.isTableView : false;

      final filtered = _applyFilter(sites, activeTab, searchQuery);

      emit(TransitionLoaded(
        allSites: sites,
        filteredSites: filtered,
        activeTab: activeTab,
        searchQuery: searchQuery,
        isTableView: isTableView,
        countAll: countAll,
        countSiteCreation: countSiteCreation,
        countSiteLive: countSiteLive,
        countTransitionComplete: countTransitionComplete,
      ));
    } catch (e) {
      emit(TransitionError('Failed to load transition sites: $e'));
    }
  }

  void _onChangeTab(
    ChangeTransitionTab event,
    Emitter<TransitionState> emit,
  ) {
    if (state is! TransitionLoaded) return;
    final current = state as TransitionLoaded;

    final filtered = _applyFilter(current.allSites, event.tab, current.searchQuery);
    emit(current.copyWith(
      activeTab: event.tab,
      filteredSites: filtered,
    ));
  }

  void _onChangeSearch(
    ChangeTransitionSearch event,
    Emitter<TransitionState> emit,
  ) {
    if (state is! TransitionLoaded) return;
    final current = state as TransitionLoaded;

    final filtered = _applyFilter(current.allSites, current.activeTab, event.query);
    emit(current.copyWith(
      searchQuery: event.query,
      filteredSites: filtered,
    ));
  }

  void _onToggleViewMode(
    ToggleTransitionViewMode event,
    Emitter<TransitionState> emit,
  ) {
    if (state is! TransitionLoaded) return;
    final current = state as TransitionLoaded;
    emit(current.copyWith(isTableView: event.isTableView));
  }

  List<SiteItemModel> _applyFilter(
    List<SiteItemModel> sites,
    String tab,
    String query,
  ) {
    var result = sites;

    // 1. Stage tab filter
    if (tab == 'Site Creation') {
      result = result.where((s) => s.isSiteCreation).toList();
    } else if (tab == 'Site Live') {
      result = result.where((s) => s.isSiteLive).toList();
    } else if (tab == 'Transition Complete') {
      result = result.where((s) => s.isTransitionComplete).toList();
    }

    // 2. Search query filter
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((s) {
        final name = s.name.toLowerCase();
        final code = s.code.toLowerCase();
        final client = s.clientName.toLowerCase();
        final city = (s.city ?? '').toLowerCase();
        return name.contains(q) || code.contains(q) || client.contains(q) || city.contains(q);
      }).toList();
    }

    return result;
  }
}

