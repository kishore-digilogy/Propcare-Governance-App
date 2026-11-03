import 'package:equatable/equatable.dart';

import '../../data/models/site_model.dart';

abstract class TransitionState extends Equatable {
  const TransitionState();

  @override
  List<Object?> get props => [];
}

class TransitionInitial extends TransitionState {
  const TransitionInitial();
}

class TransitionLoading extends TransitionState {
  const TransitionLoading();
}

class TransitionLoaded extends TransitionState {
  final List<SiteItemModel> allSites;
  final List<SiteItemModel> filteredSites;
  final String activeTab; // 'All', 'Site Creation', 'Site Live', 'Transition Complete'
  final String searchQuery;
  final bool isTableView;
  final int countAll;
  final int countSiteCreation;
  final int countSiteLive;
  final int countTransitionComplete;

  const TransitionLoaded({
    required this.allSites,
    required this.filteredSites,
    this.activeTab = 'All',
    this.searchQuery = '',
    this.isTableView = false,
    required this.countAll,
    required this.countSiteCreation,
    required this.countSiteLive,
    required this.countTransitionComplete,
  });

  TransitionLoaded copyWith({
    List<SiteItemModel>? allSites,
    List<SiteItemModel>? filteredSites,
    String? activeTab,
    String? searchQuery,
    bool? isTableView,
    int? countAll,
    int? countSiteCreation,
    int? countSiteLive,
    int? countTransitionComplete,
  }) {
    return TransitionLoaded(
      allSites: allSites ?? this.allSites,
      filteredSites: filteredSites ?? this.filteredSites,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      isTableView: isTableView ?? this.isTableView,
      countAll: countAll ?? this.countAll,
      countSiteCreation: countSiteCreation ?? this.countSiteCreation,
      countSiteLive: countSiteLive ?? this.countSiteLive,
      countTransitionComplete: countTransitionComplete ?? this.countTransitionComplete,
    );
  }

  @override
  List<Object?> get props => [
        allSites,
        filteredSites,
        activeTab,
        searchQuery,
        isTableView,
        countAll,
        countSiteCreation,
        countSiteLive,
        countTransitionComplete,
      ];
}

class TransitionError extends TransitionState {
  final String message;

  const TransitionError(this.message);

  @override
  List<Object?> get props => [message];
}

