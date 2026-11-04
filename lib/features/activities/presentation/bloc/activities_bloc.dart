import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/meta_service.dart';
import '../../data/datasources/activities_remote_datasource.dart';
import '../../data/models/activity_site_summary_model.dart';
import '../../data/models/site_activity_item_model.dart';
import 'activities_event.dart';
import 'activities_state.dart';

class ActivitiesBloc extends Bloc<ActivitiesEvent, ActivitiesState> {
  final ActivitiesRemoteDataSource remoteDataSource;

  ActivitiesBloc({required this.remoteDataSource}) : super(const ActivitiesInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<LoadActivitiesBySite>(_onLoadActivitiesBySite);
    on<ChangeActivitiesSiteFilter>(_onChangeSiteFilter);
    on<LoadActivitiesPage>(_onLoadActivitiesPage);
    on<ChangeActivitiesZoneFilter>(_onChangeZoneFilter);
    on<ChangeActivitiesClusterFilter>(_onChangeClusterFilter);
    on<ChangeActivitiesStatusFilter>(_onChangeStatusFilter);
    on<ChangeActivitiesRoleFilter>(_onChangeRoleFilter);
    on<ResetActivitiesFilters>((event, emit) {
      final currentState = state;
      if (currentState is ActivitiesLoaded) {
        emit(currentState.copyWith(
          selectedSiteId: () => null,
          selectedZoneId: () => null,
          selectedClusterId: () => null,
          selectedStatus: () => null,
        ));
      }
    });
    on<SearchActivitiesQueryChanged>(_onSearchQueryChanged);
    on<SelectSiteForActivities>(_onSelectSite);
    on<CloseSiteActivitiesDetail>(_onCloseSiteDetail);
    on<LoadSiteActivitiesPage>(_onLoadSitePage);
    on<SelectActivityForDetail>(_onSelectActivityForDetail);
    on<CloseActivityDetail>(_onCloseActivityDetail);
    on<SubmitActivityVisit>(_onSubmitActivityVisit);
    on<SendActivityMomEmail>(_onSendActivityMomEmail);
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<ActivitiesState> emit,
  ) async {
    MetaService.instance.fetchMetadata().catchError((_) => MetaService.instance.meta);
    final currentState = state;
    if (!event.isRefresh && currentState is! ActivitiesLoaded) {
      emit(const ActivitiesLoading());
    } else if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(isLoadingActivities: true));
    }

    try {
      final activitiesRes = await remoteDataSource.getActivities(
        view: event.view,
        kind: event.kind,
        siteId: event.siteId,
        status: event.status,
        role: event.role,
        offset: event.offset,
        limit: event.limit,
      );

      // Extract unique sites from the response and combine with previously known sites
      final discoveredSites = <ActivitySiteOptionModel>[];
      final seenIds = <String>{};

      if (currentState is ActivitiesLoaded) {
        for (final s in currentState.knownSites) {
          if (!seenIds.contains(s.siteId)) {
            seenIds.add(s.siteId);
            discoveredSites.add(s);
          }
        }
      }

      for (final it in activitiesRes.items) {
        if (it.siteId.isNotEmpty && !seenIds.contains(it.siteId)) {
          seenIds.add(it.siteId);
          discoveredSites.add(ActivitySiteOptionModel(
            siteId: it.siteId,
            siteName: it.siteName.isNotEmpty ? it.siteName : 'Site ${it.siteId}',
          ));
        }
      }

      if (currentState is ActivitiesLoaded) {
        emit(currentState.copyWith(
          activitiesResponse: activitiesRes,
          view: () => event.view,
          kind: () => event.kind ?? currentState.kind,
          selectedSiteId: () => event.siteId,
          selectedStatus: () => event.status,
          selectedRole: () => event.role,
          knownSites: discoveredSites,
          isLoadingActivities: false,
        ));
      } else {
        emit(ActivitiesLoaded(
          activitiesResponse: activitiesRes,
          view: event.view,
          kind: event.kind,
          selectedSiteId: event.siteId,
          selectedStatus: event.status,
          selectedRole: event.role,
          knownSites: discoveredSites,
          isLoadingActivities: false,
        ));
      }
    } catch (e) {
      emit(ActivitiesError(e.toString()));
    }
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
      final activitiesRes = await remoteDataSource.getActivities(
        view: event.view,
      );

      final discoveredSites = <ActivitySiteOptionModel>[];
      final seenIds = <String>{};

      for (final it in activitiesRes.items) {
        if (it.siteId.isNotEmpty && !seenIds.contains(it.siteId)) {
          seenIds.add(it.siteId);
          discoveredSites.add(ActivitySiteOptionModel(
            siteId: it.siteId,
            siteName: it.siteName.isNotEmpty ? it.siteName : 'Site ${it.siteId}',
          ));
        }
      }

      emit(ActivitiesLoaded(
        response: res,
        activitiesResponse: activitiesRes,
        view: event.view,
        knownSites: discoveredSites,
      ));
    } catch (e) {
      emit(ActivitiesError(e.toString()));
    }
  }

  Future<void> _onChangeSiteFilter(
    ChangeActivitiesSiteFilter event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(
        selectedSiteId: () => event.siteId,
        isLoadingActivities: true,
      ));

      try {
        final res = await remoteDataSource.getActivities(
          view: currentState.view,
          kind: currentState.kind,
          siteId: event.siteId,
          status: currentState.selectedStatus,
          role: currentState.selectedRole,
          offset: 0,
          limit: 10,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            activitiesResponse: res,
            selectedSiteId: () => event.siteId,
            isLoadingActivities: false,
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            isLoadingActivities: false,
            actionErrorMessage: () => 'Failed to filter by site: $e',
          ));
        }
      }
    }
  }

  Future<void> _onLoadActivitiesPage(
    LoadActivitiesPage event,
    Emitter<ActivitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ActivitiesLoaded) {
      emit(currentState.copyWith(isLoadingActivities: true));

      try {
        final res = await remoteDataSource.getActivities(
          view: currentState.view,
          kind: currentState.kind,
          siteId: currentState.selectedSiteId,
          status: currentState.selectedStatus,
          role: currentState.selectedRole,
          offset: event.offset,
          limit: event.limit,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            activitiesResponse: res,
            isLoadingActivities: false,
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(isLoadingActivities: false));
        }
      }
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
        isLoadingActivities: true,
      ));

      try {
        final res = await remoteDataSource.getActivities(
          view: currentState.view,
          kind: currentState.kind,
          siteId: currentState.selectedSiteId,
          status: event.status,
          role: currentState.selectedRole,
          offset: 0,
          limit: 10,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            activitiesResponse: res,
            selectedStatus: () => event.status,
            isLoadingActivities: false,
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(isLoadingActivities: false));
        }
      }
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
        isLoadingActivities: true,
        isLoadingDetail: true,
      ));

      try {
        final res = await remoteDataSource.getActivities(
          view: currentState.view,
          kind: currentState.kind,
          siteId: currentState.selectedSiteId,
          status: currentState.selectedStatus,
          role: event.role,
          offset: 0,
          limit: 10,
        );

        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            activitiesResponse: res,
            selectedRole: () => event.role,
            isLoadingActivities: false,
            isLoadingDetail: false,
          ));
        }
      } catch (e) {
        final latest = state;
        if (latest is ActivitiesLoaded) {
          emit(latest.copyWith(
            isLoadingActivities: false,
            isLoadingDetail: false,
          ));
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
          view: currentState.view ?? 'mine',
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
          view: currentState.view ?? 'mine',
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
