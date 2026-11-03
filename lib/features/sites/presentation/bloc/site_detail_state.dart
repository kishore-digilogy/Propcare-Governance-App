import 'package:equatable/equatable.dart';

import '../../data/models/site_detail_model.dart';

abstract class SiteDetailState extends Equatable {
  const SiteDetailState();

  @override
  List<Object?> get props => [];
}

class SiteDetailInitial extends SiteDetailState {
  const SiteDetailInitial();
}

class SiteDetailLoading extends SiteDetailState {
  const SiteDetailLoading();
}

class SiteDetailLoaded extends SiteDetailState {
  final SiteDetailResponseModel detail;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  const SiteDetailLoaded({
    required this.detail,
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
  });

  SiteDetailLoaded copyWith({
    SiteDetailResponseModel? detail,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
  }) {
    return SiteDetailLoaded(
      detail: detail ?? this.detail,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [detail, isSubmitting, successMessage, errorMessage];
}

class SiteDetailError extends SiteDetailState {
  final String message;

  const SiteDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

