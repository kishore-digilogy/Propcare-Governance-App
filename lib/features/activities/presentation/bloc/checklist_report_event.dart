import 'package:equatable/equatable.dart';

abstract class ChecklistReportEvent extends Equatable {
  const ChecklistReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadChecklistReport extends ChecklistReportEvent {
  final bool isRefresh;
  const LoadChecklistReport({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class SearchChecklistReport extends ChecklistReportEvent {
  final String query;
  const SearchChecklistReport(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadSiteChecklistDetail extends ChecklistReportEvent {
  final String siteId;
  final String? initialActivityId;

  const LoadSiteChecklistDetail({
    required this.siteId,
    this.initialActivityId,
  });

  @override
  List<Object?> get props => [siteId, initialActivityId];
}

class SelectVisitDate extends ChecklistReportEvent {
  final String activityId;

  const SelectVisitDate(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class UpdateChecklistAnswer extends ChecklistReportEvent {
  final String key;
  final String? status; // 'OK', 'ISSUE', 'NA'
  final String? remarks;

  const UpdateChecklistAnswer({
    required this.key,
    this.status,
    this.remarks,
  });

  @override
  List<Object?> get props => [key, status, remarks];
}

class SaveCurrentChecklist extends ChecklistReportEvent {
  const SaveCurrentChecklist();
}

