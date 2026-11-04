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
  final int step; // 1 = Internal Checklist, 2 = L&D Checklist, 3 = Stability Verify

  const SelectTransitionStep(this.step);

  @override
  List<Object?> get props => [step];
}

class UpdateKickoffField extends TransitionDetailEvent {
  final String? withClient;
  final String? date;
  final List<String>? participants;
  final String? meeting;

  const UpdateKickoffField({
    this.withClient,
    this.date,
    this.participants,
    this.meeting,
  });

  @override
  List<Object?> get props => [withClient, date, participants, meeting];
}

class UpdateChecklistItemEvent extends TransitionDetailEvent {
  final String phase;
  final String key;
  final String status;
  final bool done;
  final String? startDate;
  final String? endDate;

  const UpdateChecklistItemEvent({
    required this.phase,
    required this.key,
    required this.status,
    required this.done,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [phase, key, status, done, startDate, endDate];
}

class SaveTransitionActionEvent extends TransitionDetailEvent {
  final String siteId;
  final String action; // 'save' | 'stability' | 'verify'

  const SaveTransitionActionEvent({
    required this.siteId,
    required this.action,
  });

  @override
  List<Object?> get props => [siteId, action];
}

class RaiseTransitionIssueEvent extends TransitionDetailEvent {
  final String siteId;
  final String phase;
  final String key;
  final String issue;
  final String ownerId;
  final String remarks;

  const RaiseTransitionIssueEvent({
    required this.siteId,
    required this.phase,
    required this.key,
    required this.issue,
    required this.ownerId,
    required this.remarks,
  });

  @override
  List<Object?> get props => [siteId, phase, key, issue, ownerId, remarks];
}

