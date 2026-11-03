import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_top_header.dart';
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
const _kBorder = Color(0xFFE2E8F0);

class IssuesPage extends StatelessWidget {
  final IssuesBloc? bloc;

  const IssuesPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: const _IssuesView(),
      );
    }

    return BlocProvider(
      create: (_) => IssuesBloc(
        dataSource: IssuesRemoteDataSourceImpl(),
      )..add(const LoadIssues()),
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
          final prevMsg = previous is IssuesLoaded ? previous.feedbackMessage : null;
          final prevErr = previous is IssuesLoaded ? previous.errorMessage : null;
          return (current.feedbackMessage != null && current.feedbackMessage != prevMsg) ||
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final isMobile = MediaQuery.sizeOf(context).width < 720;
        final showBottomNav =
            isMobile && state is IssuesLoaded && state.selectedIssueDetail == null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          bottomNavigationBar:
              showBottomNav ? _buildBottomFilterNav(context, state) : null,
          body: SafeArea(
            child: Column(
              children: [
                // Standard App Top Header
                const AppTopHeader(),

                // Main Content Area
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is IssuesLoading || state is IssuesInitial) {
                        return const Center(
                          child: CircularProgressIndicator(color: _kBlue),
                        );
                      }

                      if (state is IssuesError) {
                        return _buildErrorView(context, state.message);
                      }

                      if (state is IssuesLoaded) {
                        // If issue detail is open, show Detail View (Image 1)
                        if (state.selectedIssueDetail != null) {
                          return IssueDetailView(state: state);
                        }
                        // Otherwise show Issues List (Image 2)
                        return _buildIssuesList(context, state);
                      }

                      return const SizedBox.shrink();
                    },
                  ),
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
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to load issues',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
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
                context.read<IssuesBloc>().add(const LoadIssues(isRefresh: true));
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesList(BuildContext context, IssuesLoaded state) {
    final meta = MetaService.instance.meta;
    final items = state.filteredItems;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
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
                    const Icon(Icons.arrow_back_rounded, size: 16, color: _kBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Back',
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
          ),
          const SizedBox(height: 8),

          // ── Title & Record Issue Button (Matches Image 2) ──────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 480;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Issues',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Only issues inside your allocated zone and clusters.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _kSlate,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        RecordIssueDialog.show(
                          context,
                          onSave: (payload) {
                            context.read<IssuesBloc>().add(CreateIssueSubmitted(payload));
                          },
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        'Record issue',
                        style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Issues',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Only issues inside your allocated zone and clusters.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _kSlate,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // + Record issue Button (Blue primary, omit export options as requested)
                  ElevatedButton.icon(
                    onPressed: () {
                      RecordIssueDialog.show(
                        context,
                        onSave: (payload) {
                          context.read<IssuesBloc>().add(CreateIssueSubmitted(payload));
                        },
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'Record issue',
                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Active Filters on Mobile / 4 Dropdowns on Desktop ──────────────
          if (isMobile) ...[
            if (activeCount > 0)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (state.selectedZoneId != null)
                      _buildRemovableFilterChip(
                        label: 'Zone: ${meta.getZoneName(state.selectedZoneId)}',
                        onRemove: () => context.read<IssuesBloc>().add(const FilterZoneChanged(null)),
                      ),
                    if (state.selectedClusterId != null)
                      _buildRemovableFilterChip(
                        label: 'Cluster: ${meta.getClusterName(state.selectedClusterId)}',
                        onRemove: () => context.read<IssuesBloc>().add(const FilterClusterChanged(null)),
                      ),
                    if (state.selectedSiteId != null)
                      _buildRemovableFilterChip(
                        label: 'Site: ${meta.getSiteName(state.selectedSiteId!)}',
                        onRemove: () => context.read<IssuesBloc>().add(const FilterSiteChanged(null)),
                      ),
                    if (state.selectedStatus != null)
                      _buildRemovableFilterChip(
                        label: 'Status: ${state.selectedStatus}',
                        onRemove: () => context.read<IssuesBloc>().add(const FilterStatusChanged(null)),
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
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Builder(
              builder: (context) {
                final availableSites = state.selectedClusterId != null
                    ? meta.sitesForCluster(state.selectedClusterId)
                    : (state.selectedZoneId != null
                        ? meta.sitesForZone(state.selectedZoneId)
                        : meta.liveSites);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Zone Filter
                      _buildFilterChip(
                        label: 'Zone',
                        selectedValue: state.selectedZoneId,
                        options: [
                          (value: null, label: 'All Zones'),
                          ...meta.zones.map((z) => (value: z.id, label: z.name)),
                        ],
                        onSelected: (val) {
                          context.read<IssuesBloc>().add(FilterZoneChanged(val));
                        },
                      ),
                      const SizedBox(width: 8),

                      // Cluster Filter
                      _buildFilterChip(
                        label: 'Cluster',
                        selectedValue: state.selectedClusterId,
                        options: [
                          (value: null, label: 'All Clusters'),
                          ...meta
                              .clustersForZone(state.selectedZoneId)
                              .map((c) => (value: c.id, label: c.name)),
                        ],
                        onSelected: (val) {
                          context.read<IssuesBloc>().add(FilterClusterChanged(val));
                        },
                      ),
                      const SizedBox(width: 8),

                      // Site Filter (Live sites only)
                      _buildFilterChip(
                        label: 'Site',
                        selectedValue: state.selectedSiteId,
                        options: [
                          (value: null, label: 'All Sites'),
                          ...availableSites.map((s) => (value: s.id, label: s.displayName)),
                        ],
                        onSelected: (val) {
                          context.read<IssuesBloc>().add(FilterSiteChanged(val));
                        },
                      ),
                      const SizedBox(width: 8),

                      // Status Filter
                      _buildFilterChip(
                        label: 'Status',
                        selectedValue: state.selectedStatus,
                        options: const [
                          (value: null, label: 'All Statuses'),
                          (value: 'OPEN', label: 'Open'),
                          (value: 'IN_PROGRESS', label: 'In Progress'),
                          (value: 'RESOLVED', label: 'Resolved'),
                          (value: 'CLOSED', label: 'Closed'),
                        ],
                        onSelected: (val) {
                          context.read<IssuesBloc>().add(FilterStatusChanged(val));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
          ],

          // ── Search Bar ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<IssuesBloc>().add(SearchIssuesQueryChanged(val));
              },
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.secondary),
              decoration: InputDecoration(
                hintText: 'Search issue title, description, or priority...',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: _kSlate.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSlate, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: _kSlate),
                        onPressed: () {
                          _searchController.clear();
                          context.read<IssuesBloc>().add(const SearchIssuesQueryChanged(''));
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Table Container (Matches Image 2) ──────────────────────────────
          Container(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 540;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scope Summary Header: "1 Issue In Your Scope"
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Text(
                        '${state.data.total} ${state.data.total == 1 ? 'Issue' : 'Issues'} In Your Scope',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _kSlate,
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: _kBorder),

                    // Table Header Row (shown only on wider screens)
                    if (!isCompact) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Issue',
                                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: _kSlate),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Site',
                                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: _kSlate),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Status',
                                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: _kSlate),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Due',
                                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: _kSlate),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _kBorder),
                    ],

                    // Table Items
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
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
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
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
                      )
                    else
                      for (int i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildIssueRow(context, items[i], meta, isCompact: isCompact),
                      ],

                    // Pagination Bar Footer: Only shown if totalCount > 10
                    if (state.totalCount > 10) ...[
                      const Divider(height: 1, color: _kBorder),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                      context.read<IssuesBloc>().add(ChangeIssuesPage(state.currentPage - 1));
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              iconSize: 20,
                              visualDensity: VisualDensity.compact,
                              color: state.currentPage < state.totalPages ? _kBlue : const Color(0xFFCBD5E1),
                              onPressed: state.currentPage < state.totalPages
                                  ? () {
                                      context.read<IssuesBloc>().add(ChangeIssuesPage(state.currentPage + 1));
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required List<({String? value, String label})> options,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    return IntrinsicWidth(
      child: CustomDropdownButton2<String?>(
        selectedValue: selectedValue,
        buttonHeight: 34,
        maxHeight: 260,
        enableSearch: options.length > 5,
        options: options
            .map((o) => DropdownItemOption<String?>(
                  value: o.value,
                  label: o.label,
                ))
            .toList(),
        onSelect: onSelected,
      ),
    );
  }

  Widget _buildIssueRow(
    BuildContext context,
    IssueModel issue,
    MetaDataModel meta, {
    bool isCompact = false,
  }) {
    final siteName = meta.getSiteName(issue.siteId);

    if (isCompact) {
      return InkWell(
        onTap: () {
          context.read<IssuesBloc>().add(OpenIssueDetail(issue.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      issue.title,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _kBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      issue.formattedStatus,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                issue.subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: _kSlate,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: _kSlate),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      siteName,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_outlined, size: 13, color: _kSlate),
                  const SizedBox(width: 4),
                  Text(
                    issue.formattedDueDate,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: _kSlate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        context.read<IssuesBloc>().add(OpenIssueDetail(issue.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Issue Title (Blue clickable link like Image 2) + Subtitle
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    issue.title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kBlue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    issue.subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: _kSlate,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Site Name
            Expanded(
              flex: 3,
              child: Text(
                siteName,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Status Badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    issue.formattedStatus,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kBlue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Due Date
            Expanded(
              flex: 2,
              child: Text(
                issue.formattedDueDate,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav & New Design Filters ────────────────────────────────────────

  int _activeFiltersCount(IssuesLoaded state) {
    int count = 0;
    if (state.selectedZoneId != null && state.selectedZoneId!.isNotEmpty) count++;
    if (state.selectedClusterId != null && state.selectedClusterId!.isNotEmpty) count++;
    if (state.selectedSiteId != null && state.selectedSiteId!.isNotEmpty) count++;
    if (state.selectedStatus != null && state.selectedStatus!.isNotEmpty) count++;
    return count;
  }

  Widget _buildBottomFilterNav(BuildContext context, IssuesLoaded state) {
    final meta = MetaService.instance.meta;
    final activeCount = _activeFiltersCount(state);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // ── Filter Button (Opens Bottom Sheet) ──
              InkWell(
                onTap: () => _openFilterBottomSheet(context, state, meta),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: activeCount > 0 ? _kBlue : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeCount > 0 ? _kBlue : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 17,
                        color: activeCount > 0 ? Colors.white : const Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filters',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: activeCount > 0 ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeCount',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _kBlue,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Container(
                width: 1,
                height: 26,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 10),

              // ── Quick Status Pills ──
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickStatusTab(
                        context: context,
                        label: 'All',
                        isSelected: state.selectedStatus == null || state.selectedStatus!.isEmpty,
                        onTap: () => context.read<IssuesBloc>().add(const FilterStatusChanged(null)),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickStatusTab(
                        context: context,
                        label: 'Open',
                        isSelected: state.selectedStatus == 'OPEN',
                        dotColor: const Color(0xFFD97706),
                        onTap: () => context.read<IssuesBloc>().add(const FilterStatusChanged('OPEN')),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickStatusTab(
                        context: context,
                        label: 'In Progress',
                        isSelected: state.selectedStatus == 'IN_PROGRESS',
                        dotColor: const Color(0xFF2563EB),
                        onTap: () => context.read<IssuesBloc>().add(const FilterStatusChanged('IN_PROGRESS')),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickStatusTab(
                        context: context,
                        label: 'Resolved',
                        isSelected: state.selectedStatus == 'RESOLVED',
                        dotColor: const Color(0xFF16A34A),
                        onTap: () => context.read<IssuesBloc>().add(const FilterStatusChanged('RESOLVED')),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickStatusTab(
                        context: context,
                        label: 'Closed',
                        isSelected: state.selectedStatus == 'CLOSED',
                        dotColor: const Color(0xFF64748B),
                        onTap: () => context.read<IssuesBloc>().add(const FilterStatusChanged('CLOSED')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatusTab({
    required BuildContext context,
    required String label,
    required bool isSelected,
    Color? dotColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
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
                color: isSelected ? Colors.white : const Color(0xFF475569),
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
              if (bottomSheetState is! IssuesLoaded) return const SizedBox.shrink();
              final currentActiveCount = _activeFiltersCount(bottomSheetState);
              final dynamicClusters = meta.clustersForZone(bottomSheetState.selectedZoneId);
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
                            const Icon(Icons.tune_rounded, size: 20, color: _kBlue),
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                              final bloc = bottomSheetContext.read<IssuesBloc>();
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
                                const DropdownItemOption(value: null, label: 'All Zones'),
                                ...meta.zones.map((z) => DropdownItemOption(value: z.id, label: z.name)),
                              ],
                              onSelect: (val) {
                                bottomSheetContext.read<IssuesBloc>().add(FilterZoneChanged(val));
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
                                const DropdownItemOption(value: null, label: 'All Clusters'),
                                ...dynamicClusters.map((c) => DropdownItemOption(value: c.id, label: c.name)),
                              ],
                              onSelect: (val) {
                                bottomSheetContext.read<IssuesBloc>().add(FilterClusterChanged(val));
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
                                const DropdownItemOption(value: null, label: 'All Sites'),
                                ...dynamicSites.map((s) => DropdownItemOption(value: s.id, label: s.displayName)),
                              ],
                              onSelect: (val) {
                                bottomSheetContext.read<IssuesBloc>().add(FilterSiteChanged(val));
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply Filters (${bottomSheetState.filteredItems.length} issues)',
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
    final isSelected = (value == null && (currentValue == null || currentValue.isEmpty)) ||
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
              ? (color != null ? color.withValues(alpha: 0.12) : const Color(0xFF0F172A))
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
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
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
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: _kBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

