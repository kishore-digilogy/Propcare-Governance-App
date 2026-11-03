import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/meta_service.dart';
import '../../data/datasources/issues_remote_datasource.dart';
import '../../data/models/issue_model.dart';
import 'issues_event.dart';
import 'issues_state.dart';

class IssuesBloc extends Bloc<IssuesEvent, IssuesState> {
  final IssuesRemoteDataSource dataSource;

  IssuesBloc({required this.dataSource}) : super(const IssuesInitial()) {
    on<LoadIssues>(_onLoadIssues);
    on<ChangeIssuesPage>(_onChangeIssuesPage);
    on<FilterZoneChanged>(_onFilterZoneChanged);
    on<FilterClusterChanged>(_onFilterClusterChanged);
    on<FilterSiteChanged>(_onFilterSiteChanged);
    on<FilterStatusChanged>(_onFilterStatusChanged);
    on<SearchIssuesQueryChanged>(_onSearchIssuesQueryChanged);
    on<OpenIssueDetail>(_onOpenIssueDetail);
    on<BackToIssuesList>(_onBackToIssuesList);
    on<CreateIssueSubmitted>(_onCreateIssueSubmitted);
    on<UpdateIssueSubmitted>(_onUpdateIssueSubmitted);
    on<AddActionPointSubmitted>(_onAddActionPointSubmitted);
    on<ClearIssueFeedback>((event, emit) {
      if (state is IssuesLoaded) {
        emit(
          (state as IssuesLoaded).copyWith(
            feedbackMessage: () => null,
            errorMessage: () => null,
          ),
        );
      }
    });
  }

