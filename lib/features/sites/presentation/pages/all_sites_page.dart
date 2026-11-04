import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/datasources/sites_remote_datasource.dart';
import '../../data/models/site_model.dart';
import 'site_detail_page.dart';
import '../bloc/sites_bloc.dart';
import '../bloc/sites_event.dart';
import '../bloc/sites_state.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kGreen = Color(0xFF16A34A);
const _kAmber = Color(0xFFD97706);
const _kRed = Color(0xFFEF4444);

class AllSitesPage extends StatelessWidget {
  final SitesBloc? bloc;
  final String? initialZoneId;
  final String? initialClusterId;

  const AllSitesPage({
    super.key,
    this.bloc,
    this.initialZoneId,
    this.initialClusterId,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: const _AllSitesView(),
      );
    }
    return BlocProvider(
      create: (_) => SitesBloc(
        dataSource: SitesRemoteDataSourceImpl(),
      )..add(LoadSites(
          initialZoneId: initialZoneId,
          initialClusterId: initialClusterId,
        )),
      child: const _AllSitesView(),
    );
  }
}

class _AllSitesView extends StatefulWidget {
  const _AllSitesView();

  @override
  State<_AllSitesView> createState() => _AllSitesViewState();
}

class _AllSitesViewState extends State<_AllSitesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocConsumer<SitesBloc, SitesState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is SitesLoading || state is SitesInitial) {
              return const Center(
                child: CircularProgressIndicator(color: _kBlue),
              );
            }

            if (state is SitesError) {
              return _buildErrorView(context, state.message);
            }

            if (state is SitesLoaded) {
              return _buildLoadedContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, SitesLoaded state) {
    final meta = MetaService.instance.meta;
    final items = state.displayItems;
    final tabCounts = state.response.tabCounts;

    return RefreshIndicator(
      color: _kBlue,
      onRefresh: () async {
        context.read<SitesBloc>().add(const LoadSites(isRefresh: true));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          // ── Header (All Sites + Subtitle + Filter button) ────────────────
          _buildHeader(context, state, meta),
          const SizedBox(height: 14),

          // ── 5 Tab / Metric Cards (Matches Screenshot 2) ───────────────────
          _buildMetricCards(context, state, tabCounts),
          const SizedBox(height: 14),

          // ── Search Bar ─────────────────────────────────────────────────────
          _buildSearchBar(context, state),
          if (_activeSitesFiltersCount(state) > 0)
            _buildActiveFilterChips(context, state, meta),
          const SizedBox(height: 14),

          // ── Table / List View ─────────────────────────────────────────────
          if (state.isLoadingPage)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: _kBlue)),
            )
          else if (items.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(
              builder: (ctx, constraints) {
                if (constraints.maxWidth < 700) {
                  return _buildMobileCardList(items);
                }
                return _buildDataTable(items);
              },
            ),

          // ── Pagination Bar (Show only if total > 10) ──────────────────────
          if (state.totalCount > 10) ...[
            const SizedBox(height: 16),
            _buildPaginationBar(context, state),
          ],
        ],
      ),
    );
  }

  int _activeSitesFiltersCount(SitesLoaded state) {
    int count = 0;
    if (state.selectedStatus != null) count++;
    if (state.selectedZoneId != null) count++;
    if (state.selectedClusterId != null) count++;
    if (state.selectedClientType != null) count++;
    if (state.selectedMode != null) count++;
    return count;
  }

  // ── Header (All Sites + Subtitle + Filter button with active count) ────────
  Widget _buildHeader(BuildContext context, SitesLoaded state, MetaDataModel meta) {
    final activeCount = _activeSitesFiltersCount(state);
    final canPop = Navigator.of(context).canPop();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (canPop) ...[
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 16, color: _kBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Back',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Sites',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Site master · access is filtered to your geography scope',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: _kSlate,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _openFilterBottomSheet(context, state, meta),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: activeCount > 0 ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeCount > 0 ? _kBlue : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: activeCount > 0 ? _kBlue : const Color(0xFF334155),
                ),
                const SizedBox(width: 6),
                Text(
                  'Filter',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: activeCount > 0 ? _kBlue : const Color(0xFF334155),
                  ),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: _kBlue,
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
        ),
      ],
    );
  }

  // ── 5 Metric Cards (All, Live, Transition, Special Attention, Draft) ───────
  Widget _buildMetricCards(
    BuildContext context,
    SitesLoaded state,
    SiteTabCountsModel counts,
  ) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final cards = [
          _MetricCardItem(
            title: 'All Sites',
            count: counts.all,
            subtitle: 'In your allocation',
            icon: Icons.apartment_rounded,
            isSelected: state.selectedTab == 'All',
            activeColor: _kBlue,
            onTap: () => context.read<SitesBloc>().add(const ChangeSitesTab('All')),
          ),
          _MetricCardItem(
            title: 'Live Sites',
            count: counts.live,
            subtitle: 'Operational · live',
            icon: Icons.check_circle_outline_rounded,
            isSelected: state.selectedTab == 'LIVE',
            activeColor: _kGreen,
            onTap: () => context.read<SitesBloc>().add(const ChangeSitesTab('LIVE')),
          ),
          _MetricCardItem(
            title: 'Transition',
            count: counts.transition,
            subtitle: 'In transition pipeline',
            icon: Icons.swap_horiz_rounded,
            isSelected: state.selectedTab == 'Transition',
            activeColor: _kAmber,
            onTap: () => context.read<SitesBloc>().add(const ChangeSitesTab('Transition')),
          ),
          _MetricCardItem(
            title: 'Special attention',
            count: counts.special,
            subtitle: 'Needs attention',
            icon: Icons.flag_outlined,
            isSelected: state.selectedTab == 'Special',
            activeColor: _kRed,
            onTap: () => context.read<SitesBloc>().add(const ChangeSitesTab('Special')),
          ),
          _MetricCardItem(
            title: 'Draft',
            count: counts.draft,
            subtitle: 'Not yet live',
            icon: Icons.description_outlined,
            isSelected: state.selectedTab == 'Draft',
            activeColor: _kSlate,
            onTap: () => context.read<SitesBloc>().add(const ChangeSitesTab('Draft')),
          ),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        }

        // Horizontal scrollable on compact mobile screens
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: cards
                .map((c) => Container(
                      width: 156,
                      margin: const EdgeInsets.only(right: 8),
                      child: c,
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context, SitesLoaded state) {
    final activeCount = _activeSitesFiltersCount(state);

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<SitesBloc>().add(SearchQueryChanged(val));
              },
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search name, code, client, city...',
                hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kSlate),
                prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: _kSlate),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SitesBloc>().add(const SearchQueryChanged(''));
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          if (activeCount > 0) ...[
            InkWell(
              onTap: () {
                context.read<SitesBloc>().add(const ResetSitesFilters());
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Clear ($activeCount)',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(BuildContext context, SitesLoaded state, MetaDataModel meta) {
    final chips = <Widget>[];

    if (state.selectedZoneId != null) {
      final zoneName = meta.zones
              .where((z) => z.id == state.selectedZoneId)
              .firstOrNull
              ?.name ??
          'Zone';
      chips.add(_buildFilterChip(
        label: zoneName,
        onClear: () {
          context.read<SitesBloc>().add(const ChangeZoneFilter(null));
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
          context.read<SitesBloc>().add(const ChangeClusterFilter(null));
        },
      ));
    }

    if (state.selectedStatus != null) {
      chips.add(_buildFilterChip(
        label: 'Status: ${state.selectedStatus}',
        onClear: () {
          context.read<SitesBloc>().add(const ChangeStatusFilter(null));
        },
      ));
    }

    if (state.selectedClientType != null) {
      chips.add(_buildFilterChip(
        label: 'Type: ${state.selectedClientType}',
        onClear: () {
          context.read<SitesBloc>().add(const ChangeClientTypeFilter(null));
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
              context.read<SitesBloc>().add(const ResetSitesFilters());
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
              color: _kBlue,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: _kBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterBottomSheet(
    BuildContext context,
    SitesLoaded state,
    MetaDataModel meta,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<SitesBloc>(),
          child: BlocBuilder<SitesBloc, SitesState>(
            builder: (bottomSheetContext, bottomSheetState) {
              if (bottomSheetState is! SitesLoaded) return const SizedBox.shrink();
              final currentActiveCount = _activeSitesFiltersCount(bottomSheetState);

              final statusOptions = const <DropdownItemOption<String?>>[
                DropdownItemOption(value: null, label: 'All Statuses'),
                DropdownItemOption(value: 'LIVE', label: 'Live'),
                DropdownItemOption(value: 'INACTIVE', label: 'Inactive'),
                DropdownItemOption(value: 'DRAFT', label: 'Draft'),
                DropdownItemOption(value: 'PRE_TRANSITION', label: 'Pre-Transition'),
                DropdownItemOption(value: 'POST_TRANSITION', label: 'Post-Transition'),
                DropdownItemOption(value: 'READY', label: 'Ready'),
              ];

              final zoneOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Zones'),
                ...meta.zones.map((z) => DropdownItemOption(value: z.id, label: z.name)),
              ];

              final clusterOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Clusters'),
                ...meta
                    .clustersForZone(bottomSheetState.selectedZoneId)
                    .map((c) => DropdownItemOption(value: c.id, label: c.name)),
              ];

              final clientTypeOptions = const <DropdownItemOption<String?>>[
                DropdownItemOption(value: null, label: 'All Types'),
                DropdownItemOption(value: 'A+', label: 'A+'),
                DropdownItemOption(value: 'A', label: 'A'),
                DropdownItemOption(value: 'B', label: 'B'),
                DropdownItemOption(value: 'C', label: 'C'),
              ];

              final modeOptions = const <DropdownItemOption<String?>>[
                DropdownItemOption(value: null, label: 'All Modes'),
                DropdownItemOption(value: 'ORGANIC', label: 'Organic'),
                DropdownItemOption(value: 'NEW', label: 'New'),
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
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 20, color: _kBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Sites',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (currentActiveCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  '$currentActiveCount active',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kBlue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            if (currentActiveCount > 0)
                              TextButton(
                                onPressed: () {
                                  bottomSheetContext.read<SitesBloc>().add(const ResetSitesFilters());
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: Text(
                                  'Reset',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: const Color(0xFF64748B),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Filter Fields
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomDropdownButton2<String?>(
                              label: 'Status',
                              selectedValue: bottomSheetState.selectedStatus,
                              options: statusOptions,
                              maxHeight: 260,
                              enableSearch: true,
                              onSelect: (val) {
                                bottomSheetContext.read<SitesBloc>().add(ChangeStatusFilter(val));
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomDropdownButton2<String?>(
                              label: 'Zone',
                              selectedValue: bottomSheetState.selectedZoneId,
                              options: zoneOptions,
                              maxHeight: 260,
                              enableSearch: true,
                              onSelect: (val) {
                                bottomSheetContext.read<SitesBloc>().add(ChangeZoneFilter(val));
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomDropdownButton2<String?>(
                              label: 'Cluster',
                              selectedValue: bottomSheetState.selectedClusterId,
                              options: clusterOptions,
                              maxHeight: 260,
                              enableSearch: true,
                              onSelect: (val) {
                                bottomSheetContext.read<SitesBloc>().add(ChangeClusterFilter(val));
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomDropdownButton2<String?>(
                              label: 'Client Type',
                              selectedValue: bottomSheetState.selectedClientType,
                              options: clientTypeOptions,
                              maxHeight: 260,
                              enableSearch: true,
                              onSelect: (val) {
                                bottomSheetContext.read<SitesBloc>().add(ChangeClientTypeFilter(val));
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomDropdownButton2<String?>(
                              label: 'Client Status / Mode',
                              selectedValue: bottomSheetState.selectedMode,
                              options: modeOptions,
                              maxHeight: 260,
                              placeholder: 'Client status',
                              enableSearch: true,
                              onSelect: (val) {
                                bottomSheetContext.read<SitesBloc>().add(ChangeModeFilter(val));
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
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

  // ── Data Table (Desktop / Tablet matching Screenshot 2) ────────────────────
  Widget _buildDataTable(List<SiteItemModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 850),
          child: DataTable(
            showCheckboxColumn: false,
            horizontalMargin: 16,
            columnSpacing: 18,
            headingRowHeight: 44,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            border: const TableBorder(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              left: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              verticalInside: BorderSide.none,
            ),
            columns: [
              DataColumn(label: _tableHeader('Site')),
              DataColumn(label: _tableHeader('Geography')),
              DataColumn(label: _tableHeader('Billing PM')),
              DataColumn(label: _tableHeader('Client type')),
              DataColumn(label: _tableHeader('Manpower')),
              DataColumn(label: _tableHeader('SPOC (Lead)')),
              DataColumn(label: _tableHeader('Status')),
              DataColumn(label: _tableHeader('Actions')),
            ],
            rows: items.map((site) {
              return DataRow(
                onSelectChanged: (_) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SiteDetailPage(siteId: site.id),
                    ),
                  );
                },
                cells: [
                  // Site
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              site.name,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (site.specialAttention) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.flag_rounded, size: 14, color: _kRed),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          site.sublineDisplay,
                          style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
                        ),
                      ],
                    ),
                  ),

                  // Geography
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          site.zoneName.isNotEmpty ? site.zoneName : '—',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          site.clusterName.isNotEmpty ? site.clusterName : '—',
                          style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
                        ),
                      ],
                    ),
                  ),

                  // Billing PM
                  DataCell(
                    Text(
                      site.formattedBillingPm,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),

                  // Client type
                  DataCell(_buildClientTypeBadge(site.clientType)),

                  // Manpower
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${site.manpowerDeployed}/${site.manpowerRequired}',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (site.shortage > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Short ${site.shortage}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _kRed,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // SPOC (Lead)
                  DataCell(
                    Text(
                      site.leadName,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),

                  // Status
                  DataCell(_buildStatusBadge(site.status)),

                  // Actions
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20, color: _kSlate),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SiteDetailPage(siteId: site.id),
                          ),
                        );
                      },
                      tooltip: 'View details',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Mobile Card List (For screens < 700 width) ─────────────────────────────
  Widget _buildMobileCardList(List<SiteItemModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final site = items[idx];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SiteDetailPage(siteId: site.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Name, Special Flag, Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              site.name,
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (site.specialAttention) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.flag_rounded, size: 15, color: _kRed),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(site.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  site.sublineDisplay,
                  style: GoogleFonts.outfit(fontSize: 11.5, color: _kSlate),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Middle Info Row: Geography, Client Type, Billing PM
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geography',
                          style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${site.zoneName} · ${site.clusterName}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Billing PM',
                          style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          site.formattedBillingPm,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom row: Manpower, SPOC, Client Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildClientTypeBadge(site.clientType),
                        const SizedBox(width: 8),
                        Text(
                          'Manpower: ${site.manpowerDeployed}/${site.manpowerRequired}',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _kSlate,
                          ),
                        ),
                        if (site.shortage > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${site.shortage} Short)',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kRed,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      site.leadName,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Pagination Bar (Show only if total > 10) ──────────────────────────────
  Widget _buildPaginationBar(BuildContext context, SitesLoaded state) {
    final total = state.totalCount;
    if (total <= 10) {
      return const SizedBox.shrink();
    }
    final current = state.currentPage;
    final totalPages = state.totalPages;
    final start = total == 0 ? 0 : (current - 1) * state.pageSize + 1;
    final end = math.min(current * state.pageSize, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $start–$end of $total Sites',
            style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: current > 1
                    ? () => context.read<SitesBloc>().add(ChangeSitesPage(current - 1))
                    : null,
                tooltip: 'Previous page',
              ),
              Text(
                'Page $current of $totalPages',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: current < totalPages
                    ? () => context.read<SitesBloc>().add(ChangeSitesPage(current + 1))
                    : null,
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Badges ─────────────────────────────────────────────────────────────────
  Widget _tableHeader(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _buildClientTypeBadge(String type) {
    Color bg;
    Color fg;
    switch (type.toUpperCase()) {
      case 'A+':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF9333EA);
        break;
      case 'A':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case 'B':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case 'C':
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toUpperCase();
    Color dotColor;
    Color bgColor;
    Color textColor;
    String label = status;

    if (s == 'LIVE') {
      dotColor = _kGreen;
      bgColor = const Color(0xFFF0FDF4);
      textColor = const Color(0xFF15803D);
      label = 'Live';
    } else if (s.contains('TRANSITION')) {
      dotColor = _kAmber;
      bgColor = const Color(0xFFFFFBEB);
      textColor = const Color(0xFFB45309);
      label = 'Transition';
    } else if (s == 'INACTIVE') {
      dotColor = const Color(0xFF94A3B8);
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF475569);
      label = 'Inactive';
    } else {
      dotColor = _kBlue;
      bgColor = const Color(0xFFEFF6FF);
      textColor = _kBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dotColor.withValues(alpha: 0.2)),
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
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.apartment_outlined, size: 48, color: _kSlate),
          const SizedBox(height: 12),
          Text(
            'No Sites Found',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your filters or search keywords.',
            style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              'Failed to load sites',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SitesBloc>().add(const LoadSites());
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Card Widget ───────────────────────────────────────────────────────
class _MetricCardItem extends StatelessWidget {
  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _MetricCardItem({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : _kBorder,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? activeColor : _kSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? activeColor : _kSlate.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: _kSlate,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
