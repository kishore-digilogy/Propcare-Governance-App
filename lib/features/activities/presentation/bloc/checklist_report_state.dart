import 'package:equatable/equatable.dart';

import '../../data/models/checklist_report_model.dart';

class ChecklistReportState extends Equatable {
  final bool isLoadingSummary;
  final ChecklistReportResponseModel? summary;
  final String searchQuery;
  final String? summaryError;

  final bool isLoadingDetail;
  final SiteChecklistDetailResponseModel? detailSite;
  final String? selectedActivityId;
  final Map<String, ChecklistAnswerItemModel> currentAnswers;
  final String? detailError;

  final bool isSaving;
  final bool saveSuccess;
  final String? saveError;

  const ChecklistReportState({
    this.isLoadingSummary = false,
    this.summary,
    this.searchQuery = '',
    this.summaryError,
    this.isLoadingDetail = false,
    this.detailSite,
    this.selectedActivityId,
    this.currentAnswers = const {},
    this.detailError,
    this.isSaving = false,
    this.saveSuccess = false,
    this.saveError,
  });

  /// The currently active activity within the detail site
  SiteChecklistActivityItemModel? get selectedActivity {
    if (detailSite == null || detailSite!.items.isEmpty) return null;
    if (selectedActivityId == null) return detailSite!.items.first;
    try {
      return detailSite!.items.firstWhere((it) => it.id == selectedActivityId);
    } catch (_) {
      return detailSite!.items.first;
    }
  }

  /// Filtered summary items based on search query
  List<ChecklistReportItemModel> get filteredItems {
    if (summary == null) return [];
    if (searchQuery.trim().isEmpty) return summary!.items;
    final q = searchQuery.toLowerCase().trim();
    return summary!.items.where((it) {
      return it.siteName.toLowerCase().contains(q) ||
          it.zoneName.toLowerCase().contains(q) ||
          it.clusterName.toLowerCase().contains(q) ||
          it.activityLabel.toLowerCase().contains(q) ||
          it.roleLabel.toLowerCase().contains(q);
    }).toList();
  }

  // Answer stats for current answers
  int get currentYesCount =>
      currentAnswers.values.where((a) => a.status == 'OK').length;
  int get currentNoCount =>
      currentAnswers.values.where((a) => a.status == 'ISSUE').length;
  int get currentNaCount =>
      currentAnswers.values.where((a) => a.status == 'NA').length;

  ChecklistReportState copyWith({
    bool? isLoadingSummary,
    ChecklistReportResponseModel? Function()? summary,
    String? searchQuery,
    String? Function()? summaryError,
    bool? isLoadingDetail,
    SiteChecklistDetailResponseModel? Function()? detailSite,
    String? Function()? selectedActivityId,
    Map<String, ChecklistAnswerItemModel>? currentAnswers,
    String? Function()? detailError,
    bool? isSaving,
    bool? saveSuccess,
    String? Function()? saveError,
  }) {
    return ChecklistReportState(
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      summary: summary != null ? summary() : this.summary,
      searchQuery: searchQuery ?? this.searchQuery,
      summaryError: summaryError != null ? summaryError() : this.summaryError,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      detailSite: detailSite != null ? detailSite() : this.detailSite,
      selectedActivityId: selectedActivityId != null
          ? selectedActivityId()
          : this.selectedActivityId,
      currentAnswers: currentAnswers ?? this.currentAnswers,
      detailError: detailError != null ? detailError() : this.detailError,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      saveError: saveError != null ? saveError() : this.saveError,
    );
  }

  @override
  List<Object?> get props => [
        isLoadingSummary,
        summary,
        searchQuery,
        summaryError,
        isLoadingDetail,
        detailSite,
        selectedActivityId,
        currentAnswers,
        detailError,
        isSaving,
        saveSuccess,
        saveError,
      ];
}

