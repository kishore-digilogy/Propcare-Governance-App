import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/datasources/sites_remote_datasource.dart';
import '../../data/models/site_model.dart';
import '../bloc/transition_bloc.dart';
import '../bloc/transition_event.dart';
import '../bloc/transition_state.dart';
import 'transition_site_detail_page.dart';

const Color _kBlue = Color(0xFF1A73E8);
const Color _kSlate = Color(0xFF64748B);
const Color _kDark = Color(0xFF0F172A);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kBg = Color(0xFFF8FAFC);

class TransitionSitesPage extends StatelessWidget {
  final TransitionBloc? bloc;

  const TransitionSitesPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: const _TransitionSitesView(),
      );
    }

    return BlocProvider(
      create: (_) => TransitionBloc(
        dataSource: SitesRemoteDataSourceImpl(),
      )..add(const LoadTransitionSites()),
      child: const _TransitionSitesView(),
    );
  }
}

class _TransitionSitesView extends StatefulWidget {
  const _TransitionSitesView();

  @override
  State<_TransitionSitesView> createState() => _TransitionSitesViewState();
}

class _TransitionSitesViewState extends State<_TransitionSitesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: BlocConsumer<TransitionBloc, TransitionState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is TransitionLoading || state is TransitionInitial) {
              return const Center(
                child: CircularProgressIndicator(color: _kBlue),
              );
            }

            if (state is TransitionError) {
              return _buildErrorView(context, state.message);
            }

            if (state is TransitionLoaded) {
              return _buildLoadedContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, TransitionLoaded state) {
    return RefreshIndicator(
      color: _kBlue,
      onRefresh: () async {
        context.read<TransitionBloc>().add(const LoadTransitionSites(isRefresh: true));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 16,
            ),
            children: [
              // ── Header (Title + Subtitle + View Toggle) ────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transition & Start-Up',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lifecycle: Site Creation → Site Live → Transition Complete (after L&D Head Stability Verify).',
                          style: GoogleFonts.outfit(
                            fontSize: isDesktop ? 13 : 11.5,
                            color: _kSlate,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildViewToggle(context, state.isTableView),
                ],
              ),
              const SizedBox(height: 14),

              // ── Filter Tabs and Search Bar (Matching Screenshot) ────────────
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tab pills on left
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _buildTabPills(context, state),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Search box on right
                    SizedBox(
                      width: 300,
                      child: _buildSearchBox(context, state),
                    ),
                  ],
                )
              else ...[
                // On mobile / tablet: Tabs row then search box
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildTabPills(context, state),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSearchBox(context, state),
              ],
              const SizedBox(height: 16),

              // ── Content Area: Table View vs Card View ───────────────────────
              if (state.filteredSites.isEmpty)
                _buildEmptyState(state)
              else if (state.isTableView)
                _buildTableView(context, state.filteredSites)
              else
                _buildCardView(context, state.filteredSites),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context, bool isTableView) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              Icons.table_chart_outlined,
              size: 16,
              color: isTableView ? _kBlue : _kSlate,
            ),
            tooltip: 'Table view',
            onPressed: () {
              context.read<TransitionBloc>().add(const ToggleTransitionViewMode(true));
            },
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              Icons.view_agenda_outlined,
              size: 16,
              color: !isTableView ? _kBlue : _kSlate,
            ),
            tooltip: 'Card view',
            onPressed: () {
              context.read<TransitionBloc>().add(const ToggleTransitionViewMode(false));
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabPills(BuildContext context, TransitionLoaded state) {
    final tabs = [
      ('All', 'All Sites (${state.countAll})'),
      ('Site Creation', 'Site Creation (${state.countSiteCreation})'),
      ('Site Live', 'Site Live (${state.countSiteLive})'),
      ('Transition Complete', 'Transition Complete (${state.countTransitionComplete})'),
    ];

    return tabs.map((t) {
      final isSelected = state.activeTab == t.$1;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.read<TransitionBloc>().add(ChangeTransitionTab(t.$1));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _kBlue : _kBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              t.$2,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _kBlue : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSearchBox(BuildContext context, TransitionLoaded state) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(fontSize: 12.5),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          hintText: 'Search site name, code, client...',
          hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: _kSlate),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kSlate),
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: _kSlate),
                  onPressed: () {
                    _searchController.clear();
                    context.read<TransitionBloc>().add(const ChangeTransitionSearch(''));
                  },
                )
              : null,
          border: InputBorder.none,
        ),
        onChanged: (val) {
          context.read<TransitionBloc>().add(ChangeTransitionSearch(val));
        },
      ),
    );
  }

  // ── Table View (Screenshot 1: Desktop table with 4 columns) ────────────────
  Widget _buildTableView(BuildContext context, List<SiteItemModel> sites) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                verticalInside: BorderSide.none,
              ),
              headingRowHeight: 44,
              dataRowMinHeight: 58,
              dataRowMaxHeight: 64,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
              horizontalMargin: 20,
              columnSpacing: 28,
              columns: [
                DataColumn(
                  label: Text(
                    'Site & Client',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Current Transition Stage',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Action Required',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Workflow Action',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              rows: sites.map((site) {
                return DataRow(
                  onSelectChanged: (_) => _handleWorkflowAction(context, site),
                  cells: [
                    // 1. Site & Client
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            site.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: _kDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${site.code}  ·  ${site.clientName}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _kSlate,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Current Transition Stage
                    DataCell(
                      _buildStageBadge(site),
                    ),

                    // 3. Action Required
                    DataCell(
                      Text(
                        site.transitionActionRequired,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: _getActionColor(site),
                        ),
                      ),
                    ),

                    // 4. Workflow Action Button
                    DataCell(
                      _buildWorkflowButton(context, site),
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

  // ── Card View (Mobile / Responsive) ─────────────────────────────────────────
  Widget _buildCardView(BuildContext context, List<SiteItemModel> sites) {
    return Column(
      children: sites.map((site) {
        return InkWell(
          onTap: () => _handleWorkflowAction(context, site),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                // Top Row: Site Name, Code & Client, and Stage Badge
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
                            '${site.code} · ${site.clientName.isNotEmpty ? site.clientName : site.name}',
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
                    _buildStageBadge(site),
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
                      child: _buildCardMetaItem(
                        icon: Icons.location_on_outlined,
                        label: 'Geography',
                        value: '${site.zoneName.isNotEmpty ? site.zoneName : '—'} · ${site.clusterName.isNotEmpty ? site.clusterName : '—'}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCardMetaItem(
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
                      child: _buildCardMetaItem(
                        icon: Icons.badge_outlined,
                        label: 'Client Type',
                        value: site.clientType,
                        isBadge: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCardMetaItem(
                        icon: Icons.person_outline_rounded,
                        label: 'SPOC / Lead',
                        value: site.leadName.isNotEmpty ? site.leadName : (site.lead.isNotEmpty ? site.lead : '—'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action required info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _getActionBgColor(site),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: _getActionColor(site).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: _getActionColor(site),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          site.transitionActionRequired,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getActionColor(site),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Workflow Action Button
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    onPressed: () => _handleWorkflowAction(context, site),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          site.transitionWorkflowButtonLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardMetaItem({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
    bool isBadge = false,
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
              if (isBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                    color: isHighlighted ? const Color(0xFF0F172A) : const Color(0xFF334155),
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

  // ── Stage Badge (Matching Screenshot colors and dot styling) ────────────────
  Widget _buildStageBadge(SiteItemModel site) {
    Color bg;
    Color border;
    Color textColor;
    Color dotColor;
    String label = site.transitionStageLabel;

    if (site.isSiteCreation) {
      bg = const Color(0xFFFFF7ED);
      border = const Color(0xFFFED7AA);
      textColor = const Color(0xFFD97706);
      dotColor = const Color(0xFFEA580C);
    } else if (site.isSiteLive) {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF16A34A);
      dotColor = const Color(0xFF16A34A);
    } else {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF86EFAC);
      textColor = const Color(0xFF15803D);
      dotColor = const Color(0xFF15803D);
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
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(SiteItemModel site) {
    if (site.isSiteCreation) {
      return const Color(0xFFD97706);
    } else if (site.isSiteLive) {
      return const Color(0xFF2563EB);
    } else {
      return const Color(0xFF16A34A);
    }
  }

  Color _getActionBgColor(SiteItemModel site) {
    if (site.isSiteCreation) {
      return const Color(0xFFFFFBEB);
    } else if (site.isSiteLive) {
      return const Color(0xFFEFF6FF);
    } else {
      return const Color(0xFFF0FDF4);
    }
  }

  Widget _buildWorkflowButton(BuildContext context, SiteItemModel site) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        onPressed: () {
          _handleWorkflowAction(context, site);
        },
        child: Text(
          site.transitionWorkflowButtonLabel,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleWorkflowAction(BuildContext context, SiteItemModel site) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransitionSiteDetailPage(siteId: site.id),
      ),
    );
  }

  Widget _buildEmptyState(TransitionLoaded state) {
    return Container(
      padding: const EdgeInsets.all(36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 48, color: _kSlate),
          const SizedBox(height: 12),
          Text(
            'No sites in stage "${state.activeTab}"',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
          if (state.searchQuery.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'No matches found for "${state.searchQuery}"',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: _kSlate,
              ),
            ),
          ],
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
              'Failed to load transition sites',
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
                context.read<TransitionBloc>().add(const LoadTransitionSites());
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
