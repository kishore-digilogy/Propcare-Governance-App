import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/activity_site_summary_model.dart';
import '../../data/models/site_activity_item_model.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';

class SiteActivitiesDetailView extends StatefulWidget {
  final ActivitySiteItemModel site;
  final SiteActivitiesResponseModel? response;
  final bool isLoading;
  final String myRoleLabel;
  final VoidCallback onBack;
  final ActivitiesBloc bloc;

  const SiteActivitiesDetailView({
    super.key,
    required this.site,
    required this.response,
    required this.isLoading,
    required this.myRoleLabel,
    required this.onBack,
    required this.bloc,
  });

  @override
  State<SiteActivitiesDetailView> createState() => _SiteActivitiesDetailViewState();
}

class _SiteActivitiesDetailViewState extends State<SiteActivitiesDetailView> {
  bool _isTableView = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.response?.items ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 20,
            vertical: isNarrow ? 14 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Link
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'All sites',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Site Title & Subtitle
              Text(
                widget.site.siteName,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.myRoleLabel.isNotEmpty ? widget.myRoleLabel : "CRRM / Super Admin"} · ${widget.site.siteCity.isNotEmpty ? widget.site.siteCity : "NA"}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),

              // 4 Status Summary Cards (compact 2x2 on mobile, saves ~300px!)
              _buildSummaryCards(context),

              const SizedBox(height: 20),

              // Activities Section Header with View Mode Toggle
              _buildActivitiesSectionHeader(items.length),

              const SizedBox(height: 12),

              // Body: Loading, Empty, Card View, or Table View
              if (widget.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (items.isEmpty)
                _buildEmptyState()
              else if (_isTableView)
                _buildActivitiesTable(context, items)
              else
                _buildActivitiesCardView(items),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final counts = widget.response?.counts ??
        const SiteActivityCountsModel(
          today: 0,
          upcoming: 0,
          pending: 0,
          overdue: 0,
          all: 0,
          scheduled: 0,
          assigned: 0,
          completed: 0,
          summaryOverdue: 0,
        );

    final scheduledVal = counts.scheduled > 0 ? counts.scheduled : (counts.today + counts.upcoming);
    final assignedVal = counts.assigned;
    final completedVal = counts.completed;
    final overdueVal = counts.summaryOverdue > 0 ? counts.summaryOverdue : counts.overdue;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        final cardScheduled = _buildCountCard(
          title: 'Scheduled',
          count: scheduledVal,
          subtitle: 'Due today / upcoming',
          icon: Icons.calendar_month_outlined,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFEF3C7),
          bgTint: const Color(0xFFFFFDF5),
          borderColor: const Color(0xFFFDE68A),
          isCompact: isNarrow,
        );

        final cardAssigned = _buildCountCard(
          title: 'Assigned',
          count: assignedVal,
          subtitle: 'SPOC named · open',
          icon: Icons.person_outline_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFDBEAFE),
          bgTint: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFBFDBFE),
          isCompact: isNarrow,
        );

        final cardCompleted = _buildCountCard(
          title: 'Completed',
          count: completedVal,
          subtitle: 'MOM sent · closed',
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          bgTint: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          isCompact: isNarrow,
        );

        final cardOverdue = _buildCountCard(
          title: 'Overdue',
          count: overdueVal,
          subtitle: 'Past due date',
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
          bgTint: overdueVal > 0 ? const Color(0xFFFEF2F2) : Colors.white,
          borderColor: overdueVal > 0 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          isAlert: overdueVal > 0,
          isCompact: isNarrow,
        );

        // Compact 2x2 grid on mobile/narrow screens to save vertical space
        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardScheduled),
                  const SizedBox(width: 8),
                  Expanded(child: cardAssigned),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: cardCompleted),
                  const SizedBox(width: 8),
                  Expanded(child: cardOverdue),
                ],
              ),
            ],
          );
        }

        // Full row on desktop
        return Row(
          children: [
            Expanded(child: cardScheduled),
            const SizedBox(width: 12),
            Expanded(child: cardAssigned),
            const SizedBox(width: 12),
            Expanded(child: cardCompleted),
            const SizedBox(width: 12),
            Expanded(child: cardOverdue),
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
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Activities ($count)',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Trendy Card / Table View Toggle
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewToggleButton(
                icon: Icons.view_agenda_rounded,
                label: 'Cards',
                isSelected: !_isTableView,
                onTap: () {
                  if (_isTableView) setState(() => _isTableView = false);
                },
              ),
              _buildViewToggleButton(
                icon: Icons.table_chart_rounded,
                label: 'Table',
                isSelected: _isTableView,
                onTap: () {
                  if (!_isTableView) setState(() => _isTableView = true);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 3,
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
              size: 13,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_note_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No activities found for this site',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scheduled governance visits will appear here.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesCardView(List<SiteActivityItemModel> items) {
    return Column(
      children: items.map((activity) => _buildActivityCard(activity)).toList(),
    );
  }

  Widget _buildActivityCard(SiteActivityItemModel activity) {
    return InkWell(
      onTap: () => widget.bloc.add(SelectActivityForDetail(activity.id)),
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
                fontSize: 14.5,
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
                          '${activity.siteName.isNotEmpty ? activity.siteName : widget.site.siteName} · ${activity.siteCity.isNotEmpty ? activity.siteCity : widget.site.siteCity}',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      activity.code,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
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
            constraints: const BoxConstraints(minWidth: 700),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingRowHeight: 44,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columnSpacing: 32,
              horizontalMargin: 20,
              columns: [
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
                    'Date',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
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
              ],
              rows: items.map((activity) {
                return DataRow(
                  onSelectChanged: (_) {
                    widget.bloc.add(SelectActivityForDetail(activity.id));
                  },
                  cells: [
                    DataCell(_buildStatusPill(activity.status, activity.statusLabel)),
                    DataCell(
                      Text(
                        activity.formattedDate,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            activity.siteName.isNotEmpty ? activity.siteName : widget.site.siteName,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            activity.siteCity.isNotEmpty ? activity.siteCity : widget.site.siteCity,
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
                        activity.title.isNotEmpty
                            ? activity.title
                            : '${activity.roleLabel.isNotEmpty ? activity.roleLabel : "CRRM"} Visit',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
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
      default:
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFE2E8F0);
        text = const Color(0xFF64748B);
        dot = const Color(0xFF94A3B8);
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
              fontWeight: FontWeight.w500,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
