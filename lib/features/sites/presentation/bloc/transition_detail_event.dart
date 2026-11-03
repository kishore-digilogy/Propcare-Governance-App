import 'package:equatable/equatable.dart';

abstract class TransitionDetailEvent extends Equatable {
  const TransitionDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransitionDetail extends TransitionDetailEvent {
  final String siteId;
  final bool isRefresh;

  const LoadTransitionDetail({
    required this.siteId,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [siteId, isRefresh];
}

class SelectTransitionStep extends TransitionDetailEvent {
  final int step; // 1, 2, 3, 4

  const SelectTransitionStep(this.step);

  @override
  List<Object?> get props => [step];
}

