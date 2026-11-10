import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/activities_remote_datasource.dart';
import '../../data/models/checklist_report_model.dart';
import 'checklist_report_event.dart';
import 'checklist_report_state.dart';

class ChecklistReportBloc
    extends Bloc<ChecklistReportEvent, ChecklistReportState> {
  final ActivitiesRemoteDataSource remoteDataSource;

  ChecklistReportBloc({required this.remoteDataSource})
      : super(const ChecklistReportState()) {
    on<LoadChecklistReport>(_onLoadChecklistReport);
    on<SearchChecklistReport>(_onSearchChecklistReport);
    on<LoadSiteChecklistDetail>(_onLoadSiteChecklistDetail);
    on<SelectVisitDate>(_onSelectVisitDate);
    on<UpdateChecklistAnswer>(_onUpdateChecklistAnswer);
    on<SaveCurrentChecklist>(_onSaveCurrentChecklist);
  }

  Future<void> _onLoadChecklistReport(
    LoadChecklistReport event,
    Emitter<ChecklistReportState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(isLoadingSummary: true, summaryError: () => null));
    }
    try {
      final summary = await remoteDataSource.getChecklistBySite();
      emit(state.copyWith(
        isLoadingSummary: false,
        summary: () => summary,
        summaryError: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingSummary: false,
        summaryError: () => e.toString(),
      ));
    }
  }

  void _onSearchChecklistReport(
    SearchChecklistReport event,
    Emitter<ChecklistReportState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onLoadSiteChecklistDetail(
    LoadSiteChecklistDetail event,
    Emitter<ChecklistReportState> emit,
  ) async {
    emit(state.copyWith(
      isLoadingDetail: true,
      detailError: () => null,
      saveSuccess: false,
      saveError: () => null,
    ));

    try {
      final detail = await remoteDataSource.getChecklistDetailBySite(event.siteId);

      // Determine selected activity
      String? activeId = event.initialActivityId;
      if (activeId == null && detail.items.isNotEmpty) {
        activeId = detail.items.first.id;
      }

      // Populate current answers from the selected activity
      final activeActivity = detail.items.firstWhere(
        (it) => it.id == activeId,
        orElse: () => detail.items.isNotEmpty
            ? detail.items.first
            : const SiteChecklistActivityItemModel(id: ''),
      );

      final answersMap = <String, ChecklistAnswerItemModel>{};
      for (final ans in activeActivity.answers) {
        answersMap[ans.key] = ans;
      }

      // For any template item without an explicit answer, default to 'OK'
      for (final tmpl in activeActivity.template) {
        if (!answersMap.containsKey(tmpl.key)) {
          answersMap[tmpl.key] = ChecklistAnswerItemModel(
            key: tmpl.key,
            status: 'OK',
            remarks: '',
          );
        }
      }

      emit(state.copyWith(
        isLoadingDetail: false,
        detailSite: () => detail,
        selectedActivityId: () => activeId,
        currentAnswers: answersMap,
        detailError: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingDetail: false,
        detailError: () => e.toString(),
      ));
    }
  }

  void _onSelectVisitDate(
    SelectVisitDate event,
    Emitter<ChecklistReportState> emit,
  ) {
    if (state.detailSite == null) return;
    final activity = state.detailSite!.items.firstWhere(
      (it) => it.id == event.activityId,
      orElse: () => state.detailSite!.items.first,
    );

    final answersMap = <String, ChecklistAnswerItemModel>{};
    for (final ans in activity.answers) {
      answersMap[ans.key] = ans;
    }
    for (final tmpl in activity.template) {
      if (!answersMap.containsKey(tmpl.key)) {
        answersMap[tmpl.key] = ChecklistAnswerItemModel(
          key: tmpl.key,
          status: 'OK',
          remarks: '',
        );
      }
    }

    emit(state.copyWith(
      selectedActivityId: () => event.activityId,
      currentAnswers: answersMap,
      saveSuccess: false,
      saveError: () => null,
    ));
  }

  void _onUpdateChecklistAnswer(
    UpdateChecklistAnswer event,
    Emitter<ChecklistReportState> emit,
  ) {
    final updated = Map<String, ChecklistAnswerItemModel>.from(state.currentAnswers);
    final existing = updated[event.key] ??
        ChecklistAnswerItemModel(
          key: event.key,
          status: 'OK',
          remarks: '',
        );

    updated[event.key] = existing.copyWith(
      status: event.status ?? existing.status,
      remarks: event.remarks ?? existing.remarks,
    );

    emit(state.copyWith(
      currentAnswers: updated,
      saveSuccess: false,
    ));
  }

  Future<void> _onSaveCurrentChecklist(
    SaveCurrentChecklist event,
    Emitter<ChecklistReportState> emit,
  ) async {
    final active = state.selectedActivity;
    if (active == null || active.id.isEmpty) return;

    emit(state.copyWith(
      isSaving: true,
      saveSuccess: false,
      saveError: () => null,
    ));

    try {
      final answersList = state.currentAnswers.values
          .map((a) => {
                'key': a.key,
                'status': a.status,
                'remarks': a.remarks,
              })
          .toList();

      await remoteDataSource.saveChecklistAnswers(
        activityId: active.id,
        answers: answersList,
      );

      // Refresh site checklist detail to get updated counts & answers
      if (state.detailSite != null) {
        final refreshedDetail = await remoteDataSource.getChecklistDetailBySite(
          state.detailSite!.siteId,
        );

        final updatedActivity = refreshedDetail.items.firstWhere(
          (it) => it.id == active.id,
          orElse: () => refreshedDetail.items.first,
        );

        final answersMap = <String, ChecklistAnswerItemModel>{};
        for (final ans in updatedActivity.answers) {
          answersMap[ans.key] = ans;
        }

        emit(state.copyWith(
          isSaving: false,
          saveSuccess: true,
          detailSite: () => refreshedDetail,
          currentAnswers: answersMap,
          saveError: () => null,
        ));
      } else {
        emit(state.copyWith(
          isSaving: false,
          saveSuccess: true,
          saveError: () => null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        saveSuccess: false,
        saveError: () => e.toString(),
      ));
    }
  }
}

