import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/mom_remote_datasource.dart';
import '../../data/models/mom_activity_model.dart';
import 'mom_event.dart';
import 'mom_state.dart';

class MomBloc extends Bloc<MomEvent, MomState> {
  final MomRemoteDataSource dataSource;

  MomBloc({required this.dataSource}) : super(const MomInitial()) {
    on<LoadMomBySite>(_onLoadMomBySite);
    on<ChangeMomTab>(_onChangeMomTab);
    on<SearchMomQueryChanged>(_onSearchMomQueryChanged);
    on<SelectMomSite>(_onSelectMomSite);
    on<BackToMomSitesList>(_onBackToMomSitesList);
    on<SelectMomActivity>(_onSelectMomActivity);
    on<SendMomEmailAction>(_onSendMomEmailAction);
  }

  Future<void> _onLoadMomBySite(
    LoadMomBySite event,
    Emitter<MomState> emit,
  ) async {
    final currentState = state;
    if (!event.isRefresh || currentState is! MomLoaded) {
      emit(const MomLoading());
    }

    try {
      final result = await dataSource.getMomBySite();
      if (currentState is MomLoaded) {
        emit(currentState.copyWith(data: result));
      } else {
        emit(MomLoaded(data: result));
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? e.message)
          : e.message;
      emit(MomError(msg?.toString() ?? 'Unable to connect to server.'));
    } catch (e) {
      emit(MomError(e.toString()));
    }
  }

  void _onChangeMomTab(
    ChangeMomTab event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final loaded = state as MomLoaded;
      MomActivityModel? nextSelectedActivity = loaded.selectedActivity;
      if (loaded.selectedSite != null && loaded.siteActivities.isNotEmpty) {
        if (event.tabIndex == 0) {
          nextSelectedActivity = loaded.siteActivities
              .where((a) => a.isPending)
              .firstOrNull ?? loaded.siteActivities.firstOrNull;
        } else {
          nextSelectedActivity = loaded.siteActivities
              .where((a) => a.isSent)
              .firstOrNull ?? loaded.siteActivities.firstOrNull;
        }
      }

      emit(loaded.copyWith(
        selectedTabIndex: event.tabIndex,
        selectedActivity: () => nextSelectedActivity,
      ));
    }
  }

  void _onSearchMomQueryChanged(
    SearchMomQueryChanged event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final loaded = state as MomLoaded;
      emit(loaded.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onSelectMomSite(
    SelectMomSite event,
    Emitter<MomState> emit,
  ) async {
    if (state is! MomLoaded) return;
    final current = state as MomLoaded;

    emit(current.copyWith(
      selectedSite: () => event.site,
      isSiteActivitiesLoading: true,
      siteActivities: [],
      selectedActivity: () => null,
      actionError: () => null,
      actionMessage: () => null,
      momSendSuccess: false,
    ));

    try {
      final activities = await dataSource.getSiteMomActivities(
        siteId: event.site.siteId,
      );

      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        MomActivityModel? defaultActivity;
        if (latest.selectedTabIndex == 0) {
          defaultActivity = activities.where((a) => a.isPending).firstOrNull ??
              activities.firstOrNull;
        } else {
          defaultActivity = activities.where((a) => a.isSent).firstOrNull ??
              activities.firstOrNull;
        }

        emit(latest.copyWith(
          selectedSite: () => event.site,
          isSiteActivitiesLoading: false,
          siteActivities: activities,
          selectedActivity: () => defaultActivity,
        ));
      }
    } catch (e, stack) {
      developer.log(
        'Error loading site activities for MOM: ${event.site.siteName}',
        error: e,
        stackTrace: stack,
        name: 'MOM',
      );
      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        emit(latest.copyWith(
          selectedSite: () => event.site,
          isSiteActivitiesLoading: false,
          siteActivities: [],
          selectedActivity: () => null,
          actionError: () => 'Could not load site activities: $e',
        ));
      }
    }
  }

  void _onBackToMomSitesList(
    BackToMomSitesList event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final current = state as MomLoaded;
      emit(current.copyWith(
        selectedSite: () => null,
        selectedActivity: () => null,
        siteActivities: [],
        actionError: () => null,
        actionMessage: () => null,
        momSendSuccess: false,
      ));
    }
  }

  void _onSelectMomActivity(
    SelectMomActivity event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final current = state as MomLoaded;
      emit(current.copyWith(
        selectedActivity: () => event.activity,
        actionError: () => null,
        actionMessage: () => null,
        momSendSuccess: false,
      ));
    }
  }

  Future<void> _onSendMomEmailAction(
    SendMomEmailAction event,
    Emitter<MomState> emit,
  ) async {
    if (state is! MomLoaded) return;
    final current = state as MomLoaded;

    emit(current.copyWith(
      isSendingMom: true,
      actionError: () => null,
      actionMessage: () => null,
      momSendSuccess: false,
    ));

    try {
      await dataSource.sendMomEmail(
        activityId: event.activityId,
        payload: event.payload,
      );

      // Refresh site activities
      List<MomActivityModel> updatedActivities = current.siteActivities;
      if (current.selectedSite != null) {
        try {
          updatedActivities = await dataSource.getSiteMomActivities(
            siteId: current.selectedSite!.siteId,
          );
        } catch (_) {}
      }

      // Also refresh root site counts in background
      dataSource.getMomBySite().then((freshData) {
        if (!isClosed && state is MomLoaded) {
          add(const LoadMomBySite(isRefresh: true));
        }
      }).catchError((_) {});

      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        final updatedSelected = updatedActivities
            .where((a) => a.id == event.activityId)
            .firstOrNull ?? latest.selectedActivity;

        emit(latest.copyWith(
          isSendingMom: false,
          momSendSuccess: true,
          actionMessage: () => 'MOM email dispatched successfully!',
          siteActivities: updatedActivities,
          selectedActivity: () => updatedSelected,
        ));
      }
    } catch (e, stack) {
      developer.log('Error dispatching MOM email', error: e, stackTrace: stack, name: 'MOM');
      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        emit(latest.copyWith(
          isSendingMom: false,
          momSendSuccess: false,
          actionError: () => 'Failed to send MOM email: ${e.toString()}',
        ));
      }
    }
  }
}
