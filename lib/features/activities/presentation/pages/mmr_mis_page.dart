import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../../../core/widgets/app_shimmer.dart';
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

class _MmrMisPageState extends State<MmrMisPage>
    with SingleTickerProviderStateMixin {
  late final ActivitiesBloc _bloc;
  late final TextEditingController _searchController;
  final bool _ownsBloc = false;
  bool _isTableView = false;

  late final AnimationController _animController;
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(_headerFadeAnimation);

    _bloc = widget.bloc ??
        ActivitiesBloc(
          remoteDataSource: ActivitiesRemoteDataSourceImpl(),
        );
    _searchController = TextEditingController();

    _bloc.add(const LoadActivities(
      kind: 'MIS,MMR',
    ));

    _searchController.addListener(_onSearchChanged);
    _animController.forward();
  }

  void _onSearchChanged() {
    _bloc.add(SearchActivitiesQueryChanged(_searchController.text));
  }

  @override
  void dispose() {
    _animController.dispose();
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
      return const ShimmerListLoading();
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
          return const ShimmerActivityExecutionLoading();
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

                  // 6. Pagination (Hidden during loading, show only if total > 10)
                  if (!state.isLoadingActivities && state.activitiesResponse.total > 10)
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
    final isTablet = MediaQuery.sizeOf(context).width >= 720;

    return SlideTransition(
      position: _headerSlideAnimation,
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEAF2FE),
                Color(0xFFF3F7FD),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Decorative background circle accents
                Positioned(
                  top: -24,
                  right: -24,
                  width: 120,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -18,
                  right: 60,
                  width: 80,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF6FF).withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 16 : 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button Pill
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 13,
                                color: Color(0xFF1A73E8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Back',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A73E8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Title + Subtitle on Left, 3D Illustration on Right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'MMR / MIS',
                                      style: GoogleFonts.outfit(
                                        fontSize: isTablet ? 24 : 21,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 24,
                                      height: 3.5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A73E8),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$roleLabel · MIS & MMR governance — visit first, then MOM',
                                  style: GoogleFonts.outfit(
                                    fontSize: isTablet ? 12.5 : 11.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            AppAssets.governanceClipboard,
                            height: isTablet ? 84 : 70,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          icon: Icons.layers_rounded,
          iconColor: const Color(0xFF1A73E8),
          iconBgColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFDBEAFE),
          waveColor: const Color(0xFF3B82F6),
          isCompact: isNarrow,
        );

        final cardCompleted = _buildCountCard(
          title: 'Completed',
          count: completed,
          subtitle: 'MOM sent · closed',
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFDCFCE7),
          waveColor: const Color(0xFF22C55E),
          isCompact: isNarrow,
        );

        final cardPending = _buildCountCard(
          title: 'Pending',
          count: pending,
          subtitle: 'Need visit / MOM',
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFDBEAFE),
          waveColor: const Color(0xFF2563EB),
          isCompact: isNarrow,
        );

        final cardDue = _buildCountCard(
          title: 'Due',
          count: due,
          subtitle: 'Past due date',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          waveColor: const Color(0xFFEF4444),
          isAlert: true,
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
              const SizedBox(height: 8),
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
    required Color borderColor,
    required Color waveColor,
    bool isAlert = false,
    bool isCompact = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: 0,
              width: isCompact ? 105 : 135,
              height: isCompact ? 58 : 72,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MmrCardBottomWavePainter(baseColor: waveColor),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 11 : 14,
                vertical: isCompact ? 9 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: isCompact ? 28 : 34,
                        height: isCompact ? 28 : 34,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                          border: Border.all(color: borderColor, width: 1.0),
                        ),
                        child: Icon(
                          icon,
                          size: isCompact ? 15 : 18,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: isCompact ? 13 : 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 5 : 8),
                  Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: isCompact ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      color: isAlert && count > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: isCompact ? 1 : 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: isCompact ? 10 : 11.5,
                      fontWeight: FontWeight.w500,
                      color: isAlert && count > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                right: 0,
                width: 140,
                height: 70,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MmrCardBottomWavePainter(baseColor: const Color(0xFF3B82F6)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Left icon badge + Status pill, Right due date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.trending_up_rounded,
                                  size: 17,
                                  color: Color(0xFF1A73E8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusPill(activity.status, activity.statusLabel),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12.5, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              activity.formattedDate,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 3,
                      margin: const EdgeInsets.only(top: 4, bottom: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

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
                            color: activity.priority.toLowerCase() == 'high'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF475569),
                            bgColor: activity.priority.toLowerCase() == 'high'
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF1F5F9),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Text(
                              activity.code,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    Color dotColor = const Color(0xFF2563EB);
    Color bgColor = const Color(0xFFEFF6FF);
    Color textColor = const Color(0xFF1D4ED8);

    if (isDone) {
      dotColor = const Color(0xFF16A34A);
      bgColor = const Color(0xFFF0FDF4);
      textColor = const Color(0xFF15803D);
    } else if (isAssigned || isScheduled) {
      dotColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF1D4ED8);
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
    if (state.isLoadingActivities) return const SizedBox.shrink();
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

class _MmrCardBottomWavePainter extends CustomPainter {
  final Color baseColor;

  const _MmrCardBottomWavePainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Outer/lighter wave
    final lightPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final lightPath = Path();
    lightPath.moveTo(0, size.height);
    lightPath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.22,
      size.width,
      size.height * 0.12,
    );
    lightPath.lineTo(size.width, size.height);
    lightPath.close();
    canvas.drawPath(lightPath, lightPaint);

    // Inner/soft wave
    final richPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final richPath = Path();
    richPath.moveTo(size.width * 0.22, size.height);
    richPath.quadraticBezierTo(
      size.width * 0.58,
      size.height * 0.46,
      size.width,
      size.height * 0.36,
    );
    richPath.lineTo(size.width, size.height);
    richPath.close();
    canvas.drawPath(richPath, richPaint);
  }

  @override
  bool shouldRepaint(covariant _MmrCardBottomWavePainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}
