import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/datasources/sites_remote_datasource.dart';
import '../../data/models/site_model.dart';
import 'site_detail_page.dart';
import '../bloc/renewals_bloc.dart';
import '../bloc/renewals_event.dart';
import '../bloc/renewals_state.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

class RenewalSitesPage extends StatefulWidget {
  final RenewalsBloc? bloc;

  const RenewalSitesPage({super.key, this.bloc});

  @override
  State<RenewalSitesPage> createState() => _RenewalSitesPageState();
}

class _RenewalSitesPageState extends State<RenewalSitesPage> {
  late final RenewalsBloc _bloc;
  late final TextEditingController _searchController;
  bool _ownsBloc = false;
  bool _isCardView = true;

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      _bloc = RenewalsBloc(dataSource: SitesRemoteDataSourceImpl());
      _ownsBloc = true;
    }

    _searchController = TextEditingController();
    _bloc.add(const LoadRenewalSites());
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
            padding: const EdgeInsets.only(top: 0),
            child: BlocBuilder<RenewalsBloc, RenewalsState>(
              builder: (context, state) {
                if (state is RenewalsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kBlue),
                  );
                }

                if (state is RenewalsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load renewal sites',
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
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: _kSlate,
                            ),
                          ),

                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _bloc.add(
                                const LoadRenewalSites(isRefresh: true),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is RenewalsLoaded) {
                  final meta = MetaService.instance.meta;
                  return RefreshIndicator(
                    color: _kBlue,
                    onRefresh: () async {
                      _bloc.add(const LoadRenewalSites(isRefresh: true));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(context, state, meta),
                          const SizedBox(height: 16),

                          // 4 Window Metric Cards
                          _buildWindowMetricCards(state),
                          const SizedBox(height: 18),

                          // Search Bar
                          _buildSearchBar(context, state),
                          const SizedBox(height: 16),

                          // Sub-header with count and Table / Card Toggle
                          _buildSubHeader(state),
                          const SizedBox(height: 12),

                          // Sites View (Card or Table)
                          if (state.isLoadingPage)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: CircularProgressIndicator(color: _kBlue),
                              ),
                            )
                          else if (_isCardView)
                            _buildCardView(state)
                          else
                            _buildTableView(state),

                          // Pagination Controls (Show only if total > 10)
                          if (state.response.total > 10) ...[
                            const SizedBox(height: 16),
                            _buildPaginationBar(state),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
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

  int _activeRenewalFiltersCount(RenewalsLoaded state) {
    int count = 0;
    if (state.selectedZoneId != null) count++;
    if (state.selectedClusterId != null) count++;
    if (state.selectedClientType != null) count++;
    return count;
  }

  Widget _buildHeader(
    BuildContext context,
    RenewalsLoaded state,
    MetaDataModel meta,
  ) {
    final activeCount = _activeRenewalFiltersCount(state);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const SizedBox(height: 10),
              Text(
                'Renewal Sites',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Site master · sistes nearing contract renewal window',
                style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _openRenewalFilterBottomSheet(context, state, meta),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
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

  Widget _buildWindowMetricCards(RenewalsLoaded state) {
    final counts = state.response.windowCounts;

    final cards = [
      _buildWindowCard(
        window: '30',
        title: '30 Days',
        count: counts.count30,
        subtitle: 'Expiring ≤ 30 days',
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFDC2626),
        isActive: state.selectedWindow == '30',
      ),
      _buildWindowCard(
        window: '60',
        title: '60 Days',
        count: counts.count60,
        subtitle: 'Expiring ≤ 60 days',
        icon: Icons.calendar_month_outlined,
        iconColor: const Color(0xFFD97706),
        isActive: state.selectedWindow == '60',
      ),
      _buildWindowCard(
        window: '90',
        title: '90 Days',
        count: counts.count90,
        subtitle: 'Expiring ≤ 90 days',
        icon: Icons.event_note_outlined,
        iconColor: const Color(0xFF2563EB),
        isActive: state.selectedWindow == '90',
      ),
      _buildWindowCard(
        window: 'pending',
        title: 'Pending',
        count: counts.countPending,
        subtitle: 'Renewal pending',
        icon: Icons.pending_actions_rounded,
        iconColor: const Color(0xFF64748B),
        isActive: state.selectedWindow == 'pending',
      ),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 620;

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _buildWindowCard({
    required String window,
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        _bloc.add(ChangeRenewalWindow(window));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _kBlue : const Color(0xFFE2E8F0),
            width: isActive ? 1.8 : 1,
          ),
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
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? _kBlue : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: iconColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isActive ? _kBlue : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, RenewalsLoaded state) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          _bloc.add(SearchRenewalQueryChanged(val));
        },
        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search site, code, client...',
          hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _bloc.add(const SearchRenewalQueryChanged(''));
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  void _openRenewalFilterBottomSheet(
    BuildContext context,
    RenewalsLoaded state,
    MetaDataModel meta,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: _bloc,
          child: BlocBuilder<RenewalsBloc, RenewalsState>(
            builder: (bottomSheetContext, bottomSheetState) {
              if (bottomSheetState is! RenewalsLoaded) {
                return const SizedBox.shrink();
              }
              final currentActiveCount = _activeRenewalFiltersCount(
                bottomSheetState,
              );

              final zoneOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Zones'),
                ...meta.zones.map(
                  (z) => DropdownItemOption(value: z.id, label: z.name),
                ),
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
                  16,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Renewal Sites',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (currentActiveCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _kBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$currentActiveCount',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (currentActiveCount > 0)
                          TextButton(
                            onPressed: () {
                              _bloc.add(const ResetRenewalFilters());
                            },
                            child: Text(
                              'Reset All',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Filter Fields
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Zone
                            Text(
                              'Zone',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            CustomDropdownButton2<String?>(
                              selectedValue: bottomSheetState.selectedZoneId,
                              options: zoneOptions,
                              buttonHeight: 44,
                              maxHeight: 260,
                              enableSearch: true,
                              onSelect: (val) {
                                _bloc.add(ChangeRenewalZoneFilter(val));
                              },
                            ),
                            const SizedBox(height: 14),

                            // Cluster
                            Text(
                              'Cluster',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            CustomDropdownButton2<String?>(
                              selectedValue: bottomSheetState.selectedClusterId,
                              options: clusterOptions,
                              buttonHeight: 44,
                              maxHeight: 260,
                              enableSearch: true,
                              onSelect: (val) {
                                _bloc.add(ChangeRenewalClusterFilter(val));
                              },
                            ),
                            const SizedBox(height: 14),

                            // Client Type
                            Text(
                              'Client Type',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            CustomDropdownButton2<String?>(
                              selectedValue:
                                  bottomSheetState.selectedClientType,
                              options: clientTypeOptions,
                              buttonHeight: 44,
                              maxHeight: 260,
                              enableSearch: false,
                              onSelect: (val) {
                                _bloc.add(ChangeRenewalClientTypeFilter(val));
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Button
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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

  Widget _buildSubHeader(RenewalsLoaded state) {
    final total = state.response.total;
    final itemsCount = state.filteredItems.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 18,
              color: Color(0xFF334155),
            ),
            const SizedBox(width: 6),
            Text(
              'Showing $itemsCount of $total sites in scope',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),

        // Table / Card View Toggle
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Table Option
              InkWell(
                onTap: () {
                  if (_isCardView) {
                    setState(() => _isCardView = false);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: !_isCardView ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: !_isCardView
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 13,
                        color: !_isCardView ? _kBlue : _kSlate,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Table',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: !_isCardView
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: !_isCardView ? _kBlue : _kSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Card Option
              InkWell(
                onTap: () {
                  if (!_isCardView) {
                    setState(() => _isCardView = true);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _isCardView ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: _isCardView
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.view_agenda_outlined,
                        size: 13,
                        color: _isCardView ? _kBlue : _kSlate,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Card',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: _isCardView
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _isCardView ? _kBlue : _kSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableView(RenewalsLoaded state) {
    final sites = state.filteredItems;

    if (sites.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
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
            constraints: const BoxConstraints(minWidth: 850),
            child: DataTable(
              showCheckboxColumn: false,
              border: const TableBorder(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                left: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                horizontalInside: BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
                verticalInside: BorderSide.none,
              ),
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
                    'Expiry / Days Left',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Geography',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Client & Type',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Billing PM',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'SPOC',
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
                DataColumn(
                  label: Text(
                    'Actions',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              rows: sites.map((site) {
                return DataRow(
                  onSelectChanged: (_) => _navigateToSiteDetail(context, site),
                  cells: [
                    // Site Name & Code
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            site.name,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            site.code,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: _kSlate,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expiry Pill
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDaysRemainingBadge(site.daysRemaining),
                          const SizedBox(height: 2),
                          Text(
                            site.formattedContractEndDate,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: _kSlate,
                            ),
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
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            site.clusterName.isNotEmpty
                                ? site.clusterName
                                : '—',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: _kSlate,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Client & Type
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            site.clientName.isNotEmpty
                                ? site.clientName
                                : site.name,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              site.clientType,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                              ),
                            ),
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
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // SPOC / Contact
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            site.contactPersonName ??
                                (site.lead.isNotEmpty ? site.lead : '—'),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (site.contactPhone != null &&
                              site.contactPhone!.isNotEmpty)
                            Text(
                              site.contactPhone!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: _kSlate,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Status
                    DataCell(_buildStatusBadge(site.status)),

                    // Action
                    DataCell(
                      InkWell(
                        onTap: () => _navigateToSiteDetail(context, site),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'View →',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kBlue,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildCardView(RenewalsLoaded state) {
    final sites = state.filteredItems;

    if (sites.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: sites.map((site) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSiteRenewalCard(site),
        );
      }).toList(),
    );
  }

  Widget _buildSiteRenewalCard(SiteItemModel site) {
    return InkWell(
      onTap: () => _navigateToSiteDetail(context, site),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Site Name, Code, and Expiry Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${site.code} · ${site.serviceName.isNotEmpty ? site.serviceName : 'HK'}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _kSlate,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDaysRemainingBadge(site.daysRemaining),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Metadata Grid: 2 columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildRenewalMetaItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Contract End',
                    value: site.formattedContractEndDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRenewalMetaItem(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Billing PM',
                    value: site.formattedBillingPm,
                    isHighlighted: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildRenewalMetaItem(
                    icon: Icons.location_on_outlined,
                    label: 'Geography',
                    value:
                        '${site.zoneName.isNotEmpty ? site.zoneName : '—'} · ${site.clusterName.isNotEmpty ? site.clusterName : '—'}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRenewalMetaItem(
                    icon: Icons.business_rounded,
                    label: 'Client (Type)',
                    value:
                        '${site.clientName.isNotEmpty ? site.clientName : site.name} (${site.clientType})',
                  ),
                ),
              ],
            ),
            if (site.contactPersonName != null &&
                site.contactPersonName!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildRenewalMetaItem(
                icon: Icons.person_outline_rounded,
                label: 'Contact',
                value:
                    '${site.contactPersonName} (${site.contactPhone ?? "—"})',
              ),
            ],
            const SizedBox(height: 14),

            // View Details Button / Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(site.status),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View site details',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _kBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: _kBlue,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenewalMetaItem({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: _kSlate),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: _kSlate,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                  color: isHighlighted
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF334155),
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

  Widget _buildDaysRemainingBadge(int? days) {
    if (days == null) {
      return Text('—', style: GoogleFonts.outfit(fontSize: 12, color: _kSlate));
    }

    Color bg;
    Color border;
    Color text;

    if (days <= 0) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFDC2626);
    } else if (days <= 30) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFDC2626);
    } else if (days <= 60) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFD97706);
    } else {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      text = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        days <= 0 ? 'Expired' : '$days days left',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isLive = status.toUpperCase() == 'LIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive ? const Color(0xFFBBF7D0) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFF16A34A) : _kSlate,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isLive ? const Color(0xFF16A34A) : _kSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            'No renewal sites found',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'There are no contracts expiring in this renewal window.',
            style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(RenewalsLoaded state) {
    final total = state.response.total;
    if (total <= 10) {
      return const SizedBox.shrink();
    }
    final totalPages = state.totalPages;
    final currentPage = state.currentPage;
    final pageSize = state.pageSize;

    final start = total == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final end = min(currentPage * pageSize, total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $start-$end of $total',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kSlate,
          ),
        ),
        Row(
          children: [
            // Previous button
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: currentPage > 1
                  ? () {
                      _bloc.add(ChangeRenewalPage(currentPage - 1));
                    }
                  : null,
            ),
            Text(
              'Page $currentPage of $totalPages',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            // Next button
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: currentPage < totalPages
                  ? () {
                      _bloc.add(ChangeRenewalPage(currentPage + 1));
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToSiteDetail(BuildContext context, SiteItemModel site) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SiteDetailPage(siteId: site.id)));
  }
}
