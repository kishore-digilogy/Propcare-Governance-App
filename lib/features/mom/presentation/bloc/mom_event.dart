import 'package:equatable/equatable.dart';

import '../../data/models/mom_activity_model.dart';
import '../../data/models/mom_by_site_model.dart';

abstract class MomEvent extends Equatable {
  const MomEvent();

  @override
  List<Object?> get props => [];
}

class LoadMomBySite extends MomEvent {
  final bool isRefresh;
  const LoadMomBySite({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class ChangeMomTab extends MomEvent {
  final int tabIndex; // 0: Pending, 1: Completed
  const ChangeMomTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class SearchMomQueryChanged extends MomEvent {
  final String query;
  const SearchMomQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectMomSite extends MomEvent {
  final MomSiteItemModel site;
  const SelectMomSite(this.site);

  @override
  List<Object?> get props => [site];
}

class BackToMomSitesList extends MomEvent {
  const BackToMomSitesList();
}

class SelectMomActivity extends MomEvent {
  final MomActivityModel activity;
  const SelectMomActivity(this.activity);

  @override
  List<Object?> get props => [activity];
}

class SendMomEmailAction extends MomEvent {
  final String activityId;
  final Map<String, dynamic> payload;

  const SendMomEmailAction({
    required this.activityId,
    required this.payload,
  });

  @override
  List<Object?> get props => [activityId, payload];
}
