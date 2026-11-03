import 'package:equatable/equatable.dart';

import '../../data/models/issue_model.dart';

abstract class IssuesState extends Equatable {
  const IssuesState();

  @override
  List<Object?> get props => [];
}

class IssuesInitial extends IssuesState {
  const IssuesInitial();
}

class IssuesLoading extends IssuesState {
  const IssuesLoading();
}

class IssuesLoaded extends IssuesState {
  final IssuesResponseModel data;
  final int currentPage;
  final int itemsPerPage;

  // Filters
  final String? selectedZoneId;
  final String? selectedClusterId;
  final String? selectedSiteId;
  final String? selectedStatus;
  final String searchQuery;

  // Detail view
  final IssueDetailModel? selectedIssueDetail;
  final bool isDetailLoading;

  // Creation & Action status
  final bool isCreating;
  final bool createSuccess;
  final String? feedbackMessage;
  final String? errorMessage;

  const IssuesLoaded({
    required this.data,
    this.currentPage = 1,
    this.itemsPerPage = 20,
    this.selectedZoneId,
    this.selectedClusterId,
    this.selectedSiteId,
    this.selectedStatus,
    this.searchQuery = '',
    this.selectedIssueDetail,
    this.isDetailLoading = false,
    this.isCreating = false,
    this.createSuccess = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  /// Filtered issues list according to local search query
  List<IssueModel> get filteredItems {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return data.items;

    return data.items.where((it) {
      return it.title.toLowerCase().contains(q) ||
          it.description.toLowerCase().contains(q) ||
          it.priority.toLowerCase().contains(q) ||
          it.status.toLowerCase().contains(q);
    }).toList();
  }

  int get totalCount => data.total;

  int get totalPages {
    if (data.total <= 0) return 1;
    return (data.total / itemsPerPage).ceil();
  }

  /// Pagination range string e.g. "1-1 of 1" or "1-20 of 45"
  String get paginationLabel {
    if (data.total == 0) return '0-0 of 0';
    final start = (currentPage - 1) * itemsPerPage + 1;
    final end = (start + itemsPerPage - 1).clamp(1, data.total);
    return '$start-$end of ${data.total}';
  }

  IssuesLoaded copyWith({
    IssuesResponseModel? data,
    int? currentPage,
    int? itemsPerPage,
    String? Function()? selectedZoneId,
    String? Function()? selectedClusterId,
    String? Function()? selectedSiteId,
    String? Function()? selectedStatus,
    String? searchQuery,
    IssueDetailModel? Function()? selectedIssueDetail,
    bool? isDetailLoading,
    bool? isCreating,
    bool? createSuccess,
    String? Function()? feedbackMessage,
    String? Function()? errorMessage,
  }) {
    return IssuesLoaded(
      data: data ?? this.data,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      selectedZoneId:
          selectedZoneId != null ? selectedZoneId() : this.selectedZoneId,
      selectedClusterId: selectedClusterId != null
          ? selectedClusterId()
          : this.selectedClusterId,
      selectedSiteId:
          selectedSiteId != null ? selectedSiteId() : this.selectedSiteId,
      selectedStatus:
          selectedStatus != null ? selectedStatus() : this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIssueDetail: selectedIssueDetail != null
          ? selectedIssueDetail()
          : this.selectedIssueDetail,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isCreating: isCreating ?? this.isCreating,
      createSuccess: createSuccess ?? this.createSuccess,
      feedbackMessage: feedbackMessage != null
          ? feedbackMessage()
          : this.feedbackMessage,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        data,
        currentPage,
        itemsPerPage,
        selectedZoneId,
        selectedClusterId,
        selectedSiteId,
        selectedStatus,
        searchQuery,
        selectedIssueDetail,
        isDetailLoading,
        isCreating,
        createSuccess,
        feedbackMessage,
        errorMessage,
      ];
}

class IssuesError extends IssuesState {
  final String message;
  const IssuesError(this.message);

  @override
  List<Object?> get props => [message];
}

