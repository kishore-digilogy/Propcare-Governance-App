import 'package:equatable/equatable.dart';

abstract class MomEvent extends Equatable {
  const MomEvent();

  @override
  List<Object?> get props => [];
}

class LoadMomBySite extends MomEvent {
  final bool isRefresh;
  const LoadMomBySite({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class ChangeMomTab extends MomEvent {
  final int tabIndex; // 0: Pending, 1: Completed
  const ChangeMomTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class SearchMomQueryChanged extends MomEvent {
  final String query;
  const SearchMomQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