  Future<void> _onLoadIssues(
    LoadIssues event,
    Emitter<IssuesState> emit,
  ) async {
    final currentState = state;
    if (!event.isRefresh || currentState is! IssuesLoaded) {
      emit(const IssuesLoading());
    }

    // Prefetch metadata in background
    MetaService.instance.fetchMetadata().catchError(
      (_) => MetaService.instance.meta,
    );

    final page = currentState is IssuesLoaded ? currentState.currentPage : 1;
    final limit = currentState is IssuesLoaded ? currentState.itemsPerPage : 20;
    final zoneId = currentState is IssuesLoaded
        ? currentState.selectedZoneId
        : null;
    final clusterId = currentState is IssuesLoaded
        ? currentState.selectedClusterId
        : null;
    final siteId = currentState is IssuesLoaded
        ? currentState.selectedSiteId
        : null;
    final status = currentState is IssuesLoaded
        ? currentState.selectedStatus
        : null;

    final offset = (page - 1) * limit;

    try {
      final res = await dataSource.getIssues(
        offset: offset,
        limit: limit,
        zoneId: zoneId,
        clusterId: clusterId,
        siteId: siteId,
        status: status,
      );

      if (currentState is IssuesLoaded) {
        emit(
          currentState.copyWith(
            data: res,
            currentPage: page,
            feedbackMessage: () => null,
            errorMessage: () => null,
          ),
        );
      } else {
        emit(
          IssuesLoaded(
            data: res,
            currentPage: page,
            itemsPerPage: limit,
            selectedZoneId: zoneId,
            selectedClusterId: clusterId,
            selectedSiteId: siteId,
            selectedStatus: status,
          ),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ??
                e.response?.data['error'] ??
                e.message)
          : e.message;
      emit(IssuesError(msg?.toString() ?? 'Failed to load issues.'));
    } catch (e) {
      emit(IssuesError(e.toString()));
    }
  }

  Future<void> _onChangeIssuesPage(
    ChangeIssuesPage event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;
    final offset = (event.page - 1) * current.itemsPerPage;

    try {
      final res = await dataSource.getIssues(
        offset: offset,
        limit: current.itemsPerPage,
        zoneId: current.selectedZoneId,
        clusterId: current.selectedClusterId,
        siteId: current.selectedSiteId,
        status: current.selectedStatus,
      );
      emit(current.copyWith(data: res, currentPage: event.page));
    } catch (e) {
      developer.log('Failed to change page: $e', name: 'Issues');
    }
  }

  Future<void> _onFilterZoneChanged(
    FilterZoneChanged event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;
    final nextZoneId = event.zoneId;

    emit(
      current.copyWith(
        selectedZoneId: () => nextZoneId,
        selectedClusterId: () => null, // reset dependent cluster
        selectedSiteId: () => null, // reset dependent site
        currentPage: 1,
      ),
    );

    add(const LoadIssues(isRefresh: true));
  }

  Future<void> _onFilterClusterChanged(
    FilterClusterChanged event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;

    emit(
      current.copyWith(
        selectedClusterId: () => event.clusterId,
        selectedSiteId: () => null,
        currentPage: 1,
      ),
    );

    add(const LoadIssues(isRefresh: true));
  }

  Future<void> _onFilterSiteChanged(
    FilterSiteChanged event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;

    emit(current.copyWith(selectedSiteId: () => event.siteId, currentPage: 1));

    add(const LoadIssues(isRefresh: true));
  }

  Future<void> _onFilterStatusChanged(
    FilterStatusChanged event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;

    emit(current.copyWith(selectedStatus: () => event.status, currentPage: 1));

    add(const LoadIssues(isRefresh: true));
  }

  void _onSearchIssuesQueryChanged(
    SearchIssuesQueryChanged event,
    Emitter<IssuesState> emit,
  ) {
    if (state is IssuesLoaded) {
      final current = state as IssuesLoaded;
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onOpenIssueDetail(
    OpenIssueDetail event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;

    emit(current.copyWith(isDetailLoading: true, errorMessage: () => null));

    try {
      final detail = await dataSource.getIssueDetail(event.issueId);
      if (state is IssuesLoaded) {
        final latest = state as IssuesLoaded;
        emit(
          latest.copyWith(
            selectedIssueDetail: () => detail,
            isDetailLoading: false,
          ),
        );
      }
    } catch (e, stack) {
      developer.log(
        'Error opening issue detail: $e',
        error: e,
        stackTrace: stack,
        name: 'Issues',
      );
      if (state is IssuesLoaded) {
        final latest = state as IssuesLoaded;
        emit(
          latest.copyWith(
            isDetailLoading: false,
            errorMessage: () => 'Failed to load issue details: $e',
          ),
        );
      }
    }
  }

  void _onBackToIssuesList(BackToIssuesList event, Emitter<IssuesState> emit) {
    if (state is IssuesLoaded) {
      final current = state as IssuesLoaded;
      emit(
        current.copyWith(
          selectedIssueDetail: () => null,
          errorMessage: () => null,
          feedbackMessage: () => null,
        ),
      );
    }
  }

  Future<void> _onCreateIssueSubmitted(
    CreateIssueSubmitted event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;

    emit(
      current.copyWith(
        isCreating: true,
        createSuccess: false,
        errorMessage: () => null,
        feedbackMessage: () => null,
      ),
    );

    try {
      await dataSource.createIssue(event.payload);

      // Re-trigger GET /issues to see recent changes immediately ("once post ai trugger call get api to see recnet chnages...")
      final refreshed = await dataSource.getIssues(
        offset: 0,
        limit: current.itemsPerPage,
        zoneId: current.selectedZoneId,
        clusterId: current.selectedClusterId,
        siteId: current.selectedSiteId,
        status: current.selectedStatus,
      );

      if (state is IssuesLoaded) {
        final latest = state as IssuesLoaded;
        emit(
          latest.copyWith(
            data: refreshed,
            currentPage: 1,
            isCreating: false,
            createSuccess: true,
            feedbackMessage: () => 'Issue recorded successfully!',
          ),
        );
      }
    } catch (e, stack) {
      developer.log(
        'Error creating issue: $e',
        error: e,
        stackTrace: stack,
        name: 'Issues',
      );
      String userMsg = 'Failed to create issue.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          userMsg = data['message'].toString();
        } else if (data is Map && data['error'] != null) {
          userMsg = data['error'].toString();
        } else if (e.response?.statusCode == 422) {
          userMsg = 'Validation error (422): please ensure a live site is selected.';
        } else {
          userMsg = e.message ?? 'Network error occurred.';
        }
      } else {
        userMsg = e.toString();
      }
      if (state is IssuesLoaded) {
        final latest = state as IssuesLoaded;
        emit(
          latest.copyWith(
            isCreating: false,
            createSuccess: false,
            errorMessage: () => userMsg,
          ),
        );
      }
    }
  }

  Future<void> _onUpdateIssueSubmitted(
    UpdateIssueSubmitted event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;

    emit(
      current.copyWith(
        isDetailLoading: true,
        errorMessage: () => null,
        feedbackMessage: () => null,
      ),
    );

    try {
      await dataSource.updateIssue(event.issueId, event.payload);
      final refreshedDetail = await dataSource.getIssueDetail(event.issueId);

      // Re-fetch current issues list cleanly
      IssuesResponseModel? freshList;
      try {
        freshList = await dataSource.getIssues(
          offset: (current.currentPage - 1) * current.itemsPerPage,
          limit: current.itemsPerPage,
          zoneId: current.selectedZoneId,
          clusterId: current.selectedClusterId,
          siteId: current.selectedSiteId,
          status: current.selectedStatus,
        );
      } catch (_) {}

      if (state is IssuesLoaded) {
        final latest = state as IssuesLoaded;
        emit(
          latest.copyWith(
            data: freshList ?? latest.data,
            selectedIssueDetail: () => refreshedDetail,
            isDetailLoading: false,
            feedbackMessage: () => 'Issue updated successfully!',
            errorMessage: () => null,
          ),
        );
      }
    } catch (e) {
      if (state is IssuesLoaded) {
        final latest = state as IssuesLoaded;
        emit(
          latest.copyWith(
            isDetailLoading: false,
            errorMessage: () => 'Failed to update issue: $e',
          ),
        );
      }
    }
  }

  Future<void> _onAddActionPointSubmitted(
    AddActionPointSubmitted event,
    Emitter<IssuesState> emit,
  ) async {
    if (state is! IssuesLoaded) return;
    final current = state as IssuesLoaded;

    emit(
      current.copyWith(
        isDetailLoading: true,
        errorMessage: () => null,
        feedbackMessage: () => null,
      ),
    );

    try {
      await dataSource.addActionPoint(event.payload);

      // Immediately re-fetch issue detail so the new action point is displayed
      final refreshedDetail = await dataSource.getIssueDetail(event.issueId);

      if (state is IssuesLoaded) {
        final latest = state as IssuesLoaded;
        emit(
          latest.copyWith(
            selectedIssueDetail: () => refreshedDetail,
            isDetailLoading: false,
            feedbackMessage: () => 'Action point added successfully!',
            errorMessage: () => null,
          ),
        );
      }
    } catch (e, stack) {
      developer.log(
        'Error adding action point: $e',
        error: e,
        stackTrace: stack,
        name: 'Issues',
      );
      if (state is IssuesLoaded) {
        final latest = state as IssuesLoaded;
        emit(
          latest.copyWith(
            isDetailLoading: false,
            errorMessage: () => 'Failed to add action point: $e',
          ),
        );
      }
    }
  }
}
