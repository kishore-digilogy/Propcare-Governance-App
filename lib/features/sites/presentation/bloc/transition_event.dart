import 'package:equatable/equatable.dart';

abstract class TransitionEvent extends Equatable {
  const TransitionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransitionSites extends TransitionEvent {
  final bool isRefresh;

  const LoadTransitionSites({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class ChangeTransitionTab extends TransitionEvent {
  final String tab;

  const ChangeTransitionTab(this.tab);

  @override
  List<Object?> get props => [tab];
}

class ChangeTransitionSearch extends TransitionEvent {
  final String query;

  const ChangeTransitionSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class ToggleTransitionViewMode extends TransitionEvent {
  final bool isTableView;

  const ToggleTransitionViewMode(this.isTableView);

  @override
  List<Object?> get props => [isTableView];
}

