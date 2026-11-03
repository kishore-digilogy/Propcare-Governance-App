import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/meta_service.dart';
import '../../data/datasources/activities_remote_datasource.dart';
import '../../data/models/activity_site_summary_model.dart';
import 'activities_event.dart';
import 'activities_state.dart';

class ActivitiesBloc extends Bloc<ActivitiesEvent, ActivitiesState> {
  final ActivitiesRemoteDataSource remoteDataSource;

  ActivitiesBloc({required this.remoteDataSource}) : super(const ActivitiesInitial()) {
    on<LoadActivitiesBySite>(_onLoadActivitiesBySite);
    on<ChangeActivitiesZoneFilter>(_onChangeZoneFilter);
    on<ChangeActivitiesClusterFilter>(_onChangeClusterFilter);
    on<ChangeActivitiesStatusFilter>(_onChangeStatusFilter);
    on<ChangeActivitiesRoleFilter>(_onChangeRoleFilter);
    on<SearchActivitiesQueryChanged>(_onSearchQueryChanged);
    on<SelectSiteForActivities>(_onSelectSite);
    on<CloseSiteActivitiesDetail>(_onCloseSiteDetail);
    on<LoadSiteActivitiesPage>(_onLoadSitePage);
    on<SelectActivityForDetail>(_onSelectActivityForDetail);
    on<CloseActivityDetail>(_onCloseActivityDetail);
    on<SubmitActivityVisit>(_onSubmitActivityVisit);
    on<SendActivityMomEmail>(_onSendActivityMomEmail);
  }

  Future<void> _onLoadActivitiesBySite(
    LoadActivitiesBySite event,
    Emitter<ActivitiesState> emit,
  ) async {
    MetaService.instance.fetchMetadata().catchError((_) => MetaService.instance.meta);
    final currentState = state;
    if (!event.isRefresh && currentState is! ActivitiesLoaded) {
      emit(const ActivitiesLoading());
    }

    try {
      final res = await remoteDataSource.getActivitiesBySite(
        view: event.view,
      );

      if (currentState is ActivitiesLoaded && event.isRefresh) {
        emit(currentState.copyWith(
          response: res,
          view: event.view,
        ));
      } else {
        emit(ActivitiesLoaded(
          response: res,
          view: event.view,
        ));
      }
    } catch (e) {
      emit(ActivitiesError(e.toString()));
    }
  }

