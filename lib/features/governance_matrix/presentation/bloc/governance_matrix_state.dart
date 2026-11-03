import 'package:equatable/equatable.dart';

import '../../data/models/governance_matrix_model.dart';

abstract class GovernanceMatrixState extends Equatable {
  const GovernanceMatrixState();

  @override
  List<Object?> get props => [];
}

class GovernanceMatrixInitial extends GovernanceMatrixState {
  const GovernanceMatrixInitial();
}

class GovernanceMatrixLoading extends GovernanceMatrixState {
  const GovernanceMatrixLoading();
}

class GovernanceMatrixLoaded extends GovernanceMatrixState {
  final GovernanceMatrixResponseModel data;
  final String selectedTabKey;
  final bool isCardView;

  const GovernanceMatrixLoaded({
    required this.data,
    required this.selectedTabKey,
    this.isCardView = true,
  });

  GovernanceMatrixLoaded copyWith({
    GovernanceMatrixResponseModel? data,
    String? selectedTabKey,
    bool? isCardView,
  }) {
    return GovernanceMatrixLoaded(
      data: data ?? this.data,
      selectedTabKey: selectedTabKey ?? this.selectedTabKey,
      isCardView: isCardView ?? this.isCardView,
    );
  }

  @override
  List<Object?> get props => [data, selectedTabKey, isCardView];
}

class GovernanceMatrixError extends GovernanceMatrixState {
  final String message;
  const GovernanceMatrixError(this.message);

  @override
  List<Object?> get props => [message];
}

