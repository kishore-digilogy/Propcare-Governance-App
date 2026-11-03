import 'package:equatable/equatable.dart';

import '../../data/models/transition_detail_model.dart';

abstract class TransitionDetailState extends Equatable {
  const TransitionDetailState();

  @override
  List<Object?> get props => [];
}

class TransitionDetailInitial extends TransitionDetailState {
  const TransitionDetailInitial();
}

class TransitionDetailLoading extends TransitionDetailState {
  const TransitionDetailLoading();
}

class TransitionDetailLoaded extends TransitionDetailState {
  final TransitionSiteDetailResponseModel response;
  final int selectedStep; // 1 = Site Creation, 2 = Internal Checklist, 3 = L&D Checklist, 4 = Stability Verify

  const TransitionDetailLoaded({
    required this.response,
    this.selectedStep = 2,
  });

  TransitionDetailLoaded copyWith({
    TransitionSiteDetailResponseModel? response,
    int? selectedStep,
  }) {
    return TransitionDetailLoaded(
      response: response ?? this.response,
      selectedStep: selectedStep ?? this.selectedStep,
    );
  }

  @override
  List<Object?> get props => [response, selectedStep];
}

class TransitionDetailError extends TransitionDetailState {
  final String message;

  const TransitionDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

