import 'package:equatable/equatable.dart';

abstract class SiteDetailEvent extends Equatable {
  const SiteDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadSiteDetail extends SiteDetailEvent {
  final String siteId;

  const LoadSiteDetail(this.siteId);

  @override
  List<Object?> get props => [siteId];
}

class SubmitSpecialAttention extends SiteDetailEvent {
  final String siteId;
  final bool enabled;
  final String fromDate;
  final String toDate;
  final String reason;

  const SubmitSpecialAttention({
    required this.siteId,
    required this.enabled,
    required this.fromDate,
    required this.toDate,
    required this.reason,
  });

  @override
  List<Object?> get props => [siteId, enabled, fromDate, toDate, reason];
}

class SubmitClassification extends SiteDetailEvent {
  final String siteId;
  final String clientType;
  final String effectiveDate;
  final String reason;

  const SubmitClassification({
    required this.siteId,
    required this.clientType,
    required this.effectiveDate,
    required this.reason,
  });

  @override
  List<Object?> get props => [siteId, clientType, effectiveDate, reason];
}

class SubmitLifecycle extends SiteDetailEvent {
  final String siteId;
  final String action;
  final String reason;

  const SubmitLifecycle({
    required this.siteId,
    required this.action,
    required this.reason,
  });

  @override
  List<Object?> get props => [siteId, action, reason];
}

