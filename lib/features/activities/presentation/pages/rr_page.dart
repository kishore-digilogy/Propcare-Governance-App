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

class RrPage extends StatefulWidget {
  final ActivitiesBloc? bloc;

  const RrPage({
    super.key,
    this.bloc,
  });

  @override
  State<RrPage> createState() => _RrPageState();
}

class _RrPageState extends State<RrPage> {
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
      kind: 'RR',
      limit: 10,
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
                'Failed to load R&R',
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
                    kind: 'RR',
                    limit: 10,
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

      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;

          return RefreshIndicator(
            onRefresh: () async {
              _bloc.add(LoadActivities(
                kind: 'RR',
                limit: 10,
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

                  // 2. Top Metric Cards (Total Activity, Completed, Pending, Due)
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
        : 'CRRM / Super Admin';

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
                'R&R',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$roleLabel · Recognition And Reward Visits From The Governance Matrix — Visit, Then MOM',
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
          title: 'Total Activity',
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
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          hintText: 'Search activity, site, role...',
          hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8)),
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
        ),
      ),
    );

    final filterButton = InkWell(
      onTap: () => _showFilterBottomSheet(context, state, meta),
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
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: activeCount > 0 ? AppColors.primary : const Color(0xFF334155),
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$activeCount',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final siteDropdown = CustomDropdownButton2<String?>(
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
    );

    final statusDropdown = CustomDropdownButton2<String?>(
      selectedValue: state.selectedStatus?.toLowerCase(),
      options: statusOptions,
      placeholder: 'Status',
      buttonHeight: 38,
      onSelect: (val) {
        _bloc.add(ChangeActivitiesStatusFilter(val));
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 10),
            filterButton,
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: siteDropdown),
            const SizedBox(width: 10),
            Expanded(child: statusDropdown),
          ],
        ),
        const SizedBox(height: 10),
        _buildQuickStatusChips(state),
      ],
    );
  }

  Widget _buildQuickStatusChips(ActivitiesLoaded state) {
    final current = state.selectedStatus?.toLowerCase();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusFilterChip(
            label: 'All',
            isSelected: current == null || current.isEmpty,
            onTap: () => _bloc.add(const ChangeActivitiesStatusFilter(null)),
          ),
          const SizedBox(width: 6),
          _buildStatusFilterChip(
            label: 'Completed',
            isSelected: current == 'completed',
            activeColor: const Color(0xFF16A34A),
            onTap: () => _bloc.add(const ChangeActivitiesStatusFilter('completed')),
          ),
          const SizedBox(width: 6),
          _buildStatusFilterChip(
            label: 'Pending',
            isSelected: current == 'pending',
            activeColor: const Color(0xFFD97706),
            onTap: () => _bloc.add(const ChangeActivitiesStatusFilter('pending')),
          ),
          const SizedBox(width: 6),
          _buildStatusFilterChip(
            label: 'Due',
            isSelected: current == 'due',
            activeColor: const Color(0xFFDC2626),
            onTap: () => _bloc.add(const ChangeActivitiesStatusFilter('due')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required bool isSelected,
    Color activeColor = AppColors.primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ActivitiesLoaded state) {
    final count = state.filteredActivities.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_outlined, size: 20, color: Color(0xFF334155)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'R&R Activities',
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
              'Loading R&R activities...',
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
            const Icon(Icons.workspace_premium_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No R&R Visits For These Sites. A And A+ Are N/A In The Governance Matrix, So A Visit Is Not Required.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
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
    final statusColor = _statusColor(activity.status);
    final statusBgColor = _statusBgColor(activity.status);
    final statusLabel = _statusLabel(activity.status);

    return InkWell(
      onTap: () {
        _bloc.add(SelectActivityForDetail(activity.id));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.siteName.isNotEmpty ? activity.siteName : 'Site ${activity.siteId}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildInfoBadge(Icons.calendar_today_outlined, 'Due: ${activity.formattedDate}'),
                _buildInfoBadge(Icons.repeat_rounded, activity.frequencyLabel.isNotEmpty ? activity.frequencyLabel : 'Quarterly'),
                if (activity.zoneName.isNotEmpty)
                  _buildInfoBadge(Icons.map_outlined, activity.zoneName),
                if (activity.clusterName.isNotEmpty)
                  _buildInfoBadge(Icons.hub_outlined, activity.clusterName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesTable(BuildContext context, List<SiteActivityItemModel> activities) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
          dataTextStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF1E293B),
          ),
          columns: const [
            DataColumn(label: Text('Site')),
            DataColumn(label: Text('Zone')),
            DataColumn(label: Text('Cluster')),
            DataColumn(label: Text('Activity')),
            DataColumn(label: Text('Frequency')),
            DataColumn(label: Text('Due Date')),
            DataColumn(label: Text('Status')),
          ],
          rows: activities.map((activity) {
            final statusColor = _statusColor(activity.status);
            final statusBgColor = _statusBgColor(activity.status);
            final statusLabel = _statusLabel(activity.status);

            return DataRow(
              onSelectChanged: (_) {
                _bloc.add(SelectActivityForDetail(activity.id));
              },
              cells: [
                DataCell(
                  Text(
                    activity.siteName.isNotEmpty ? activity.siteName : activity.siteId,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(activity.zoneName.isNotEmpty ? activity.zoneName : '—')),
                DataCell(Text(activity.clusterName.isNotEmpty ? activity.clusterName : '—')),
                DataCell(Text(activity.title)),
                DataCell(Text(activity.frequencyLabel.isNotEmpty ? activity.frequencyLabel : 'Quarterly')),
                DataCell(Text(activity.formattedDate)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination(ActivitiesLoaded state) {
    final total = state.activitiesResponse.total;
    final limit = state.activitiesResponse.limit;
    final offset = state.activitiesResponse.offset;
    final currentPage = (offset / limit).floor() + 1;
    final totalPages = (total / limit).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${offset + 1}–${(offset + limit) > total ? total : (offset + limit)} of $total',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: currentPage > 1
                  ? () {
                      _bloc.add(LoadActivitiesPage(offset: (currentPage - 2) * limit, limit: limit));
                    }
                  : null,
            ),
            Text(
              '$currentPage / $totalPages',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: currentPage < totalPages
                  ? () {
                      _bloc.add(LoadActivitiesPage(offset: currentPage * limit, limit: limit));
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context, ActivitiesLoaded state, MetaDataModel meta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter R&R',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _bloc.add(const ResetActivitiesFilters());
                      Navigator.of(bottomSheetContext).pop();
                    },
                    child: Text(
                      'Reset All',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(bottomSheetContext).pop(),
                child: Text(
                  'Apply Filters',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'CLOSED':
        return const Color(0xFF16A34A);
      case 'PENDING':
      case 'OPEN':
      case 'SCHEDULED':
      case 'ASSIGNED':
        return const Color(0xFFD97706);
      case 'DUE':
      case 'OVERDUE':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'CLOSED':
        return const Color(0xFFDCFCE7);
      case 'PENDING':
      case 'OPEN':
      case 'SCHEDULED':
      case 'ASSIGNED':
        return const Color(0xFFFEF3C7);
      case 'DUE':
      case 'OVERDUE':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'CLOSED':
        return 'Completed';
      case 'PENDING':
      case 'OPEN':
      case 'SCHEDULED':
      case 'ASSIGNED':
        return 'Pending';
      case 'DUE':
      case 'OVERDUE':
        return 'Due';
      default:
        return status;
    }
  }
}