  Future<void> _onChangeZoneFilter(
    ChangeActivitiesZoneFilter event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(
        selectedZoneId: () => event.zoneId,
        selectedClusterId: () => null, // reset cluster when zone changes
      ));
    }
  }

  Future<void> _onChangeClusterFilter(
    ChangeActivitiesClusterFilter event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(
        selectedClusterId: () => event.clusterId,
      ));
    }
  }

  Future<void> _onChangeStatusFilter(
    ChangeActivitiesStatusFilter event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(
        selectedStatus: () => event.status,
      ));
    }
  }

  Future<void> _onChangeRoleFilter(
    ChangeActivitiesRoleFilter event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(
        selectedRole: () => event.role,
        isLoadingDetail: true,
      ));

      try {
        final res = await remoteDataSource.getActivitiesBySite(
          view: currentState.view,
          role: event.role,
          zoneId: currentState.selectedZoneId,
          clusterId: currentState.selectedClusterId,
          status: currentState.selectedStatus,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            response: res,
            selectedRole: () => event.role,
            isLoadingDetail: false,
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(isLoadingDetail: false));
        }
      }
    }
  }

  void _onSearchQueryChanged(
    SearchActivitiesQueryChanged event,
    Emitter<ActivitiesState> emit,
  ) {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onSelectSite(
    SelectSiteForActivities event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(
        selectedSite: () => event.site,
        isLoadingDetail: true,
      ));

      try {
        final siteActivities = await remoteDataSource.getSiteActivities(
          view: currentState.view,
          siteId: event.site.siteId,
          offset: 0,
          limit: 10,
          role: currentState.selectedRole,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            selectedSiteActivities: () => siteActivities,
            isLoadingDetail: false,
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(isLoadingDetail: false));
        }
      }
    }
  }

  void _onCloseSiteDetail(
    CloseSiteActivitiesDetail event,
    Emitter<ActivitiesState> emit,
  ) {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(
        selectedSite: () => null,
        selectedSiteActivities: () => null,
        isLoadingDetail: false,
      ));
    }
  }

  Future<void> _onLoadSitePage(
    LoadSiteActivitiesPage event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded && currentState.selectedSite != null) {
      emit(currentState.copyWith(isLoadingDetail: true));

      try {
        final siteActivities = await remoteDataSource.getSiteActivities(
          view: currentState.view,
          siteId: event.siteId,
          offset: event.offset,
          limit: event.limit,
          role: currentState.selectedRole,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            selectedSiteActivities: () => siteActivities,
            isLoadingDetail: false,
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(isLoadingDetail: false));
        }
      }
    }
  }

  Future<void> _onSelectActivityForDetail(
    SelectActivityForDetail event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state is ActivitiesLoaded
        ? state as ActivitiesLoaded
        : const ActivitiesLoaded(
            response: ActivitiesBySiteResponseModel(
              items: [],
              pending: 0,
              completed: 0,
              total: 0,
              view: 'mine',
              myRoleLabel: 'CRRM / Super Admin',
            ),
            view: 'mine',
          );

    emit(currentState.copyWith(
      isLoadingActivity: true,
      actionSuccessMessage: () => null,
      actionErrorMessage: () => null,
    ));

    try {
      final detail = await remoteDataSource.getActivityDetail(event.activityId);
      final latest = state is ActivitiesLoaded ? state as ActivitiesLoaded : currentState;
      emit(latest.copyWith(
        selectedActivityDetail: () => detail,
        isLoadingActivity: false,
      ));
    } catch (e) {
      final latest = state is ActivitiesLoaded ? state as ActivitiesLoaded : currentState;
      emit(latest.copyWith(
        isLoadingActivity: false,
        actionErrorMessage: () => 'Failed to load activity details: $e',
      ));
    }
  }

  void _onCloseActivityDetail(
    CloseActivityDetail event,
    Emitter<ActivitiesState> emit,
  ) {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(
        selectedActivityDetail: () => null,
        isLoadingActivity: false,
        actionSuccessMessage: () => null,
        actionErrorMessage: () => null,
      ));
    }
  }

  Future<void> _onSubmitActivityVisit(
    SubmitActivityVisit event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded && currentState.selectedActivityDetail != null) {
      emit(currentState.copyWith(
        isSubmittingVisit: true,
        actionSuccessMessage: () => null,
        actionErrorMessage: () => null,
      ));

      try {
        final updatedActivity = await remoteDataSource.completeActivity(
          activityId: event.activityId,
          visitDate: event.visitDate,
          clientMet: event.clientMet,
          note: event.note,
        );

        final updatedDetail = currentState.selectedActivityDetail!.copyWith(
          activity: updatedActivity,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            selectedActivityDetail: () => updatedDetail,
            isSubmittingVisit: false,
            actionSuccessMessage: () => 'Visit details submitted successfully',
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            isSubmittingVisit: false,
            actionErrorMessage: () => 'Failed to submit visit: $e',
          ));
        }
      }
    }
  }

  Future<void> _onSendActivityMomEmail(
    SendActivityMomEmail event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded && currentState.selectedActivityDetail != null) {
      emit(currentState.copyWith(
        isSendingMom: true,
        actionSuccessMessage: () => null,
        actionErrorMessage: () => null,
      ));

      try {
        final updatedActivity = await remoteDataSource.sendMomEmail(
          activityId: event.activityId,
          payload: event.payload,
        );

        final updatedDetail = currentState.selectedActivityDetail!.copyWith(
          activity: updatedActivity,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            selectedActivityDetail: () => updatedDetail,
            isSendingMom: false,
            actionSuccessMessage: () => 'MOM and Email sent successfully',
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            isSendingMom: false,
            actionErrorMessage: () => 'Error sending MOM: $e',
          ));
        }
      }
    }
  }
}
