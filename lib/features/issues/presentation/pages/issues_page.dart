import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/app_top_header.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/datasources/issues_remote_datasource.dart';
import '../../data/models/issue_model.dart';
import '../bloc/issues_bloc.dart';
import '../bloc/issues_event.dart';
import '../bloc/issues_state.dart';
import '../widgets/issue_detail_view.dart';
import '../widgets/record_issue_dialog.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);

class IssuesPage extends StatelessWidget {
  final IssuesBloc? bloc;

  const IssuesPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(value: bloc!, child: const _IssuesView());
    }

    return BlocProvider(
      create: (_) =>
          IssuesBloc(dataSource: IssuesRemoteDataSourceImpl())
            ..add(const LoadIssues()),
      child: const _IssuesView(),
    );
  }
}

class _IssuesView extends StatefulWidget {
  const _IssuesView();

  @override
  State<_IssuesView> createState() => _IssuesViewState();
}

class _IssuesViewState extends State<_IssuesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IssuesBloc, IssuesState>(
      listenWhen: (previous, current) {
        if (current is IssuesLoaded) {
          final prevMsg = previous is IssuesLoaded
              ? previous.feedbackMessage
              : null;
          final prevErr = previous is IssuesLoaded
              ? previous.errorMessage
              : null;
          return (current.feedbackMessage != null &&
                  current.feedbackMessage != prevMsg) ||
              (current.errorMessage != null && current.errorMessage != prevErr);
        }
        return false;
      },
      listener: (context, state) {
        if (state is IssuesLoaded) {
          if (state.feedbackMessage != null) {
            final msg = state.feedbackMessage!;
            context.read<IssuesBloc>().add(const ClearIssueFeedback());
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  msg,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state.errorMessage != null) {
            final err = state.errorMessage!;
            context.read<IssuesBloc>().add(const ClearIssueFeedback());
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err, style: GoogleFonts.outfit()),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Stack(
              children: [
                // Top-right background decorative wave (light and airy, stays in corner)
                Positioned(
                  top: 0,
                  right: 0,
                  width: 160,
                  height: 95,
                  child: IgnorePointer(
                    child: CustomPaint(painter: _IssuesHeaderWavePainter()),
                  ),
                ),
                Column(
                  children: [
                    // Standard App Top Header
                    const AppTopHeader(),

                    // Main Content Area
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (state is IssuesLoading ||
                              state is IssuesInitial) {
                            return const ShimmerListLoading();
                          }

                          if (state is IssuesError) {
                            return _buildErrorView(context, state.message);
                          }

                          if (state is IssuesLoaded) {
                            // If issue detail is open, show Detail View
                            if (state.selectedIssueDetail != null) {
                              return IssueDetailView(state: state);
                            }
                            // Otherwise show Issues List
                            return _buildIssuesList(context, state);
                          }

                          return const SizedBox.shrink();
                        },
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

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load issues',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                context.read<IssuesBloc>().add(
                  const LoadIssues(isRefresh: true),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesList(BuildContext context, IssuesLoaded state) {
    final meta = MetaService.instance.meta;
    final items = state.filteredItems;
    final activeCount = _activeFiltersCount(state);

    return RefreshIndicator(
      color: _kBlue,
      onRefresh: () async {
        context.read<IssuesBloc>().add(const LoadIssues(isRefresh: true));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Back Button ──────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Title with Accent Bar ─────────────────────────────────────────
          Row(
            children: [
              Text(
                'Issues',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 3.5,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Only issues inside your allocated zone and clusters.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: _kSlate,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),

          // ── Action & Filter Row (Same Row: Record Issue + Filters + Status Tabs) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildRecordIssueButton(context),
                const SizedBox(width: 10),
                _buildFilterButton(context, state, meta),
                const SizedBox(width: 8),
                _buildQuickStatusTab(
                  context: context,
                  label: 'All',
                  isSelected:
                      state.selectedStatus == null ||
                      state.selectedStatus!.isEmpty,
                  onTap: () => context.read<IssuesBloc>().add(
                    const FilterStatusChanged(null),
                  ),
                ),
                const SizedBox(width: 6),
                _buildQuickStatusTab(
                  context: context,
                  label: 'Open',
                  isSelected: state.selectedStatus == 'OPEN',
                  dotColor: const Color(0xFFD97706),
                  onTap: () => context.read<IssuesBloc>().add(
                    const FilterStatusChanged('OPEN'),
                  ),
                ),
                const SizedBox(width: 6),
                _buildQuickStatusTab(
                  context: context,
                  label: 'In Progress',
                  isSelected: state.selectedStatus == 'IN_PROGRESS',
                  dotColor: const Color(0xFF2563EB),
                  onTap: () => context.read<IssuesBloc>().add(
                    const FilterStatusChanged('IN_PROGRESS'),
                  ),
                ),
                const SizedBox(width: 6),
                _buildQuickStatusTab(
                  context: context,
                  label: 'Resolved',
                  isSelected: state.selectedStatus == 'RESOLVED',
                  dotColor: const Color(0xFF16A34A),
                  onTap: () => context.read<IssuesBloc>().add(
                    const FilterStatusChanged('RESOLVED'),
                  ),
                ),
                const SizedBox(width: 6),
                _buildQuickStatusTab(
                  context: context,
                  label: 'Closed',
                  isSelected: state.selectedStatus == 'CLOSED',
                  dotColor: const Color(0xFF64748B),
                  onTap: () => context.read<IssuesBloc>().add(
                    const FilterStatusChanged('CLOSED'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Active Filters Chips (if any zone/cluster/site selected) ───────
          if (activeCount > 0) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (state.selectedZoneId != null)
                    _buildRemovableFilterChip(
                      label: 'Zone: ${meta.getZoneName(state.selectedZoneId)}',
                      onRemove: () => context.read<IssuesBloc>().add(
                        const FilterZoneChanged(null),
                      ),
                    ),
                  if (state.selectedClusterId != null)
                    _buildRemovableFilterChip(
                      label:
                          'Cluster: ${meta.getClusterName(state.selectedClusterId)}',
                      onRemove: () => context.read<IssuesBloc>().add(
                        const FilterClusterChanged(null),
                      ),
                    ),
                  if (state.selectedSiteId != null)
                    _buildRemovableFilterChip(
                      label: 'Site: ${meta.getSiteName(state.selectedSiteId!)}',
                      onRemove: () => context.read<IssuesBloc>().add(
                        const FilterSiteChanged(null),
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      final bloc = context.read<IssuesBloc>();
                      bloc.add(const FilterZoneChanged(null));
                      bloc.add(const FilterClusterChanged(null));
                      bloc.add(const FilterSiteChanged(null));
                      bloc.add(const FilterStatusChanged(null));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Search Bar ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<IssuesBloc>().add(SearchIssuesQueryChanged(val));
              },
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search issue title, description, or priority...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
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
                          context.read<IssuesBloc>().add(
                            const SearchIssuesQueryChanged(''),
                          );
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Scope Summary Banner ("7 Issues In Your Scope") ─────────────────
          _buildScopeBanner(state),
          const SizedBox(height: 14),

          // ── Issues Cards List (New Design Matching User Reference) ─────────
          if (items.isEmpty)
            _buildEmptyState()
          else
            for (int i = 0; i < items.length; i++)
              _buildIssueCard(context, items[i], meta, i),

          // ── Pagination Footer ──────────────────────────────────────────────
          if (state.totalCount > 10) _buildPaginationFooter(context, state),
        ],
      ),
    );
  }

  Widget _buildScopeBanner(IssuesLoaded state) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
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
              width: 130,
              height: 52,
              child: IgnorePointer(
                child: CustomPaint(painter: _ScopeBannerWavePainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 18,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${state.data.total} ${state.data.total == 1 ? 'Issue' : 'Issues'} In Your Scope',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
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

  Widget _buildRecordIssueButton(BuildContext context) {
    return InkWell(
      onTap: () {
        RecordIssueDialog.show(
          context,
          onSave: (payload) {
            context.read<IssuesBloc>().add(CreateIssueSubmitted(payload));
          },
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Record issue',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    IssuesLoaded state,
    MetaDataModel meta,
  ) {
    final activeCount = _activeFiltersCount(state);
    return InkWell(
      onTap: () => _openFilterBottomSheet(context, state, meta),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8.5),
        decoration: BoxDecoration(
          color: activeCount > 0 ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activeCount > 0
                ? const Color(0xFF3B82F6)
                : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: activeCount > 0
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              'Filters',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: activeCount > 0
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF334155),
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(
    BuildContext context,
    IssueModel issue,
    MetaDataModel meta,
    int index,
  ) {
    final siteName = meta.getSiteName(issue.siteId);
    final style = _getIssueStyle(issue, index);

    return InkWell(
      onTap: () {
        context.read<IssuesBloc>().add(OpenIssueDetail(issue.id));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Bottom-right corner wave tint
              Positioned(
                bottom: 0,
                right: 0,
                width: 120,
                height: 55,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _IssueCardCornerWavePainter(style.color),
                  ),
                ),
              ),
              // Left vertical colored edge accent
              Positioned(
                left: 0,
                top: 10,
                bottom: 10,
                width: 3.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: style.color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Squircle icon container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: style.bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: style.borderColor,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(style.icon, size: 20, color: style.color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  issue.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildCardStatusBadge(issue),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Source & Priority
                          Row(
                            children: [
                              Text(
                                'Manual',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  issue.priority.isNotEmpty
                                      ? issue.priority[0].toUpperCase() +
                                            issue.priority
                                                .substring(1)
                                                .toLowerCase()
                                      : 'Medium',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Location & Date
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13.5,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  siteName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 12.5,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                issue.formattedDueDate,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildCardStatusBadge(IssueModel issue) {
    final status = issue.status.toUpperCase();
    if (status == 'RESOLVED' || status == 'CLOSED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: Color(0xFF16A34A),
            ),
            const SizedBox(width: 4),
            Text(
              'Resolved',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'IN_PROGRESS') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_filled_rounded,
              size: 12,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 4),
            Text(
              'In Progress',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }

    // Default: OPEN
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.radio_button_checked_rounded,
            size: 12,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 4),
          Text(
            'Open',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, color: _kSlate, size: 36),
            const SizedBox(height: 10),
            Text(
              'No issues found',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting filters or search query',
              style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(BuildContext context, IssuesLoaded state) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            state.paginationLabel,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 14),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            color: state.currentPage > 1 ? _kBlue : const Color(0xFFCBD5E1),
            onPressed: state.currentPage > 1
                ? () {
                    context.read<IssuesBloc>().add(
                      ChangeIssuesPage(state.currentPage - 1),
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            color: state.currentPage < state.totalPages
                ? _kBlue
                : const Color(0xFFCBD5E1),
            onPressed: state.currentPage < state.totalPages
                ? () {
                    context.read<IssuesBloc>().add(
                      ChangeIssuesPage(state.currentPage + 1),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color, Color bgColor, Color borderColor})
  _getIssueStyle(IssueModel issue, int index) {
    final title = issue.title.toLowerCase();
    if (title.contains('plant') ||
        title.contains('flower') ||
        title.contains('garden')) {
      return (
        icon: Icons.eco_outlined,
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
      );
    }
    if (title.contains('mobile') ||
        title.contains('phone') ||
        title.contains('test')) {
      return (
        icon: Icons.smartphone_rounded,
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
        borderColor: const Color(0xFFBFDBFE),
      );
    }
    if (title.contains('odour') ||
        title.contains('smell') ||
        title.contains('air') ||
        title.contains('hvac')) {
      return (
        icon: Icons.air_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        borderColor: const Color(0xFFDDD6FE),
      );
    }
    if (title.contains('door') ||
        title.contains('glass') ||
        title.contains('window')) {
      return (
        icon: Icons.meeting_room_outlined,
        color: const Color(0xFF0D9488),
        bgColor: const Color(0xFFF0FDFA),
        borderColor: const Color(0xFF99F6E4),
      );
    }
    if (title.contains('desk') ||
        title.contains('table') ||
        title.contains('chair') ||
        title.contains('clean')) {
      return (
        icon: Icons.table_restaurant_outlined,
        color: const Color(0xFFEA580C),
        bgColor: const Color(0xFFFFF7ED),
        borderColor: const Color(0xFFFED7AA),
      );
    }

    // Palette fallback rotation
    const palette = [
      (
        icon: Icons.assignment_outlined,
        color: Color(0xFFD97706),
        bgColor: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
      ),
      (
        icon: Icons.build_outlined,
        color: Color(0xFF2563EB),
        bgColor: Color(0xFFEFF6FF),
        borderColor: Color(0xFFBFDBFE),
      ),
      (
        icon: Icons.lightbulb_outline_rounded,
        color: Color(0xFF7C3AED),
        bgColor: Color(0xFFF5F3FF),
        borderColor: Color(0xFFDDD6FE),
      ),
      (
        icon: Icons.shield_outlined,
        color: Color(0xFF0D9488),
        bgColor: Color(0xFFF0FDFA),
        borderColor: Color(0xFF99F6E4),
      ),
      (
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFEA580C),
        bgColor: Color(0xFFFFF7ED),
        borderColor: Color(0xFFFED7AA),
      ),
    ];
    return palette[index % palette.length];
  }

  int _activeFiltersCount(IssuesLoaded state) {
    int count = 0;
    if (state.selectedZoneId != null && state.selectedZoneId!.isNotEmpty)
      count++;
    if (state.selectedClusterId != null && state.selectedClusterId!.isNotEmpty)
      count++;
    if (state.selectedSiteId != null && state.selectedSiteId!.isNotEmpty)
      count++;
    if (state.selectedStatus != null && state.selectedStatus!.isNotEmpty)
      count++;
    return count;
  }

  Widget _buildQuickStatusTab({
    required BuildContext context,
    required String label,
    required bool isSelected,
    Color? dotColor,
    required VoidCallback onTap,
  }) {
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF475569);

    if (isSelected) {
      if (label == 'All') {
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFFB45309);
      } else if (label == 'Open') {
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFFB45309);
      } else if (label == 'In Progress') {
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF3B82F6);
        textColor = const Color(0xFF1D4ED8);
      } else if (label == 'Resolved') {
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFF22C55E);
        textColor = const Color(0xFF15803D);
      } else {
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFF64748B);
        textColor = const Color(0xFF334155);
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.3 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6.5,
                height: 6.5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterBottomSheet(
    BuildContext context,
    IssuesLoaded state,
    MetaDataModel meta,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<IssuesBloc>(),
          child: BlocBuilder<IssuesBloc, IssuesState>(
            builder: (bottomSheetContext, bottomSheetState) {
              if (bottomSheetState is! IssuesLoaded)
                return const SizedBox.shrink();
              final currentActiveCount = _activeFiltersCount(bottomSheetState);
              final dynamicClusters = meta.clustersForZone(
                bottomSheetState.selectedZoneId,
              );
              final dynamicSites = bottomSheetState.selectedClusterId != null
                  ? meta.sitesForCluster(bottomSheetState.selectedClusterId)
                  : (bottomSheetState.selectedZoneId != null
                        ? meta.sitesForZone(bottomSheetState.selectedZoneId)
                        : meta.liveSites);

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
                            const Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: _kBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Issues',
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
                                  color: _kBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
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
                        if (currentActiveCount > 0)
                          TextButton(
                            onPressed: () {
                              final bloc = bottomSheetContext
                                  .read<IssuesBloc>();
                              bloc.add(const FilterZoneChanged(null));
                              bloc.add(const FilterClusterChanged(null));
                              bloc.add(const FilterSiteChanged(null));
                              bloc.add(const FilterStatusChanged(null));
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Reset All',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),

                    // Content form
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Zone Dropdown ──
                            _buildSectionHeader('Zone'),
                            const SizedBox(height: 6),
                            CustomDropdownButton2<String?>(
                              selectedValue: bottomSheetState.selectedZoneId,
                              buttonHeight: 44,
                              placeholder: 'All Zones',
                              enableSearch: meta.zones.length > 5,
                              options: [
                                const DropdownItemOption(
                                  value: null,
                                  label: 'All Zones',
                                ),
                                ...meta.zones.map(
                                  (z) => DropdownItemOption(
                                    value: z.id,
                                    label: z.name,
                                  ),
                                ),
                              ],
                              onSelect: (val) {
                                bottomSheetContext.read<IssuesBloc>().add(
                                  FilterZoneChanged(val),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Cluster Dropdown (Dynamic for zone) ──
                            _buildSectionHeader('Cluster'),
                            const SizedBox(height: 6),
                            CustomDropdownButton2<String?>(
                              selectedValue: bottomSheetState.selectedClusterId,
                              buttonHeight: 44,
                              placeholder: 'All Clusters',
                              enableSearch: dynamicClusters.length > 5,
                              options: [
                                const DropdownItemOption(
                                  value: null,
                                  label: 'All Clusters',
                                ),
                                ...dynamicClusters.map(
                                  (c) => DropdownItemOption(
                                    value: c.id,
                                    label: c.name,
                                  ),
                                ),
                              ],
                              onSelect: (val) {
                                bottomSheetContext.read<IssuesBloc>().add(
                                  FilterClusterChanged(val),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Site Dropdown (Live Sites Only) ──
                            _buildSectionHeader('Site (Live Sites Only)'),
                            const SizedBox(height: 6),
                            CustomDropdownButton2<String?>(
                              selectedValue: bottomSheetState.selectedSiteId,
                              buttonHeight: 44,
                              placeholder: 'All Sites',
                              enableSearch: dynamicSites.length > 5,
                              options: [
                                const DropdownItemOption(
                                  value: null,
                                  label: 'All Sites',
                                ),
                                ...dynamicSites.map(
                                  (s) => DropdownItemOption(
                                    value: s.id,
                                    label: s.displayName,
                                  ),
                                ),
                              ],
                              onSelect: (val) {
                                bottomSheetContext.read<IssuesBloc>().add(
                                  FilterSiteChanged(val),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Status Filter ──
                            _buildSectionHeader('Issue Status'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatusOptionChip(
                                  context: bottomSheetContext,
                                  label: 'All Statuses',
                                  value: null,
                                  currentValue: bottomSheetState.selectedStatus,
                                ),
                                _buildStatusOptionChip(
                                  context: bottomSheetContext,
                                  label: 'Open',
                                  value: 'OPEN',
                                  currentValue: bottomSheetState.selectedStatus,
                                  color: const Color(0xFFD97706),
                                ),
                                _buildStatusOptionChip(
                                  context: bottomSheetContext,
                                  label: 'In Progress',
                                  value: 'IN_PROGRESS',
                                  currentValue: bottomSheetState.selectedStatus,
                                  color: const Color(0xFF2563EB),
                                ),
                                _buildStatusOptionChip(
                                  context: bottomSheetContext,
                                  label: 'Resolved',
                                  value: 'RESOLVED',
                                  currentValue: bottomSheetState.selectedStatus,
                                  color: const Color(0xFF16A34A),
                                ),
                                _buildStatusOptionChip(
                                  context: bottomSheetContext,
                                  label: 'Closed',
                                  value: 'CLOSED',
                                  currentValue: bottomSheetState.selectedStatus,
                                  color: const Color(0xFF64748B),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply Filters (${bottomSheetState.filteredItems.length} issues)',
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildStatusOptionChip({
    required BuildContext context,
    required String label,
    required String? value,
    required String? currentValue,
    Color? color,
  }) {
    final isSelected =
        (value == null && (currentValue == null || currentValue.isEmpty)) ||
        (value != null && currentValue == value);

    return InkWell(
      onTap: () {
        context.read<IssuesBloc>().add(FilterStatusChanged(value));
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color != null
                    ? color.withValues(alpha: 0.12)
                    : const Color(0xFF0F172A))
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (color ?? const Color(0xFF0F172A))
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (color ?? Colors.white)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovableFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _kBlue,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(10),
              child: const Icon(Icons.close_rounded, size: 14, color: _kBlue),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssuesHeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft light cream/gold wave
    final goldSoftPaint = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.15);
    path1.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.05,
      size.width,
      size.height * 0.45,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();
    canvas.drawPath(path1, goldSoftPaint);

    // 2. Light airy amber wave (translucent pastel)
    final goldRichPaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.25, size.height * 0.65);
    path2.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.25,
      size.width,
      size.height * 0.5,
    );
    path2.lineTo(size.width, 0);
    path2.lineTo(size.width * 0.5, 0);
    path2.close();
    canvas.drawPath(path2, goldRichPaint);

    // 3. Gentle pastel accent curve (light amber/orange, no heavy dark wedge)
    final accentPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(size.width * 0.45, size.height);
    path3.quadraticBezierTo(
      size.width * 0.72,
      size.height * 0.5,
      size.width,
      size.height * 0.7,
    );
    path3.lineTo(size.width, size.height);
    path3.close();
    canvas.drawPath(path3, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScopeBannerWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.2,
      size.width,
      0,
    );
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.3, size.height);
    path2.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.45,
      size.width,
      size.height * 0.25,
    );
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IssueCardCornerWavePainter extends CustomPainter {
  final Color baseColor;

  const _IssueCardCornerWavePainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = baseColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.3,
      size.width,
      0,
    );
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = baseColor.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.3, size.height);
    path2.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.5,
      size.width,
      size.height * 0.3,
    );
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _IssueCardCornerWavePainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}
