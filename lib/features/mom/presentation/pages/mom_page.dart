import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_top_header.dart';
import '../../data/datasources/mom_remote_datasource.dart';
import '../../data/models/mom_by_site_model.dart';
import '../bloc/mom_bloc.dart';
import '../bloc/mom_event.dart';
import '../bloc/mom_state.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE8EDF2);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF16A34A);

/// MOM & Email page with full mobile-adaptive design, search, metric cards,
/// tab filters, and detail bottom sheets.
class MomPage extends StatelessWidget {
  const MomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MomBloc(
        dataSource: MomRemoteDataSourceImpl(),
      )..add(const LoadMomBySite()),
      child: const _MomView(),
    );
  }
}

class _MomView extends StatefulWidget {
  const _MomView();

  @override
  State<_MomView> createState() => _MomViewState();
}

class _MomViewState extends State<_MomView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Standard Left-aligned PropCare App Header
            const AppTopHeader(),

            // Main Body with BlocBuilder
            Expanded(
              child: BlocBuilder<MomBloc, MomState>(
                builder: (context, state) {
                  if (state is MomLoading || state is MomInitial) {
                    return _buildLoading();
                  }

                  if (state is MomError) {
                    return _buildError(context, state.message);
                  }

                  if (state is MomLoaded) {
                    return _buildLoadedBody(context, state);
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: _kBlue,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            'Loading MOM & Email visits...',
            style: TextStyle(
              fontSize: 13,
              color: _kSlate,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load MOM Data',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _kSlate,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<MomBloc>()
                    .add(const LoadMomBySite(isRefresh: true));
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedBody(BuildContext context, MomLoaded state) {
    final filteredSites = state.filteredItems;

    return RefreshIndicator(
      color: _kBlue,
      onRefresh: () async {
        context.read<MomBloc>().add(const LoadMomBySite(isRefresh: true));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Title & Subtitle ───────────────────────────────────────────────
          Text(
            'MOM & Email',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Governance visits — send pending MOM, review completed MOM',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: _kSlate,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),

          // ── Top 2 Metric Cards (Pending MOM & Completed MOM) ───────────────
          Row(
            children: [
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Pending MOM',
                  count: state.pendingCount,
                  subtitle: 'Checklist done · MOM not sent',
                  countColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: state.selectedTabIndex == 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFFDE68A),
                  isSelected: state.selectedTabIndex == 0,
                  icon: Icons.hourglass_top_rounded,
                  onTap: () {
                    context.read<MomBloc>().add(const ChangeMomTab(0));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Completed MOM',
                  count: state.completedCount,
                  subtitle: 'MOM sent · activity completed',
                  countColor: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: state.selectedTabIndex == 1
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFBBF7D0),
                  isSelected: state.selectedTabIndex == 1,
                  icon: Icons.check_circle_rounded,
                  onTap: () {
                    context.read<MomBloc>().add(const ChangeMomTab(1));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Search & Filter Input ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<MomBloc>().add(SearchMomQueryChanged(val));
              },
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.secondary,
              ),
              decoration: InputDecoration(
                hintText: 'Search site, code, cluster, or zone...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _kSlate.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _kSlate,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: _kSlate,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<MomBloc>()
                              .add(const SearchMomQueryChanged(''));
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Sites List or Empty State ──────────────────────────────────────
          if (filteredSites.isEmpty)
            _buildEmptyState(state)
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Text(
                    '${filteredSites.length} ${filteredSites.length == 1 ? 'Site' : 'Sites'} Found',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSlate,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    state.selectedTabIndex == 0
                        ? 'Pending Actions'
                        : 'Completed Reviews',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: state.selectedTabIndex == 0 ? _kAmber : _kGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final site in filteredSites)
              _MomSiteCard(
                site: site,
                isPendingTab: state.selectedTabIndex == 0,
                onTap: () => _showSiteDetailsBottomSheet(context, site),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState(MomLoaded state) {
    final isSearchActive = state.searchQuery.isNotEmpty;
    final isPendingTab = state.selectedTabIndex == 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (isPendingTab ? _kAmber : _kGreen).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearchActive
                  ? Icons.search_off_rounded
                  : (isPendingTab
                      ? Icons.done_all_rounded
                      : Icons.inbox_outlined),
              color: isPendingTab ? _kAmber : _kGreen,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearchActive
                ? 'No matching sites found'
                : (isPendingTab ? 'All Caught Up!' : 'No Completed MOMs Yet'),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearchActive
                ? 'Try adjusting your search keywords or clear the filter.'
                : (isPendingTab
                    ? 'No pending MOM emails require action right now.'
                    : 'Completed governance MOMs will appear here once finalized.'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: _kSlate,
              height: 1.4,
            ),
          ),
          if (isSearchActive) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                context.read<MomBloc>().add(const SearchMomQueryChanged(''));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Clear Search',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSlate,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSiteDetailsBottomSheet(
    BuildContext context,
    MomSiteItemModel site,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle
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

                // Site Name & Status Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: _kBlue,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.siteName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            site.siteCode,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _kSlate,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: site.isLive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        site.siteStatus,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: site.isLive
                              ? const Color(0xFF15803D)
                              : _kSlate,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Info Grid
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'Cluster',
                        value: site.clusterName.isNotEmpty
                            ? site.clusterName
                            : 'N/A',
                        icon: Icons.hub_outlined,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Zone',
                        value: site.zoneName.isNotEmpty
                            ? site.zoneName
                            : 'N/A',
                        icon: Icons.public_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'City',
                        value: site.siteCity.isNotEmpty
                            ? site.siteCity
                            : 'N/A',
                        icon: Icons.location_city_rounded,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Client Type',
                        value: 'Type ${site.siteClientType}',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // MOM Status Breakdown
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCol(
                        label: 'Pending MOM',
                        value: '${site.pending}',
                        color: const Color(0xFFD97706),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      _StatCol(
                        label: 'Completed MOM',
                        value: '${site.completed}',
                        color: const Color(0xFF16A34A),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      _StatCol(
                        label: 'Total Visits',
                        value: '${site.total}',
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Button
                if (site.pending > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Sending MOM email workflow for ${site.siteName}...',
                              style: GoogleFonts.outfit(),
                            ),
                            backgroundColor: _kBlue,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        'Send Pending MOM (${site.pending})',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        'Review Completed MOM',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Metric Card Component
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryMetricCard extends StatelessWidget {
  final String title;
  final int count;
  final String subtitle;
  final Color countColor;
  final Color bgColor;
  final Color borderColor;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryMetricCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.countColor,
    required this.bgColor,
    required this.borderColor,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: countColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: countColor, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: countColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: _kSlate.withValues(alpha: 0.8),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill Tab Bar
// ─────────────────────────────────────────────────────────────────────────────



// ─────────────────────────────────────────────────────────────────────────────
// Individual Site Card Component
// ─────────────────────────────────────────────────────────────────────────────

class _MomSiteCard extends StatelessWidget {
  final MomSiteItemModel site;
  final bool isPendingTab;
  final VoidCallback onTap;

  const _MomSiteCard({
    required this.site,
    required this.isPendingTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = isPendingTab ? site.pending : site.completed;
    final accentColor = isPendingTab ? _kAmber : _kGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Site Icon Box
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: _kSlate,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Site Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.siteName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        site.formattedSubtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: _kSlate,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Meta Chips Row
                      Row(
                        children: [
                          if (site.clusterName.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.hub_outlined,
                                    size: 10,
                                    color: _kSlate,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    site.clusterName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: _kSlate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Client ${site.siteClientType}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Badge & Arrow
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers for Modal Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kSlate),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: _kSlate,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
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
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCol({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _kSlate,
          ),
        ),
      ],
    );
  }
}

