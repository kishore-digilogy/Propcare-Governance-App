import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/datasources/activities_remote_datasource.dart';
import '../../data/models/site_activity_item_model.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';
import '../bloc/activities_state.dart';
import '../widgets/activity_execution_view.dart';

class MmrMisPage extends StatefulWidget {
  final ActivitiesBloc? bloc;

  const MmrMisPage({
    super.key,
    this.bloc,
  });

  @override
  State<MmrMisPage> createState() => _MmrMisPageState();
}

class _MmrMisPageState extends State<MmrMisPage> {
  late final ActivitiesBloc _bloc;
  late final TextEditingController _searchController;
  final bool _ownsBloc = false;
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ??
        ActivitiesBloc(
          remoteDataSource: ActivitiesRemoteDataSourceImpl(),
        );
    _searchController = TextEditingController();

    _bloc.add(const LoadActivities(
      kind: 'MIS,MMR',
    ));

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _bloc.add(SearchActivitiesQueryChanged(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ActivitiesBloc, ActivitiesState>(
        listener: (context, state) {
          if (state is ActivitiesLoaded) {
            if (state.actionSuccessMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionSuccessMessage!),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state.actionErrorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionErrorMessage!),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildBody(context, state),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ActivitiesState state) {
    if (state is ActivitiesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is ActivitiesError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Failed to load MMR / MIS',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _bloc.add(const LoadActivities(
                    kind: 'MIS,MMR',
                    isRefresh: true,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ActivitiesLoaded) {
      // If an individual activity detail is open
      if (state.selectedActivityDetail != null || state.isLoadingActivity) {
        if (state.isLoadingActivity) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return ActivityExecutionView(
          activityDetail: state.selectedActivityDetail!,
          isSubmittingVisit: state.isSubmittingVisit,
          isSendingMom: state.isSendingMom,
          bloc: _bloc,
          onBack: () {
            _bloc.add(const CloseActivityDetail());
          },
        );
      }

      // Main MMR / MIS view
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;

          return RefreshIndicator(
            onRefresh: () async {
              _bloc.add(LoadActivities(
                kind: 'MIS,MMR',
                siteId: state.selectedSiteId,
                status: state.selectedStatus,
                isRefresh: true,
              ));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header with Back button
                  _buildHeader(context, state),
                  const SizedBox(height: 14),

                  // 2. Top Metric Cards (Total, Completed, Pending, Due)
                  _buildTopStatCards(state),
                  const SizedBox(height: 14),

                  // 3. Search and Quick Filters
                  _buildFilterBar(context, state),
                  const SizedBox(height: 14),

                  // 4. Section Header with Cards / Table toggle
                  _buildSectionHeader(state),
                  const SizedBox(height: 12),

                  // 5. Activities Content (Cards or Table)
                  _buildActivitiesContent(context, state),
                  const SizedBox(height: 16),

                  // 6. Pagination
                  if (state.activitiesResponse.total > 10)
                    _buildPagination(state),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader(BuildContext context, ActivitiesLoaded state) {
    final roleLabel = state.activitiesResponse.myRoleLabel.isNotEmpty
        ? state.activitiesResponse.myRoleLabel
        : 'Crrm';

    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF1E293B)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MMR / MIS',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$roleLabel · MIS & MMR governance — visit first, then MOM',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopStatCards(ActivitiesLoaded state) {
    final counts = state.activitiesResponse.counts;
    final total = state.activitiesResponse.total;
    final completed = counts.completed;
    final pending = counts.summaryPending > 0
        ? counts.summaryPending
        : (counts.scheduled + counts.assigned);
    final due = counts.summaryOverdue > 0
        ? counts.summaryOverdue
        : counts.overdue;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        final cardTotal = _buildCountCard(
          title: 'Total',
          count: total,
          subtitle: 'All activities',
          icon: Icons.apartment_outlined,
          iconColor: const Color(0xFF475569),
          iconBgColor: const Color(0xFFF1F5F9),
          bgTint: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          isCompact: isNarrow,
        );

        final cardCompleted = _buildCountCard(
          title: 'Completed',
          count: completed,
          subtitle: 'MOM sent · closed',
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          bgTint: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          isCompact: isNarrow,
        );

        final cardPending = _buildCountCard(
          title: 'Pending',
          count: pending,
          subtitle: 'Need visit / MOM',
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFEF3C7),
          bgTint: const Color(0xFFFFFDF5),
          borderColor: const Color(0xFFFDE68A),
          isCompact: isNarrow,
        );

        final cardDue = _buildCountCard(
          title: 'Due',
          count: due,
          subtitle: 'Past due date',
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
          bgTint: due > 0 ? const Color(0xFFFEF2F2) : Colors.white,
          borderColor: due > 0 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          isAlert: due > 0,
          isCompact: isNarrow,
        );

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardTotal),
                  const SizedBox(width: 8),
                  Expanded(child: cardCompleted),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: cardPending),
                  const SizedBox(width: 8),
                  Expanded(child: cardDue),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cardTotal),
            const SizedBox(width: 10),
            Expanded(child: cardCompleted),
            const SizedBox(width: 10),
            Expanded(child: cardPending),
            const SizedBox(width: 10),
            Expanded(child: cardDue),
          ],
        );
      },
    );
  }

  Widget _buildCountCard({
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color bgTint,
    required Color borderColor,
    bool isAlert = false,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: isCompact ? 11 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: isAlert ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                  ),
                ),
              ),
              Container(
                width: isCompact ? 22 : 28,
                height: isCompact ? 22 : 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: isCompact ? 12 : 15, color: iconColor),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 2 : 4),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: isCompact ? 17 : 22,
              fontWeight: FontWeight.w800,
              color: isAlert ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: isCompact ? 1 : 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: isCompact ? 9.5 : 10.5,
              fontWeight: FontWeight.w500,
              color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, ActivitiesLoaded state) {
    final meta = MetaService.instance.meta;

    final siteOptions = <DropdownItemOption<String?>>[
      const DropdownItemOption(value: null, label: 'All Sites'),
      ...state.knownSites.map((s) => DropdownItemOption(value: s.siteId, label: s.siteName)),
    ];

    final statusOptions = const <DropdownItemOption<String?>>[
      DropdownItemOption(value: null, label: 'Status'),
      DropdownItemOption(value: 'completed', label: 'Completed'),
      DropdownItemOption(value: 'pending', label: 'Pending'),
      DropdownItemOption(value: 'due', label: 'Due'),
    ];

    int activeCount = 0;
    if (state.selectedSiteId != null) activeCount++;
    if (state.selectedStatus != null) activeCount++;
    if (state.selectedZoneId != null) activeCount++;
    if (state.selectedClusterId != null) activeCount++;

    final searchField = Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Search activity, site, role...',
          hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );

    final filterButton = InkWell(
      onTap: () => _openFilterBottomSheet(context, state, meta),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: activeCount > 0 ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activeCount > 0 ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: activeCount > 0 ? AppColors.primary : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: activeCount > 0 ? AppColors.primary : const Color(0xFF475569),
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 8),
            filterButton,
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CustomDropdownButton2<String?>(
                selectedValue: state.selectedSiteId,
                options: siteOptions,
                placeholder: 'All Sites',
                buttonHeight: 38,
                maxHeight: 260,
                enableSearch: true,
                searchHint: 'Search site...',
                onSelect: (val) {
                  _bloc.add(ChangeActivitiesSiteFilter(val));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomDropdownButton2<String?>(
                selectedValue: state.selectedStatus?.toLowerCase(),
                options: statusOptions,
                placeholder: 'Status',
                buttonHeight: 38,
                maxHeight: 260,
                enableSearch: false,
                onSelect: (val) {
                  _bloc.add(ChangeActivitiesStatusFilter(val));
                },
              ),
            ),
          ],
        ),
        if (activeCount > 0)
          _buildActiveFilterChips(context, state, meta),
      ],
    );
  }

  Widget _buildActiveFilterChips(BuildContext context, ActivitiesLoaded state, MetaDataModel meta) {
    final chips = <Widget>[];

    if (state.selectedSiteId != null) {
      final siteName = state.knownSites
              .where((s) => s.siteId == state.selectedSiteId)
              .firstOrNull
              ?.siteName ??
          'Site';
      chips.add(_buildFilterChip(
        label: 'Site: $siteName',
        onClear: () => _bloc.add(const ChangeActivitiesSiteFilter(null)),
      ));
    }

    if (state.selectedStatus != null) {
      chips.add(_buildFilterChip(
        label: 'Status: ${state.selectedStatus}',
        onClear: () => _bloc.add(const ChangeActivitiesStatusFilter(null)),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          InkWell(
            onTap: () {
              _bloc.add(const ResetActivitiesFilters());
              _bloc.add(const ChangeActivitiesSiteFilter(null));
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Reset all',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onClear}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterBottomSheet(BuildContext context, ActivitiesLoaded state, MetaDataModel meta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocBuilder<ActivitiesBloc, ActivitiesState>(
          bloc: _bloc,
          builder: (ctx, bState) {
            final bottomSheetState = bState is ActivitiesLoaded ? bState : state;

            final siteOptions = <DropdownItemOption<String?>>[
              const DropdownItemOption(value: null, label: 'All Sites'),
              ...bottomSheetState.knownSites
                  .map((s) => DropdownItemOption(value: s.siteId, label: s.siteName)),
            ];

            final statusOptions = const <DropdownItemOption<String?>>[
              DropdownItemOption(value: null, label: 'Status'),
              DropdownItemOption(value: 'completed', label: 'Completed'),
              DropdownItemOption(value: 'pending', label: 'Pending'),
              DropdownItemOption(value: 'due', label: 'Due'),
            ];

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF0F172A)),
                          const SizedBox(width: 8),
                          Text(
                            'Filter MMR / MIS',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Site',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  CustomDropdownButton2<String?>(
                    selectedValue: bottomSheetState.selectedSiteId,
                    options: siteOptions,
                    placeholder: 'All Sites',
                    buttonHeight: 42,
                    maxHeight: 280,
                    enableSearch: true,
                    searchHint: 'Search site...',
                    onSelect: (val) {
                      _bloc.add(ChangeActivitiesSiteFilter(val));
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Status',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  CustomDropdownButton2<String?>(
                    selectedValue: bottomSheetState.selectedStatus?.toLowerCase(),
                    options: statusOptions,
                    placeholder: 'Status',
                    buttonHeight: 42,
                    maxHeight: 280,
                    enableSearch: false,
                    onSelect: (val) {
                      _bloc.add(ChangeActivitiesStatusFilter(val));
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(ActivitiesLoaded state) {
    final count = state.filteredActivities.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fact_check_outlined, size: 20, color: Color(0xFF334155)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'MMR / MIS Activities',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );

        final toggleWidget = Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewToggleButton(
                icon: Icons.view_agenda_outlined,
                label: 'Cards',
                isActive: !_isTableView,
                onTap: () => setState(() => _isTableView = false),
              ),
              _buildViewToggleButton(
                icon: Icons.table_chart_outlined,
                label: 'Table',
                isActive: _isTableView,
                onTap: () => setState(() => _isTableView = true),
              ),
            ],
          ),
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow,
              const SizedBox(height: 10),
              toggleWidget,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titleRow,
            toggleWidget,
          ],
        );
      },
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesContent(BuildContext context, ActivitiesLoaded state) {
    if (state.isLoadingActivities) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading MMR / MIS activities...',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final activities = state.filteredActivities;

    if (activities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.fact_check_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No MMR / MIS activities found',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filters.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (_isTableView) {
      return _buildActivitiesTable(context, activities);
    }

    return Column(
      children: activities.map((activity) => _buildActivityCard(context, activity, state)).toList(),
    );
  }

  Widget _buildActivityCard(BuildContext context, SiteActivityItemModel activity, ActivitiesLoaded state) {
    final isMmr = activity.kind.toUpperCase() == 'MMR';

    return InkWell(
      onTap: () => _bloc.add(SelectActivityForDetail(activity.id)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Status pill & Due date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusPill(activity.status, activity.statusLabel),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      activity.formattedDate,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Activity Title
            Text(
              activity.title.isNotEmpty ? activity.title : '${activity.kind} Activity',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Metadata badges: Kind (MMR/MIS), Role, Frequency, Assigned SPOC, Priority
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildMetaBadge(
                  icon: isMmr ? Icons.analytics_outlined : Icons.description_outlined,
                  label: activity.kind.isNotEmpty ? activity.kind : 'MMR',
                  color: isMmr ? const Color(0xFF7C3AED) : const Color(0xFF0284C7),
                  bgColor: isMmr ? const Color(0xFFF5F3FF) : const Color(0xFFF0F9FF),
                ),
                if (activity.roleLabel.isNotEmpty || activity.role.isNotEmpty)
                  _buildMetaBadge(
                    icon: Icons.badge_outlined,
                    label: activity.roleLabel.isNotEmpty ? activity.roleLabel : activity.role,
                    color: const Color(0xFF475569),
                    bgColor: const Color(0xFFF1F5F9),
                  ),
                if (activity.frequencyLabel.isNotEmpty)
                  _buildMetaBadge(
                    icon: Icons.repeat_rounded,
                    label: activity.frequencyLabel,
                    color: const Color(0xFF0369A1),
                    bgColor: const Color(0xFFF0F9FF),
                  ),
                if (activity.assignedToName != null && activity.assignedToName!.isNotEmpty)
                  _buildMetaBadge(
                    icon: Icons.person_outline_rounded,
                    label: activity.assignedToName!,
                    color: const Color(0xFF15803D),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                if (activity.priority.isNotEmpty)
                  _buildMetaBadge(
                    icon: Icons.flag_outlined,
                    label: activity.priority,
                    color: const Color(0xFFB45309),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            // Footer: Site & Location + Code badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${activity.siteName}${activity.clusterName.isNotEmpty ? " · ${activity.clusterName}" : ""}${activity.zoneName.isNotEmpty ? " · ${activity.zoneName}" : ""}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activity.code.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      activity.code,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesTable(BuildContext context, List<SiteActivityItemModel> activities) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 720),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingRowHeight: 44,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columnSpacing: 20,
              horizontalMargin: 16,
              columns: [
                DataColumn(
                  label: Text(
                    'Site',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Zone',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Cluster',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Activity',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Frequency',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Due Date',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              rows: activities.map((activity) {
                return DataRow(
                  onSelectChanged: (_) {
                    _bloc.add(SelectActivityForDetail(activity.id));
                  },
                  cells: [
                    // Site
                    DataCell(
                      Text(
                        activity.siteName.isNotEmpty ? activity.siteName : '—',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // Zone
                    DataCell(
                      Text(
                        activity.zoneName.isNotEmpty ? activity.zoneName : '—',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    // Cluster
                    DataCell(
                      Text(
                        activity.clusterName.isNotEmpty ? activity.clusterName : '—',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    // Activity
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          activity.title.isNotEmpty ? activity.title : '${activity.kind} Activity',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Frequency
                    DataCell(
                      Text(
                        activity.frequencyLabel.isNotEmpty ? activity.frequencyLabel : 'Monthly',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // Due Date
                    DataCell(
                      Text(
                        activity.formattedDate,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    // Status
                    DataCell(
                      _buildStatusPill(activity.status, activity.statusLabel),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, String label) {
    final upper = status.toUpperCase();
    final isDone = upper == 'COMPLETED';
    final isAssigned = upper == 'ASSIGNED';
    final isScheduled = upper == 'SCHEDULED';
    final isOverdue = upper == 'OVERDUE';

    Color dotColor = const Color(0xFFD97706);
    Color bgColor = const Color(0xFFFFFBEB);
    Color textColor = const Color(0xFFB45309);

    if (isDone) {
      dotColor = const Color(0xFF16A34A);
      bgColor = const Color(0xFFF0FDF4);
      textColor = const Color(0xFF15803D);
    } else if (isAssigned) {
      dotColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF1D4ED8);
    } else if (isScheduled) {
      dotColor = const Color(0xFF64748B);
      bgColor = const Color(0xFFF8FAFC);
      textColor = const Color(0xFF475569);
    } else if (isOverdue) {
      dotColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      textColor = const Color(0xFFB91C1C);
    }

    final displayLabel = label.isNotEmpty
        ? label
        : (isDone ? 'Completed' : (isAssigned ? 'Assigned' : 'Pending'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            displayLabel,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ActivitiesLoaded state) {
    final total = state.activitiesResponse.total;
    final offset = state.activitiesResponse.offset;
    final limit = state.activitiesResponse.limit > 0 ? state.activitiesResponse.limit : 10;
    final currentPage = (offset / limit).floor() + 1;
    final totalPages = (total / limit).ceil();
    final end = (offset + limit) > total ? total : (offset + limit);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 460;
        final infoText = Text(
          'Showing ${offset + 1}-$end of $total',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        );

        final pageButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed: currentPage > 1
                  ? () {
                      final newOffset = (currentPage - 2) * limit;
                      _bloc.add(LoadActivitiesPage(offset: newOffset, limit: limit));
                    }
                  : null,
              color: const Color(0xFF475569),
              disabledColor: const Color(0xFFCBD5E1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$currentPage',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (totalPages > 1) ...[
              const SizedBox(width: 6),
              Text(
                'of $totalPages',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              onPressed: currentPage < totalPages
                  ? () {
                      final newOffset = currentPage * limit;
                      _bloc.add(LoadActivitiesPage(offset: newOffset, limit: limit));
                    }
                  : null,
              color: const Color(0xFF475569),
              disabledColor: const Color(0xFFCBD5E1),
            ),
          ],
        );

        if (isNarrow) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                infoText,
                const SizedBox(height: 6),
                pageButtons,
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              infoText,
              pageButtons,
            ],
          ),
        );
      },
    );
  }
}
