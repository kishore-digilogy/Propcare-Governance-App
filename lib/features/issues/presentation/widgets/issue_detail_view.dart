import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/models/issue_model.dart';
import '../bloc/issues_bloc.dart';
import '../bloc/issues_event.dart';
import '../bloc/issues_state.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

const _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _kWeekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// Detail View for an Issue (Matches Screenshots 1, 2, 3 & 4)
class IssueDetailView extends StatefulWidget {
  final IssuesLoaded state;

  const IssueDetailView({super.key, required this.state});

  @override
  State<IssueDetailView> createState() => _IssueDetailViewState();
}

class _IssueDetailViewState extends State<IssueDetailView> {
  bool _isTableView = false;

  @override
  Widget build(BuildContext context) {
    final detail = widget.state.selectedIssueDetail;
    final meta = MetaService.instance.meta;

    if (widget.state.isDetailLoading || detail == null) {
      return const Center(
        child: CircularProgressIndicator(color: _kBlue),
      );
    }

    final issue = detail.issue;
    final actions = detail.actions;
    final siteName = meta.getSiteName(issue.siteId);
    final ownerName = meta.getUserName(issue.ownerId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── Top Row: <- Back & Actions ───────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 560;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          context.read<IssuesBloc>().add(const BackToIssuesList());
                        },
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () {
                              _showUpdateDialog(context, issue);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: Text(
                              'Update issue',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showAddActionDialog(context, issue);
                            },
                            icon: const Icon(Icons.add_rounded, size: 15),
                            label: Text(
                              'Add action point',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    context.read<IssuesBloc>().add(const BackToIssuesList());
                  },
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
                // Status Pill + Action Buttons
                Row(
                  children: [
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
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
                    const SizedBox(width: 8),
                    // Update Issue Button
                    SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () {
                          _showUpdateDialog(context, issue);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text(
                          'Update issue',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add Action Point Button
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showAddActionDialog(context, issue);
                        },
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: Text(
                          'Add action point',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // ── Title & Subtitle ─────────────────────────────────────────────────
        Text(
          issue.title,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${issue.formattedDepartment} · ${issue.formattedPriority} priority',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: _kSlate,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),

        // ── Card 1: Issue Details (Screenshot 4) ─────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Issue Details',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: _kBorder),
              const SizedBox(height: 14),

              // Metadata Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 540;
                  if (isNarrow) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildMetaCol(
                                label: 'Site',
                                value: siteName,
                                isLink: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetaCol(
                                label: 'Owner',
                                value: ownerName,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildMetaCol(
                                label: 'Due date',
                                value: issue.formattedDueDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetaCol(
                                label: 'Raised from',
                                value: issue.activityId != null
                                    ? 'Open governance activity'
                                    : (issue.origin ?? 'Manual'),
                                isLink: issue.activityId != null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildMetaCol(
                          label: 'Site',
                          value: siteName,
                          isLink: true,
                        ),
                      ),
                      Expanded(
                        child: _buildMetaCol(
                          label: 'Owner',
                          value: ownerName,
                        ),
                      ),
                      Expanded(
                        child: _buildMetaCol(
                          label: 'Due date',
                          value: issue.formattedDueDate,
                        ),
                      ),
                      Expanded(
                        child: _buildMetaCol(
                          label: 'Raised from',
                          value: issue.activityId != null
                              ? 'Open governance activity'
                              : (issue.origin ?? 'Manual'),
                          isLink: issue.activityId != null,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              // Description Section
              Text(
                'Description',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSlate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                issue.description.isNotEmpty ? issue.description : '—',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),

              // Resolution Section (Rendered when present, matching Screenshot 4)
              if (issue.resolution != null && issue.resolution!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Resolution',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.resolution!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Card 2: Action Points (Screenshot 4) ─────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${actions.length} Action Points',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View mode toggle: Cards vs Table
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewToggleBtn(
                          icon: Icons.view_agenda_rounded,
                          label: 'Cards',
                          isActive: !_isTableView,
                          onTap: () => setState(() => _isTableView = false),
                        ),
                        _buildViewToggleBtn(
                          icon: Icons.table_chart_rounded,
                          label: 'Table',
                          isActive: _isTableView,
                          onTap: () => setState(() => _isTableView = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: _kBorder),
              const SizedBox(height: 14),

              if (actions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 32,
                          color: _kSlate.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No action points yet.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: _kSlate,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!_isTableView)
                // Card View (Trendy, Mobile-Friendly)
                Column(
                  children: [
                    for (final act in actions)
                      _buildActionPointCard(act, meta),
                  ],
                )
              else
                // Table View (Scrollable horizontally so columns never break or squish)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table Headers
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 180,
                                child: Text(
                                  'Action',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kSlate,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: Text(
                                  'Status',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kSlate,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'Owner',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kSlate,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Due',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kSlate,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: _kBorder),
                        for (final act in actions)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    act.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _kBlue,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildStatusPill(act.formattedStatus, act.status),
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    (act.ownerId != null &&
                                            act.ownerId!.isNotEmpty &&
                                            meta.getUserName(act.ownerId!) != 'Unassigned')
                                        ? meta.getUserName(act.ownerId!)
                                        : (act.owner != null && act.owner!.isNotEmpty ? act.owner! : '—'),
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF334155)),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    act.formattedDueDate,
                                    style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                                  ),
                                ),
                              ],
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

  Widget _buildActionPointCard(IssueActionModel act, MetaDataModel meta) {
    final ownerName = (act.ownerId != null &&
            act.ownerId!.isNotEmpty &&
            meta.getUserName(act.ownerId!) != 'Unassigned')
        ? meta.getUserName(act.ownerId!)
        : (act.owner != null && act.owner!.isNotEmpty ? act.owner! : 'Unassigned');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  act.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(act.formattedStatus, act.status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEDF2F7)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        ownerName,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    act.formattedDueDate,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String formattedStatus, String status) {
    Color badgeBg;
    Color badgeText;
    Color badgeBorder;

    switch (status.toUpperCase()) {
      case 'RESOLVED':
      case 'CLOSED':
        badgeBg = const Color(0xFFF0FDF4);
        badgeText = const Color(0xFF16A34A);
        badgeBorder = const Color(0xFFBBF7D0);
        break;
      case 'IN_PROGRESS':
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
        badgeBorder = const Color(0xFFFDE68A);
        break;
      default: // OPEN
        badgeBg = const Color(0xFFEFF6FF);
        badgeText = const Color(0xFF1D4ED8);
        badgeBorder = const Color(0xFFBFDBFE);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeBorder),
      ),
      child: Text(
        formattedStatus,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeText,
        ),
      ),
    );
  }

  Widget _buildViewToggleBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
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
              icon,
              size: 13,
              color: isActive ? _kBlue : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? _kBlue : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCol({
    required String label,
    required String value,
    bool isLink = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: _kSlate,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isLink ? _kBlue : const Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showUpdateDialog(BuildContext context, IssueModel issue) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<IssuesBloc>(),
        child: _UpdateIssueDialog(issue: issue),
      ),
    );
  }

  void _showAddActionDialog(BuildContext context, IssueModel issue) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<IssuesBloc>(),
        child: _AddActionPointDialog(issue: issue),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Update Issue Dialog (Screenshots 1 & 2)
// ─────────────────────────────────────────────────────────────────────────────

class _UpdateIssueDialog extends StatefulWidget {
  final IssueModel issue;

  const _UpdateIssueDialog({required this.issue});

  @override
  State<_UpdateIssueDialog> createState() => _UpdateIssueDialogState();
}

class _UpdateIssueDialogState extends State<_UpdateIssueDialog> {
  late String _selectedStatus;
  late final TextEditingController _resolutionController;
  String? _errorMessage;

  final List<Map<String, String>> _statusOptions = const [
    {'value': 'OPEN', 'label': 'Open'},
    {'value': 'IN_PROGRESS', 'label': 'In Progress'},
    {'value': 'RESOLVED', 'label': 'Resolved'},
    {'value': 'CLOSED', 'label': 'Closed'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.issue.status.toUpperCase();
    _resolutionController = TextEditingController(text: widget.issue.resolution ?? '');
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  void _onSave() {
    final resolution = _resolutionController.text.trim();
    final isResolvedOrClosed = _selectedStatus == 'RESOLVED' || _selectedStatus == 'CLOSED';

    if (isResolvedOrClosed && resolution.length < 5) {
      setState(() {
        _errorMessage = 'At least 5 characters required for Resolved or Closed.';
      });
      return;
    }

    final payload = <String, dynamic>{
      'status': _selectedStatus,
    };
    if (resolution.isNotEmpty) {
      payload['resolution'] = resolution;
    }

    context.read<IssuesBloc>().add(
          UpdateIssueSubmitted(
            issueId: widget.issue.id,
            payload: payload,
          ),
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dialogWidth = (media.size.width - 32).clamp(280.0, 480.0);
    final maxDialogHeight = (media.size.height - media.viewInsets.bottom - 48).clamp(240.0, 680.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close icon (Screenshots 1 & 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Issue Status',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: _kSlate),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Status label
                Text(
                  'Status',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),

                // Status Selector Menu
                CustomDropdownButton2<String>(
                  selectedValue: _selectedStatus,
                  options: _statusOptions
                      .map((opt) => DropdownItemOption<String>(
                            value: opt['value'],
                            label: opt['label']!,
                          ))
                      .toList(),
                  buttonHeight: 44,
                  maxHeight: 240,
                  onSelect: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                        _errorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Resolution / Update label
                Text(
                  'Resolution / Update',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),

                // Multiline TextField for Resolution
                TextField(
                  controller: _resolutionController,
                  minLines: 4,
                  maxLines: 6,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Helper text (Screenshots 1 & 2)
                Text(
                  'At least 5 characters for Resolved or Closed. Finish all outstanding actions first.',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: _errorMessage != null ? Colors.red.shade600 : _kSlate,
                    fontWeight: _errorMessage != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons: Cancel & Save changes
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save changes',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
// Add Action Point Dialog (Screenshot 3)
// ─────────────────────────────────────────────────────────────────────────────

class _AddActionPointDialog extends StatefulWidget {
  final IssueModel issue;

  const _AddActionPointDialog({required this.issue});

  @override
  State<_AddActionPointDialog> createState() => _AddActionPointDialogState();
}

class _AddActionPointDialogState extends State<_AddActionPointDialog> {
  final _titleController = TextEditingController();
  String? _selectedOwnerId;
  DateTime? _selectedDueDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default owner to issue's owner or first user
    final users = MetaService.instance.meta.users;
    if (users.any((u) => u.id == widget.issue.ownerId)) {
      _selectedOwnerId = widget.issue.ownerId;
    } else if (users.isNotEmpty) {
      _selectedOwnerId = users.first.id;
    }
    // Default due date to today
    _selectedDueDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _kBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter an action point title.');
      return;
    }

    if (_selectedOwnerId == null || _selectedOwnerId!.isEmpty) {
      setState(() => _errorMessage = 'Please select an owner.');
      return;
    }

    final dueDateStr = _selectedDueDate != null
        ? '${_selectedDueDate!.year.toString().padLeft(4, '0')}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}'
        : widget.issue.dueDate;

    context.read<IssuesBloc>().add(
          AddActionPointSubmitted(
            issueId: widget.issue.id,
            payload: {
              'ownerId': _selectedOwnerId,
              'dueDate': dueDateStr,
              'title': title,
              'issueId': widget.issue.id,
            },
          ),
        );

    Navigator.of(context).pop();
  }

  String _formatDateDisplay(DateTime dt) {
    final month = _kMonths[dt.month - 1];
    final weekday = _kWeekdays[dt.weekday - 1];
    return '${dt.day} $month ${dt.year}  $weekday';
  }

  @override
  Widget build(BuildContext context) {
    final users = MetaService.instance.meta.users;
    final media = MediaQuery.of(context);
    final dialogWidth = (media.size.width - 32).clamp(280.0, 520.0);
    final maxDialogHeight = (media.size.height - media.viewInsets.bottom - 48).clamp(240.0, 680.0);
    final isNarrow = dialogWidth < 420;

    final pointField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Point',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );

    final ownerField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Owner',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        CustomDropdownButton2<String>(
          selectedValue: _selectedOwnerId,
          buttonHeight: 44,
          maxHeight: 260,
          enableSearch: true,
          searchHint: 'Search user or role...',
          options: users.map((u) {
            final roleDisplay = u.role.isNotEmpty ? ' · ${u.role}' : '';
            return DropdownItemOption<String>(
              value: u.id,
              label: '${u.name}$roleDisplay',
            );
          }).toList(),
          onSelect: (val) {
            if (val != null) {
              setState(() => _selectedOwnerId = val);
            }
          },
        ),
      ],
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close icon (Screenshot 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Action Point',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: _kSlate),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Row 1: Action Point & Owner side-by-side (Screenshot 3)
                if (isNarrow) ...[
                  pointField,
                  const SizedBox(height: 14),
                  ownerField,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: pointField),
                      const SizedBox(width: 14),
                      Expanded(child: ownerField),
                    ],
                  ),
                const SizedBox(height: 14),

            // TAT Due Date (Screenshot 3)
            Text(
              'TAT Due Date',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: _kBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDueDate != null
                            ? _formatDateDisplay(_selectedDueDate!)
                            : 'Select date...',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (_selectedDueDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedDueDate = null);
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: _kSlate,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 16),

            // Action Buttons: Cancel & Save changes (Screenshot 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save changes',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
