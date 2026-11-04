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
  final int selectedStep; // 1 = Internal Checklist, 2 = L&D Checklist, 3 = Stability Verify
  final bool isSaving;
  final String? actionMessage;
  final String? errorMessage;

  const TransitionDetailLoaded({
    required this.response,
    this.selectedStep = 1,
    this.isSaving = false,
    this.actionMessage,
    this.errorMessage,
  });

  TransitionDetailLoaded copyWith({
    TransitionSiteDetailResponseModel? response,
    int? selectedStep,
    bool? isSaving,
    String? actionMessage,
    String? errorMessage,
  }) {
    return TransitionDetailLoaded(
      response: response ?? this.response,
      selectedStep: selectedStep ?? this.selectedStep,
      isSaving: isSaving ?? this.isSaving,
      actionMessage: actionMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        response,
        selectedStep,
        isSaving,
        actionMessage,
        errorMessage,
      ];
}

class TransitionDetailError extends TransitionDetailState {
  final String message;

  const TransitionDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

