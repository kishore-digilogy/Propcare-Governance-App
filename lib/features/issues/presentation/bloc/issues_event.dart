import 'package:equatable/equatable.dart';

abstract class IssuesEvent extends Equatable {
  const IssuesEvent();

  @override
  List<Object?> get props => [];
}

class LoadIssues extends IssuesEvent {
  final bool isRefresh;
  const LoadIssues({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class ChangeIssuesPage extends IssuesEvent {
  final int page;
  const ChangeIssuesPage(this.page);

  @override
  List<Object?> get props => [page];
}

class FilterZoneChanged extends IssuesEvent {
  final String? zoneId;
  const FilterZoneChanged(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

class FilterClusterChanged extends IssuesEvent {
  final String? clusterId;
  const FilterClusterChanged(this.clusterId);

  @override
  List<Object?> get props => [clusterId];
}

class FilterSiteChanged extends IssuesEvent {
  final String? siteId;
  const FilterSiteChanged(this.siteId);

  @override
  List<Object?> get props => [siteId];
}

class FilterStatusChanged extends IssuesEvent {
  final String? status;
  const FilterStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class SearchIssuesQueryChanged extends IssuesEvent {
  final String query;
  const SearchIssuesQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class OpenIssueDetail extends IssuesEvent {
  final String issueId;
  const OpenIssueDetail(this.issueId);

  @override
  List<Object?> get props => [issueId];
}

class BackToIssuesList extends IssuesEvent {
  const BackToIssuesList();
}

class CreateIssueSubmitted extends IssuesEvent {
  final Map<String, dynamic> payload;
  const CreateIssueSubmitted(this.payload);

  @override
  List<Object?> get props => [payload];
}

class UpdateIssueSubmitted extends IssuesEvent {
  final String issueId;
  final Map<String, dynamic> payload;
  const UpdateIssueSubmitted({
    required this.issueId,
    required this.payload,
  });

  @override
  List<Object?> get props => [issueId, payload];
}

class AddActionPointSubmitted extends IssuesEvent {
  final String issueId;
  final Map<String, dynamic> payload;
  const AddActionPointSubmitted({
    required this.issueId,
    required this.payload,
  });

  @override
  List<Object?> get props => [issueId, payload];
}

class ClearIssueFeedback extends IssuesEvent {
  const ClearIssueFeedback();

  @override
  List<Object?> get props => [];
}

