import 'package:equatable/equatable.dart';

import '../../data/models/attendance_site_model.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendance extends AttendanceEvent {
  const LoadAttendance();
}

class RefreshAttendance extends AttendanceEvent {
  const RefreshAttendance();
}

class SearchAttendanceSites extends AttendanceEvent {
  final String query;
  const SearchAttendanceSites(this.query);

  @override
  List<Object?> get props => [query];
}

class ChangeAttendancePage extends AttendanceEvent {
  final int page;
  const ChangeAttendancePage(this.page);

  @override
  List<Object?> get props => [page];
}

class SelectAttendanceSite extends AttendanceEvent {
  final AttendanceSiteItemModel site;
  const SelectAttendanceSite(this.site);

  @override
  List<Object?> get props => [site];
}

class BackToSitesList extends AttendanceEvent {
  const BackToSitesList();
}

class SearchSiteActivities extends AttendanceEvent {
  final String query;
  const SearchSiteActivities(this.query);

  @override
  List<Object?> get props => [query];
}

class ChangeActivitiesPage extends AttendanceEvent {
  final int page;
  const ChangeActivitiesPage(this.page);

  @override
  List<Object?> get props => [page];
}

