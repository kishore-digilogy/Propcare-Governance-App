import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/datasources/activities_remote_datasource.dart';
import '../../data/models/activity_site_summary_model.dart';
import '../../data/models/site_activity_item_model.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';
import '../bloc/activities_state.dart';
import '../widgets/activity_execution_view.dart';
import '../widgets/site_activities_detail_view.dart';

class ActivitiesPage extends StatefulWidget {
  final bool isTeam;
  final ActivitiesBloc? bloc;

  const ActivitiesPage({
    super.key,
    required this.isTeam,
    this.bloc,
  });

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  late final ActivitiesBloc _bloc;
  late final TextEditingController _searchController;
  final bool _ownsBloc = false;
  bool _isRoleChipsExpanded = false;
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ??
        ActivitiesBloc(
          remoteDataSource: ActivitiesRemoteDataSourceImpl(),
        );
    _searchController = TextEditingController();

    _bloc.add(LoadActivities(
      view: widget.isTeam ? 'below' : 'mine',
    ));
  }

  @override
  void didUpdateWidget(covariant ActivitiesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTeam != widget.isTeam) {
      _bloc.add(LoadActivities(
        view: widget.isTeam ? 'below' : 'mine',
      ));
    }
  }

  @override
  void dispose() {
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
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
                      const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load activities',
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
                          _bloc.add(LoadActivitiesBySite(
                            view: widget.isTeam ? 'below' : 'mine',
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
              // 1. If an individual activity is selected for detail/execution
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

              // 2. If a site is selected, show detail view
              if (state.selectedSite != null) {
                return SiteActivitiesDetailView(
                  site: state.selectedSite!,
                  response: state.selectedSiteActivities,
                  isLoading: state.isLoadingDetail,
                  myRoleLabel: state.response.myRoleLabel,
                  bloc: _bloc,
                  onBack: () {
                    _bloc.add(const CloseSiteActivitiesDetail());
                  },
                );
              }

              // Otherwise show Main Activities list (or sites list if legacy fallback)
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 640;
                  final showSitesFallback =
                      state.activitiesResponse.items.isEmpty && state.response.items.isNotEmpty;

                  return RefreshIndicator(
                    onRefresh: () async {
                      _bloc.add(LoadActivities(
                        view: widget.isTeam ? 'below' : 'mine',
                        siteId: state.selectedSiteId,
                        status: state.selectedStatus,
                        role: state.selectedRole,
                        isRefresh: true,
                      ));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 12 : 20,
                        vertical: isNarrow ? 14 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(state),
                          const SizedBox(height: 16),
                          if (!showSitesFallback) ...[
                            _buildTopStatCards(state),
                            const SizedBox(height: 16),
                          ],
                          _buildFiltersBar(context, state),
                          if (widget.isTeam &&
                              (state.activitiesResponse.belowRoles.isNotEmpty ||
                                  state.response.belowRoles.isNotEmpty)) ...[
                            const SizedBox(height: 12),
                            _buildRoleFilterChips(state),
                          ],
                          const SizedBox(height: 20),
                          if (showSitesFallback) ...[
                            _buildSitesSectionHeader(state),
                            const SizedBox(height: 12),
                            _buildSitesList(state),
                          ] else ...[
                            _buildActivitiesSectionHeader(state),
                            const SizedBox(height: 12),
                            _buildActivitiesContent(context, state),
                            _buildPaginationBar(state),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ActivitiesLoaded state) {
    final title = widget.isTeam ? 'Team Activities' : 'My Activities';
    final roleLabel = state.activitiesResponse.myRoleLabel.isNotEmpty
        ? state.activitiesResponse.myRoleLabel
        : (state.response.myRoleLabel.isNotEmpty
            ? state.response.myRoleLabel
            : 'CRRM / Super Admin');
    final subtitle = '$roleLabel · Governance Activities';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
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
            const SizedBox(width: 12),
            Expanded(child: cardCompleted),
            const SizedBox(width: 12),
            Expanded(child: cardPending),
            const SizedBox(width: 12),
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
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isAlert ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: isCompact ? 28 : 32,
                height: isCompact ? 28 : 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: isCompact ? 15 : 17, color: iconColor),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: isCompact ? 22 : 26,
              fontWeight: FontWeight.w800,
              color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  int _activeActivitiesFiltersCount(ActivitiesLoaded state) {
    int count = 0;
    if (state.selectedSiteId != null) count++;
    if (state.selectedZoneId != null) count++;
    if (state.selectedClusterId != null) count++;
    if (state.selectedStatus != null) count++;
    if (state.selectedRole != null) count++;
    return count;
  }

  Widget _buildFiltersBar(BuildContext context, ActivitiesLoaded state) {
    final meta = MetaService.instance.meta;
    final activeCount = _activeActivitiesFiltersCount(state);

    final searchField = Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          _bloc.add(SearchActivitiesQueryChanged(val));
        },
        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search activity, code, site, role...',
          hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    _bloc.add(const SearchActivitiesQueryChanged(''));
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: activeCount > 0 ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activeCount > 0 ? AppColors.primary : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: activeCount > 0 ? AppColors.primary : const Color(0xFF334155),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
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

    // Site Dropdown Options: All Sites + unique sites from response
    final siteOptions = <DropdownItemOption<String?>>[
      const DropdownItemOption(value: null, label: 'All Sites'),
      ...state.knownSites.map((s) => DropdownItemOption(value: s.siteId, label: s.siteName)),
    ];

    final statusOptions = const <DropdownItemOption<String?>>[
      DropdownItemOption(value: null, label: 'All Statuses'),
      DropdownItemOption(value: 'SCHEDULED', label: 'Scheduled'),
      DropdownItemOption(value: 'ASSIGNED', label: 'Assigned'),
      DropdownItemOption(value: 'PENDING', label: 'Pending'),
      DropdownItemOption(value: 'COMPLETED', label: 'Completed'),
    ];

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
                selectedValue: state.selectedStatus,
                options: statusOptions,
                placeholder: 'All Statuses',
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

  Widget _buildActiveFilterChips(
    BuildContext context,
    ActivitiesLoaded state,
    MetaDataModel meta,
  ) {
    final chips = <Widget>[];

    if (state.selectedSiteId != null) {
      final siteName = state.knownSites
              .where((s) => s.siteId == state.selectedSiteId)
              .firstOrNull
              ?.siteName ??
          'Site';
      chips.add(_buildFilterChip(
        label: 'Site: $siteName',
        onClear: () {
          _bloc.add(const ChangeActivitiesSiteFilter(null));
        },
      ));
    }

    if (state.selectedZoneId != null) {
      final zoneName = meta.zones
              .where((z) => z.id == state.selectedZoneId)
              .firstOrNull
              ?.name ??
          'Zone';
      chips.add(_buildFilterChip(
        label: zoneName,
        onClear: () {
          _bloc.add(const ChangeActivitiesZoneFilter(null));
        },
      ));
    }

    if (state.selectedClusterId != null) {
      final clusterName = meta.clusters
              .where((c) => c.id == state.selectedClusterId)
              .firstOrNull
              ?.name ??
          'Cluster';
      chips.add(_buildFilterChip(
        label: clusterName,
        onClear: () {
          _bloc.add(const ChangeActivitiesClusterFilter(null));
        },
      ));
    }

    if (state.selectedStatus != null) {
      chips.add(_buildFilterChip(
        label: 'Status: ${state.selectedStatus}',
        onClear: () {
          _bloc.add(const ChangeActivitiesStatusFilter(null));
        },
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

  void _openFilterBottomSheet(
    BuildContext context,
    ActivitiesLoaded state,
    MetaDataModel meta,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: _bloc,
          child: BlocBuilder<ActivitiesBloc, ActivitiesState>(
            builder: (bottomSheetContext, bottomSheetState) {
              if (bottomSheetState is! ActivitiesLoaded) return const SizedBox.shrink();
              final currentActiveCount = _activeActivitiesFiltersCount(bottomSheetState);

              // Build zone options
              final zoneOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Zones'),
              ];
              if (meta.zones.isNotEmpty) {
                zoneOptions.addAll(meta.zones.map((z) => DropdownItemOption(value: z.id, label: z.name)));
              } else {
                final distinctZones = <String, String>{};
                for (final s in bottomSheetState.response.items) {
                  if (s.zoneId != null && s.zoneName.isNotEmpty) {
                    distinctZones[s.zoneId!] = s.zoneName;
                  }
                }
                zoneOptions.addAll(distinctZones.entries.map((e) => DropdownItemOption(value: e.key, label: e.value)));
              }

              // Build cluster options
              final clusterOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Clusters'),
              ];
              if (meta.clusters.isNotEmpty) {
                clusterOptions.addAll(
                  meta
                      .clustersForZone(bottomSheetState.selectedZoneId)
                      .map((c) => DropdownItemOption(value: c.id, label: c.name)),
                );
              } else {
                final distinctClusters = <String, String>{};
                for (final s in bottomSheetState.response.items) {
                  if (s.clusterId != null && s.clusterName.isNotEmpty) {
                    if (bottomSheetState.selectedZoneId == null || s.zoneId == bottomSheetState.selectedZoneId) {
                      distinctClusters[s.clusterId!] = s.clusterName;
                    }
                  }
                }
                clusterOptions.addAll(distinctClusters.entries.map((e) => DropdownItemOption(value: e.key, label: e.value)));
              }

              // Site options
              final siteOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Sites'),
                ...bottomSheetState.knownSites
                    .map((s) => DropdownItemOption(value: s.siteId, label: s.siteName)),
              ];

              // Status options
              final statusOptions = const <DropdownItemOption<String?>>[
                DropdownItemOption(value: null, label: 'All Statuses'),
                DropdownItemOption(value: 'SCHEDULED', label: 'Scheduled'),
                DropdownItemOption(value: 'ASSIGNED', label: 'Assigned'),
                DropdownItemOption(value: 'PENDING', label: 'Pending'),
                DropdownItemOption(value: 'COMPLETED', label: 'Completed'),
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
                    // Handle
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

                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF0F172A)),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Activities',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        if (currentActiveCount > 0)
                          TextButton(
                            onPressed: () {
                              _bloc.add(const ResetActivitiesFilters());
                              _bloc.add(const ChangeActivitiesSiteFilter(null));
                            },
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Site Filter
                    Text(
                      'Site',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomDropdownButton2<String?>(
                      selectedValue: bottomSheetState.selectedSiteId,
                      options: siteOptions,
                      placeholder: 'All Sites',
                      buttonHeight: 42,
                      maxHeight: 260,
                      enableSearch: true,
                      searchHint: 'Search site...',
                      onSelect: (val) {
                        _bloc.add(ChangeActivitiesSiteFilter(val));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Zone Filter
                    Text(
                      'Zone',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomDropdownButton2<String?>(
                      selectedValue: bottomSheetState.selectedZoneId,
                      options: zoneOptions,
                      buttonHeight: 42,
                      maxHeight: 260,
                      enableSearch: true,
                      onSelect: (val) {
                        _bloc.add(ChangeActivitiesZoneFilter(val));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Cluster Filter
                    Text(
                      'Cluster',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomDropdownButton2<String?>(
                      selectedValue: bottomSheetState.selectedClusterId,
                      options: clusterOptions,
                      buttonHeight: 42,
                      maxHeight: 260,
                      enableSearch: true,
                      onSelect: (val) {
                        _bloc.add(ChangeActivitiesClusterFilter(val));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Status Filter
                    Text(
                      'Status',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomDropdownButton2<String?>(
                      selectedValue: bottomSheetState.selectedStatus,
                      options: statusOptions,
                      buttonHeight: 42,
                      maxHeight: 260,
                      enableSearch: false,
                      onSelect: (val) {
                        _bloc.add(ChangeActivitiesStatusFilter(val));
                      },
                    ),
                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRoleFilterChips(ActivitiesLoaded state) {
    final roles = state.activitiesResponse.belowRoles.isNotEmpty
        ? state.activitiesResponse.belowRoles
            .map((r) => RoleOptionModel(role: r.role, label: r.label))
            .toList()
        : state.response.belowRoles;
    final isAllSelected = state.selectedRole == null ||
        state.selectedRole == 'ALL' ||
        state.selectedRole!.isEmpty;

    final allChips = <_ActivityRoleChipData>[
      _ActivityRoleChipData(label: 'All', role: null, isSelected: isAllSelected),
      ...roles.map((r) => _ActivityRoleChipData(
            label: r.label,
            role: r.role,
            isSelected: state.selectedRole?.toUpperCase() == r.role.toUpperCase(),
          )),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        if (availableWidth <= 0) return const SizedBox.shrink();

        // Measure each chip's approximate width including padding & spacing
        final chipWidths = <double>[];
        for (final chip in allChips) {
          final tp = TextPainter(
            text: TextSpan(
              text: chip.label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          // 28 padding (14 left + 14 right) + 8 spacing between chips
          chipWidths.add(tp.width + 28 + 8);
        }

        const viewMoreWidth = 115.0; // Room for 'View more (+N)' + icon
        const spacing = 8.0;

        // Calculate how many chips fit in 2 lines
        int visibleCount = allChips.length;
        bool exceedsTwoLines = false;

        double currentLineWidth = 0;
        int currentLine = 1;

        for (int i = 0; i < allChips.length; i++) {
          final w = chipWidths[i];
          if (currentLineWidth + w - spacing <= availableWidth) {
            currentLineWidth += w;
          } else {
            currentLine++;
            if (currentLine > 2) {
              exceedsTwoLines = true;
              break;
            }
            currentLineWidth = w;
          }
        }

        if (exceedsTwoLines && !_isRoleChipsExpanded) {
          // Recalculate leaving room for 'View more' on line 2
          currentLineWidth = 0;
          currentLine = 1;
          visibleCount = 0;

          for (int i = 0; i < allChips.length; i++) {
            final w = chipWidths[i];
            if (currentLine == 1) {
              if (currentLineWidth + w - spacing <= availableWidth) {
                currentLineWidth += w;
                visibleCount++;
              } else {
                currentLine = 2;
                currentLineWidth = w;
                visibleCount++;
              }
            } else if (currentLine == 2) {
              final isLastItem = (i == allChips.length - 1);
              final neededWidth = isLastItem
                  ? (currentLineWidth + w - spacing)
                  : (currentLineWidth + w + viewMoreWidth);

              if (neededWidth <= availableWidth) {
                currentLineWidth += w;
                visibleCount++;
              } else {
                break;
              }
            }
          }
          if (visibleCount == 0 && allChips.isNotEmpty) {
            visibleCount = 1;
          }
        }

        final displayedChips = _isRoleChipsExpanded
            ? allChips
            : allChips.take(visibleCount).toList();

        final hiddenCount = allChips.length - displayedChips.length;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...displayedChips.map((c) => _buildRoleChip(
                  label: c.label,
                  isSelected: c.isSelected,
                  onTap: () {
                    if (state.isLoadingDetail) return;
                    if (c.role == null) {
                      _bloc.add(const ChangeActivitiesRoleFilter(null));
                    } else {
                      _bloc.add(ChangeActivitiesRoleFilter(c.isSelected ? null : c.role));
                    }
                  },
                )),
            if (exceedsTwoLines || _isRoleChipsExpanded)
              _buildViewMoreChip(
                isExpanded: _isRoleChipsExpanded,
                hiddenCount: hiddenCount,
                onTap: () {
                  setState(() {
                    _isRoleChipsExpanded = !_isRoleChipsExpanded;
                  });
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildViewMoreChip({
    required bool isExpanded,
    required int hiddenCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isExpanded
                  ? 'Show less'
                  : (hiddenCount > 0 ? 'View more (+$hiddenCount)' : 'View more'),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesSectionHeader(ActivitiesLoaded state) {
    final count = state.filteredActivities.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 20, color: Color(0xFF334155)),
            const SizedBox(width: 8),
            Text(
              'Activities',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
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

        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow,
              const SizedBox(height: 8),
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
              'Loading activities...',
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
            const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No activities found',
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
            // Row 1: Status pill & Scheduled date
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
              activity.title.isNotEmpty
                  ? activity.title
                  : '${activity.roleLabel.isNotEmpty ? activity.roleLabel : "CRRM"} Visit',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Metadata badges row: Role, Frequency, Assigned SPOC, Priority
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
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
                          '${activity.siteName} · ${activity.siteCity.isNotEmpty ? activity.siteCity : "NA"}',
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
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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

  Widget _buildActivitiesTable(BuildContext context, List<SiteActivityItemModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 640),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingRowHeight: 44,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columnSpacing: 24,
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
              rows: items.map((activity) {
                return DataRow(
                  onSelectChanged: (_) {
                    _bloc.add(SelectActivityForDetail(activity.id));
                  },
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            activity.siteName,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (activity.siteCity.isNotEmpty)
                            Text(
                              activity.siteCity,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        activity.title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        activity.frequencyLabel.isNotEmpty ? activity.frequencyLabel : 'Quarterly',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
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
                    DataCell(_buildStatusPill(activity.status, activity.statusLabel)),
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
    Color bg;
    Color border;
    Color text;
    Color dot;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF16A34A);
        dot = const Color(0xFF22C55E);
        break;
      case 'ASSIGNED':
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF2563EB);
        dot = const Color(0xFF3B82F6);
        break;
      case 'OVERDUE':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFDC2626);
        dot = const Color(0xFFEF4444);
        break;
      case 'SCHEDULED':
      case 'PENDING':
      default:
        bg = const Color(0xFFFFFDF5);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFD97706);
        dot = const Color(0xFFF59E0B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.isNotEmpty ? label : status,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: text,
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
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(ActivitiesLoaded state) {
    final res = state.activitiesResponse;
    if (res.total <= res.limit) return const SizedBox.shrink();

    final currentStart = res.offset + 1;
    final currentEnd = (res.offset + res.limit).clamp(0, res.total);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $currentStart-$currentEnd of ${res.total}',
            style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: res.offset > 0
                    ? () {
                        final prevOffset = (res.offset - res.limit).clamp(0, res.total);
                        _bloc.add(LoadActivitiesPage(offset: prevOffset, limit: res.limit));
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Previous', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: currentEnd < res.total
                    ? () {
                        _bloc.add(LoadActivitiesPage(offset: res.offset + res.limit, limit: res.limit));
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Next', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSitesSectionHeader(ActivitiesLoaded state) {
    return Row(
      children: [
        const Icon(Icons.apartment_outlined, size: 20, color: Color(0xFF334155)),
        const SizedBox(width: 8),
        Text(
          'Sites',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
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
            '${state.filteredSites.length}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSitesList(ActivitiesLoaded state) {
    if (state.isLoadingDetail) {
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
              'Loading activities...',
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

    final sites = state.filteredSites;

    if (sites.isEmpty) {
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
            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No sites found',
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

    return Column(
      children: sites.map((site) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSiteCard(site),
        );
      }).toList(),
    );
  }

  Widget _buildSiteCard(ActivitySiteItemModel site) {
    final percent = site.completionPercent;

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;

    if (percent == 100) {
      badgeBg = const Color(0xFFF0FDF4);
      badgeBorder = const Color(0xFFBBF7D0);
      badgeText = const Color(0xFF16A34A);
    } else if (percent >= 50) {
      badgeBg = const Color(0xFFFFFBEB);
      badgeBorder = const Color(0xFFFDE68A);
      badgeText = const Color(0xFFD97706);
    } else {
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFECACA);
      badgeText = const Color(0xFFDC2626);
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final screenWidth = MediaQuery.sizeOf(ctx).width;
        final isNarrow = constraints.maxWidth < 768 || screenWidth < 768;

        final siteInfo = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              site.siteName,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              site.subtitleDisplay,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        );

        final percentPill = Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeBorder),
          ),
          child: Text(
            '$percent%',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeText,
            ),
          ),
        );

        Widget metricsRow;
        if (isNarrow) {
          metricsRow = Row(
            children: [
              percentPill,
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniMetric(
                  label: 'Total',
                  value: '${site.total}',
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniMetric(
                  label: 'Completed',
                  value: '${site.completed}',
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniMetric(
                  label: 'Pending',
                  value: '${site.pending}',
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          );
        } else {
          metricsRow = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              percentPill,
              const SizedBox(width: 14),
              _buildMiniMetric(
                label: 'Total',
                value: '${site.total}',
                color: const Color(0xFF0F172A),
                fixedWidth: 70,
              ),
              const SizedBox(width: 10),
              _buildMiniMetric(
                label: 'Completed',
                value: '${site.completed}',
                color: const Color(0xFF16A34A),
                fixedWidth: 75,
              ),
              const SizedBox(width: 10),
              _buildMiniMetric(
                label: 'Pending',
                value: '${site.pending}',
                color: const Color(0xFFD97706),
                fixedWidth: 65,
              ),
            ],
          );
        }

        return InkWell(
          onTap: () {
            _bloc.add(SelectSiteForActivities(site));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isNarrow ? 12 : 16),
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
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      siteInfo,
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),
                      metricsRow,
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: siteInfo),
                      metricsRow,
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
    double? fixedWidth,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );

    if (fixedWidth != null) {
      return SizedBox(
        width: fixedWidth,
        child: content,
      );
    }
    return content;
  }
}

class _ActivityRoleChipData {
  final String label;
  final String? role;
  final bool isSelected;

  const _ActivityRoleChipData({
    required this.label,
    required this.role,
    required this.isSelected,
  });
}
