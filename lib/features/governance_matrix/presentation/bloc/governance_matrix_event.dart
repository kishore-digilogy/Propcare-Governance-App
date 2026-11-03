import 'package:equatable/equatable.dart';

abstract class GovernanceMatrixEvent extends Equatable {
  const GovernanceMatrixEvent();

  @override
  List<Object?> get props => [];
}

class LoadGovernanceMatrix extends GovernanceMatrixEvent {
  final bool isRefresh;
  const LoadGovernanceMatrix({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class SelectTab extends GovernanceMatrixEvent {
  final String tabKey;
  const SelectTab(this.tabKey);

  @override
  List<Object?> get props => [tabKey];
}

class ToggleViewMode extends GovernanceMatrixEvent {
  final bool isCardView;
  const ToggleViewMode(this.isCardView);

  @override
  List<Object?> get props => [isCardView];
}

