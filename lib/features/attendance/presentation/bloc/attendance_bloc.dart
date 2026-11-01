import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/models/site_activity_model.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRemoteDataSource _dataSource;

  AttendanceBloc({AttendanceRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? AttendanceRemoteDataSourceImpl(),
        super(const AttendanceInitial()) {
    on<LoadAttendance>(_onLoadAttendance);
    on<RefreshAttendance>(_onRefreshAttendance);
    on<SearchAttendanceSites>(_onSearchAttendanceSites);
    on<ChangeAttendancePage>(_onChangeAttendancePage);
    on<SelectAttendanceSite>(_onSelectAttendanceSite);
    on<BackToSitesList>(_onBackToSitesList);
    on<SearchSiteActivities>(_onSearchSiteActivities);
    on<ChangeActivitiesPage>(_onChangeActivitiesPage);
  }

  Future<void> _onLoadAttendance(
    LoadAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      final data = await _dataSource.getAttendanceBySite();
      emit(AttendanceLoaded(data: data));
    } catch (e, stack) {
      developer.log('Error loading attendance', error: e, stackTrace: stack);
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onRefreshAttendance(
    RefreshAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final current = state;
      final data = await _dataSource.getAttendanceBySite();

      if (current is AttendanceLoaded && current.selectedSite != null) {
        final site = current.selectedSite!;
        final activities = await _dataSource.getSiteActivities(
          siteId: site.siteId,
        );
        emit(current.copyWith(
          data: data,
          activitiesData: () => activities,
        ));
      } else if (current is AttendanceLoaded) {
        emit(current.copyWith(data: data));
      } else {
        emit(AttendanceLoaded(data: data));
      }
    } catch (e) {
      // Don't show error screen on pull-to-refresh if already loaded
      if (state is! AttendanceLoaded) {
        emit(AttendanceError(e.toString()));
      }
    }
  }

  void _onSearchAttendanceSites(
    SearchAttendanceSites event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(
        siteSearchQuery: event.query,
        sitesCurrentPage: 1,
      ));
    }
  }

  void _onChangeAttendancePage(
    ChangeAttendancePage event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(sitesCurrentPage: event.page));
    }
  }

  Future<void> _onSelectAttendanceSite(
    SelectAttendanceSite event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is! AttendanceLoaded) return;
    final current = state as AttendanceLoaded;

    emit(current.copyWith(
      selectedSite: () => event.site,
      isActivitiesLoading: true,
      activitySearchQuery: '',
      activitiesCurrentPage: 1,
      activitiesData: () => null,
    ));

    try {
      final activities = await _dataSource.getSiteActivities(
        siteId: event.site.siteId,
      );
      if (state is AttendanceLoaded) {
        final latest = state as AttendanceLoaded;
        emit(latest.copyWith(
          selectedSite: () => event.site,
          isActivitiesLoading: false,
          activitiesData: () => activities,
        ));
      }
    } catch (e, stack) {
      developer.log(
        'Error loading site activities for ${event.site.siteName}',
        error: e,
        stackTrace: stack,
      );
      if (state is AttendanceLoaded) {
        final latest = state as AttendanceLoaded;
        emit(latest.copyWith(
          selectedSite: () => event.site,
          isActivitiesLoading: false,
          activitiesData: () => SiteActivitiesResponseModel.empty,
        ));
      }
    }
  }

  void _onBackToSitesList(
    BackToSitesList event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(
        selectedSite: () => null,
        activitiesData: () => null,
        activitySearchQuery: '',
        activitiesCurrentPage: 1,
      ));
    }
  }

  void _onSearchSiteActivities(
    SearchSiteActivities event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(
        activitySearchQuery: event.query,
        activitiesCurrentPage: 1,
      ));
    }
  }

  void _onChangeActivitiesPage(
    ChangeActivitiesPage event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(activitiesCurrentPage: event.page));
    }
  }
}
