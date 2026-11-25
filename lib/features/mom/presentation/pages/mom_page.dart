import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_top_header.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../data/datasources/mom_remote_datasource.dart';
import '../../data/models/mom_activity_model.dart';
import '../../data/models/mom_by_site_model.dart';
import '../bloc/mom_bloc.dart';
import '../bloc/mom_event.dart';
import '../bloc/mom_state.dart';
import '../widgets/mom_activity_form_view.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kAmber = Color(0xFFD97706);
const _kGreen = Color(0xFF16A34A);
const _kDarkText = Color(0xFF0F172A);

/// MOM & Email page with full mobile-adaptive design, search, metric cards,
/// activities table (Image 9) and site activity MOM form views (Image 10).
class MomPage extends StatelessWidget {
  final MomBloc? bloc;
  const MomPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<MomBloc>.value(
        value: bloc!,
        child: const _MomView(),
      );
    }
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
    return BlocBuilder<MomBloc, MomState>(
      buildWhen: (prev, curr) {
        final prevSite = prev is MomLoaded ? prev.selectedSite : null;
        final currSite = curr is MomLoaded ? curr.selectedSite : null;
        final prevAct = prev is MomLoaded ? prev.selectedActivity : null;
        final currAct = curr is MomLoaded ? curr.selectedActivity : null;
        return prevSite != currSite || prevAct != currAct;
      },
      builder: (context, momState) {
        final canGoBackToSites =
            momState is MomLoaded && momState.selectedSite != null;

        return PopScope(
          canPop: !canGoBackToSites,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (canGoBackToSites) {
              context.read<MomBloc>().add(const BackToMomSitesList());
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Column(
                children: [
                  // PropCare Top Header
                  const AppTopHeader(),

                  // Main Content Area
                  Expanded(
                    child: BlocConsumer<MomBloc, MomState>(
                      listener: (context, state) {
                        if (state is MomLoaded) {
                          if (state.momSendSuccess && state.actionMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  state.actionMessage!,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } else if (state.actionError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  state.actionError!,
                                  style: GoogleFonts.outfit(),
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      builder: (context, state) {
                        if (state is MomLoading || state is MomInitial) {
                          return const ShimmerListLoading();
                        }

                        if (state is MomError) {
                          return _buildError(context, state.message);
                        }

                        if (state is MomLoaded) {
                          if (state.selectedSite != null) {
                            return _buildSiteActivitiesView(context, state);
                          }
                          return _buildActivitiesListView(context, state);
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                color: _kDarkText,
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

  // ─────────────────────────────────────────────────────────────────────────
  // Site Activities / Form View (When a site is selected - Image 10)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSiteActivitiesView(BuildContext context, MomLoaded state) {
    final site = state.selectedSite!;

    if (state.isSiteActivitiesLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _kBlue, strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text(
              'Loading MOM activities for ${site.siteName}...',
              style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
            ),
          ],
        ),
      );
    }

    final activities = state.siteActivities;
    final activeActivity = state.selectedActivity ?? activities.firstOrNull;

    if (activities.isEmpty || activeActivity == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Back breadcrumb
          InkWell(
            onTap: () {
              context.read<MomBloc>().add(const BackToMomSitesList());
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 16, color: _kBlue),
                  const SizedBox(width: 6),
                  Text(
                    'All sites',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            site.siteName,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: _kSlate,
                ),
                const SizedBox(height: 14),
                Text(
                  'No Activities Found',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kDarkText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No governance visits are available for ${site.siteName}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 12.5, color: _kSlate),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return MomActivityFormView(
      key: ValueKey('mom_activity_${activeActivity.id}'),
      site: site,
      activities: activities,
      activity: activeActivity,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main Activities List View (Matching Image 9)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActivitiesListView(BuildContext context, MomLoaded state) {
    final activities = state.filteredActivities;
    final hasActivities = activities.isNotEmpty;

    return RefreshIndicator(
      color: _kBlue,
      onRefresh: () async {
        context.read<MomBloc>().add(const LoadMomBySite(isRefresh: true));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 16,
              vertical: 16,
            ),
            children: [
              // ── Header: Title & Subtitle ──────────────────────────────────
              Text(
                'MOM & Email',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _kDarkText,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Send MOM Mail For Completed Governance Visits.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _kSlate,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),

              // ── 3 Metric Cards Row (All 4, Pending 0, Completed 4) ────────
              Row(
                children: [
                  // All (Blue)
                  Expanded(
                    child: _MetricCard(
                      title: 'All',
                      count: state.allCount,
                      icon: Icons.mail_outline_rounded,
                      activeColor: _kBlue,
                      bgColor: Colors.white,
                      borderColor: state.selectedTabIndex == 0
                          ? _kBlue
                          : const Color(0xFFE2E8F0),
                      isSelected: state.selectedTabIndex == 0,
                      onTap: () {
                        context.read<MomBloc>().add(const ChangeMomTab(0));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Pending (Amber)
                  Expanded(
                    child: _MetricCard(
                      title: 'Pending',
                      count: state.pendingCount,
                      icon: Icons.access_time_rounded,
                      activeColor: _kAmber,
                      bgColor: const Color(0xFFFFFBEB),
                      borderColor: state.selectedTabIndex == 1
                          ? _kAmber
                          : const Color(0xFFFDE68A),
                      isSelected: state.selectedTabIndex == 1,
                      onTap: () {
                        context.read<MomBloc>().add(const ChangeMomTab(1));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Completed (Green)
                  Expanded(
                    child: _MetricCard(
                      title: 'Completed',
                      count: state.completedCount,
                      icon: Icons.check_circle_outline_rounded,
                      activeColor: _kGreen,
                      bgColor: const Color(0xFFF0FDF4),
                      borderColor: state.selectedTabIndex == 2
                          ? _kGreen
                          : const Color(0xFFBBF7D0),
                      isSelected: state.selectedTabIndex == 2,
                      onTap: () {
                        context.read<MomBloc>().add(const ChangeMomTab(2));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Search Input ──────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    color: _kDarkText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search site, activity, cluster or zone...',
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
              const SizedBox(height: 18),

              // ── Activities Table / Mobile Cards / Sites Fallback ───────────
              if (hasActivities)
                (isWide
                    ? _buildDesktopTable(context, activities)
                    : _buildMobileCards(context, activities))
              else if (state.filteredItems.isNotEmpty)
                _buildSitesList(context, state.filteredItems, isWide)
              else
                _buildEmptyState(state),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ── Sites Fallback View (when activities are grouped by site) ─────────────
  Widget _buildSitesList(
    BuildContext context,
    List<MomSiteItemModel> sites,
    bool isWide,
  ) {
    if (isWide) {
      return _buildSitesDesktopTable(context, sites);
    } else {
      return _buildSitesMobileCards(context, sites);
    }
  }

  Widget _buildSitesDesktopTable(
    BuildContext context,
    List<MomSiteItemModel> sites,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 980,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          'S.No',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: Text(
                          'Site',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: Text(
                          'Zone',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          'Cluster',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          'Visits Count',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 125,
                        child: Text(
                          'Status',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
                for (final entry in sites.asMap().entries) ...[
                  if (entry.key > 0)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  InkWell(
                    onTap: () {
                      context.read<MomBloc>().add(SelectMomSite(entry.value));
                    },
                    hoverColor: const Color(0xFFF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${entry.key + 1}',
                              style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.apartment_rounded, size: 15, color: _kSlate),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        entry.value.siteName.isNotEmpty ? entry.value.siteName : 'Site',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: _kDarkText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (entry.value.siteCode.isNotEmpty)
                                        Text(
                                          entry.value.siteCode,
                                          style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: Text(
                              entry.value.zoneName.isNotEmpty ? entry.value.zoneName : '—',
                              style: GoogleFonts.outfit(fontSize: 13, color: _kDarkText),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: Text(
                              entry.value.clusterName.isNotEmpty ? entry.value.clusterName : '—',
                              style: GoogleFonts.outfit(fontSize: 13, color: _kDarkText),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              '${entry.value.completed} / ${entry.value.total}',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _kDarkText),
                            ),
                          ),
                          SizedBox(
                            width: 125,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: entry.value.completed > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: entry.value.completed > 0 ? _kGreen : _kAmber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    entry.value.completed > 0 ? 'Completed' : 'Pending',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: entry.value.completed > 0 ? _kGreen : _kAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                            child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSitesMobileCards(
    BuildContext context,
    List<MomSiteItemModel> sites,
  ) {
    return Column(
      children: List.generate(sites.length, (index) {
        final site = sites[index];
        final isSent = site.completed > 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                context.read<MomBloc>().add(SelectMomSite(site));
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: _kSlate),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            site.siteName.isNotEmpty ? site.siteName : 'Site',
                            style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700, color: _kDarkText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSent ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSent ? _kGreen : _kAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSent ? 'Sent (${site.completed})' : 'Pending (${site.pending})',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSent ? _kGreen : _kAmber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: _kSlate),
                        const SizedBox(width: 4),
                        Text(
                          '${site.siteCode.isNotEmpty ? site.siteCode : ""} · ${site.zoneName.isNotEmpty ? site.zoneName : "NA"}',
                          style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _kBlue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Desktop / Tablet Table (Image 9) ──────────────────────────────────────
  Widget _buildDesktopTable(
    BuildContext context,
    List<MomActivityModel> activities,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 980,
            child: Column(
              children: [
            // Table Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      'S.No',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: Text(
                      'Site',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(
                      'Zone',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Cluster',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: Text(
                      'Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      'Frequency',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 125,
                    child: Text(
                      'Status',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30), // For chevron
                ],
              ),
            ),

            // Table Data Rows
            for (final entry in activities.asMap().entries) ...[
              if (entry.key > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
              Builder(
                builder: (context) {
                  final index = entry.key;
                  final act = entry.value;
                  final isSent = act.isSent;

                  return InkWell(
                    onTap: () {
                      context.read<MomBloc>().add(SelectMomActivityDirectly(act));
                    },
                    hoverColor: const Color(0xFFF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // S.No
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _kSlate,
                              ),
                            ),
                          ),

                          // Site: Building icon + Name
                          SizedBox(
                            width: 160,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.apartment_rounded,
                                    size: 15,
                                    color: _kSlate,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    act.siteName.isNotEmpty ? act.siteName : 'Site',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _kDarkText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Zone
                          SizedBox(
                            width: 150,
                            child: Text(
                              act.zoneName.isNotEmpty ? act.zoneName : '—',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _kDarkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Cluster
                          SizedBox(
                            width: 120,
                            child: Text(
                              act.clusterName.isNotEmpty ? act.clusterName : '—',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _kDarkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Activity
                          SizedBox(
                            width: 180,
                            child: Text(
                              act.title,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _kDarkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Frequency
                          SizedBox(
                            width: 110,
                            child: Text(
                              act.frequencyLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _kDarkText,
                              ),
                            ),
                          ),

                          // Status Pill
                          SizedBox(
                            width: 125,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSent
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isSent ? _kGreen : _kAmber,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isSent ? 'Sent' : 'Pending',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSent ? _kGreen : _kAmber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Chevron >
                          const SizedBox(
                            width: 30,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);
  }

  // ── Mobile Responsive Cards (Zero crash, Zero overflow, Clean UX) ──────────
  Widget _buildMobileCards(
    BuildContext context,
    List<MomActivityModel> activities,
  ) {
    return Column(
      children: List.generate(activities.length, (index) {
        final act = activities[index];
        final isSent = act.isSent;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                context.read<MomBloc>().add(SelectMomActivityDirectly(act));
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: S.No + Site Name + Status pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _kSlate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.apartment_rounded,
                          size: 16,
                          color: _kBlue,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            act.siteName.isNotEmpty ? act.siteName : 'Site',
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _kDarkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSent
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSent ? _kGreen : _kAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSent ? 'Sent' : 'Pending',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSent ? _kGreen : _kAmber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Activity Title
                    Text(
                      act.title,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _kDarkText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Meta chips row: Zone, Cluster, Frequency
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (act.zoneName.isNotEmpty)
                          _metaChip(act.zoneName, Icons.location_on_outlined),
                        if (act.clusterName.isNotEmpty)
                          _metaChip(act.clusterName, Icons.hub_outlined),
                        _metaChip(act.frequencyLabel, Icons.repeat_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _metaChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _kSlate),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _kDarkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(MomLoaded state) {
    final isSearchActive = state.searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: _kSlate,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearchActive
                ? 'No matching activities found'
                : 'No Activities in this view',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearchActive
                ? 'Try adjusting your search keywords.'
                : 'Governance visits will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12.5, color: _kSlate),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric Card Component (All 4, Pending 0, Completed 4)
// ─────────────────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color activeColor;
  final Color bgColor;
  final Color borderColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.activeColor,
    required this.bgColor,
    required this.borderColor,
    required this.isSelected,
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
            color: isSelected ? activeColor : borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? activeColor : _kSlate,
                  ),
                ),
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? activeColor : _kSlate.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isSelected ? activeColor : _kDarkText,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
