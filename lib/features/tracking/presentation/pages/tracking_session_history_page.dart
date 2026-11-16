import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/geo_address_text.dart';
import '../../data/models/attendance.dart';
import '../../data/models/day_story.dart';
import '../../services/tracking_controller.dart';
import 'session_route_map_page.dart';

enum HistoryDateFilter { today, yesterday, custom }

/// Dedicated Session & Attendance History Page.
/// Shows past check-ins, site visits, distance traveled, addresses,
/// multi-session support, and single-day date filtering defaulting to Today.
class TrackingSessionHistoryPage extends StatefulWidget {
  const TrackingSessionHistoryPage({super.key});

  @override
  State<TrackingSessionHistoryPage> createState() => _TrackingSessionHistoryPageState();
}

class _TrackingSessionHistoryPageState extends State<TrackingSessionHistoryPage> {
  late final AppController _controller;
  bool _isLoading = false;
  HistoryDateFilter _dateFilter = HistoryDateFilter.today; // Defaults to Today
  DateTime? _customSelectedDate;

  @override
  void initState() {
    super.initState();
    _controller = sl<AppController>();
    _refreshHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() => _isLoading = true);
    await _controller.refreshToday();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime get _selectedTargetDate {
    final now = DateTime.now();
    switch (_dateFilter) {
      case HistoryDateFilter.today:
        return now;
      case HistoryDateFilter.yesterday:
        return now.subtract(const Duration(days: 1));
      case HistoryDateFilter.custom:
        return _customSelectedDate ?? now;
    }
  }

  String get _dateFilterLabel {
    switch (_dateFilter) {
      case HistoryDateFilter.today:
        return 'Today';
      case HistoryDateFilter.yesterday:
        return 'Yesterday';
      case HistoryDateFilter.custom:
        return _customSelectedDate != null ? Fmt.date(_customSelectedDate!) : 'Selected Date';
    }
  }

  List<DaySummary> _applyFilter(List<DaySummary> all) {
    final target = _selectedTargetDate;
    return all.where((d) => _isSameDay(d.date, target)).toList();
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customSelectedDate ?? now,
      firstDate: DateTime(2023, 1, 1),
      lastDate: now, // Strictly disable future dates
      helpText: 'SELECT SESSION DATE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customSelectedDate = picked;
        _dateFilter = HistoryDateFilter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final allHistory = _controller.history;
        final filteredHistory = _applyFilter(allHistory);
        final DaySummary? selectedDay = filteredHistory.isNotEmpty ? filteredHistory.first : null;

        final totalDistance = selectedDay != null ? selectedDay.stats.distanceMeters : 0.0;
        final totalSites = selectedDay != null ? selectedDay.siteVisitCount : 0;
        final totalSeconds = selectedDay != null ? selectedDay.stats.trackingSeconds : 0;
        final sessionCount = selectedDay != null ? selectedDay.sessionCount : 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session History',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Attendance & field duty timeline',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF334155)),
                tooltip: 'Reload History',
                onPressed: _isLoading ? null : _refreshHistory,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              // ── Top Summary Grid (Reflecting the Selected Single Day) ────
              _HistorySummaryCard(
                dateLabel: _dateFilterLabel,
                sessionCount: sessionCount,
                totalDistance: totalDistance,
                totalSites: totalSites,
                totalSeconds: totalSeconds,
              ),
              const SizedBox(height: 18),

              // ── Date Filter Bar (Today / Yesterday / Pick Date) ──────────
              _DateFilterBar(
                selectedFilter: _dateFilter,
                customDate: _customSelectedDate,
                onFilterChanged: (filter) {
                  setState(() => _dateFilter = filter);
                },
                onPickCustomDate: _pickCustomDate,
              ),
              const SizedBox(height: 16),

              // ── Section Header ───────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.history_toggle_off_rounded, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'DUTY SESSIONS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$sessionCount session${sessionCount == 1 ? "" : "s"}',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Sessions List or Empty State ─────────────────────────────
              if (filteredHistory.isEmpty)
                _EmptyHistoryPlaceholder(
                  dateLabel: _dateFilterLabel,
                  isToday: _dateFilter == HistoryDateFilter.today,
                  onSelectToday: () {
                    setState(() {
                      _dateFilter = HistoryDateFilter.today;
                      _customSelectedDate = null;
                    });
                  },
                  onPickCustomDate: _pickCustomDate,
                  onRefresh: _refreshHistory,
                )
              else
                for (final day in filteredHistory) ...[
                  _DayGroupCard(
                    summary: day,
                    controller: _controller,
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Filter Bar (Single Day Selection: Today / Yesterday / Calendar Picker)
// ─────────────────────────────────────────────────────────────────────────────
class _DateFilterBar extends StatelessWidget {
  final HistoryDateFilter selectedFilter;
  final DateTime? customDate;
  final ValueChanged<HistoryDateFilter> onFilterChanged;
  final VoidCallback onPickCustomDate;

  const _DateFilterBar({
    required this.selectedFilter,
    required this.customDate,
    required this.onFilterChanged,
    required this.onPickCustomDate,
  });

  @override
  Widget build(BuildContext context) {
    final customLabel = customDate != null && selectedFilter == HistoryDateFilter.custom
        ? Fmt.date(customDate!)
        : 'Pick Date';

    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: 'Today',
            icon: Icons.today_rounded,
            isSelected: selectedFilter == HistoryDateFilter.today,
            onTap: () => onFilterChanged(HistoryDateFilter.today),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Yesterday',
            icon: Icons.history_rounded,
            isSelected: selectedFilter == HistoryDateFilter.yesterday,
            onTap: () => onFilterChanged(HistoryDateFilter.yesterday),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: customLabel,
            icon: Icons.calendar_month_rounded,
            isSelected: selectedFilter == HistoryDateFilter.custom,
            onTap: onPickCustomDate,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Metric Card
// ─────────────────────────────────────────────────────────────────────────────
class _HistorySummaryCard extends StatelessWidget {
  final String dateLabel;
  final int sessionCount;
  final double totalDistance;
  final int totalSites;
  final int totalSeconds;

  const _HistorySummaryCard({
    required this.dateLabel,
    required this.sessionCount,
    required this.totalDistance,
    required this.totalSites,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined, size: 16, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Text(
                'FIELD TOTALS OVERVIEW',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Text(
                  dateLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricPill(
                  icon: Icons.layers_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFEFF6FF),
                  label: 'Sessions',
                  value: '$sessionCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetricPill(
                  icon: Icons.route_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFECFDF5),
                  label: 'Distance',
                  value: Fmt.distance(totalDistance),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricPill(
                  icon: Icons.apartment_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFFFBEB),
                  label: 'Site Visits',
                  value: '$totalSites',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetricPill(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  iconBg: const Color(0xFFF5F3FF),
                  label: 'Duty Time',
                  value: Fmt.duration(Duration(seconds: totalSeconds)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _SummaryMetricPill({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day Group Card (Holds one or multiple sessions for that day)
// ─────────────────────────────────────────────────────────────────────────────
class _DayGroupCard extends StatelessWidget {
  final DaySummary summary;
  final AppController controller;

  const _DayGroupCard({
    required this.summary,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = summary.sessions;
    final totalSessions = sessions.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day Header Strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_note_rounded, size: 13, color: Color(0xFF475569)),
                      const SizedBox(width: 4.5),
                      Text(
                        Fmt.dayLabel(summary.date),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Fmt.date(summary.date),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Text(
                    '$totalSessions session${totalSessions == 1 ? "" : "s"}',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Sessions List for this Day ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (var i = 0; i < sessions.length; i++) ...[
                  _SingleSessionCard(
                    sessionSummary: sessions[i],
                    totalSessions: sessions.length,
                    summaryDate: summary.date,
                    controller: controller,
                  ),
                  if (i < sessions.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single Session Card (with Check In, Check Out, Street Address, & Metrics)
// ─────────────────────────────────────────────────────────────────────────────
class _SingleSessionCard extends StatelessWidget {
  final DaySessionSummary sessionSummary;
  final int totalSessions;
  final DateTime summaryDate;
  final AppController controller;

  const _SingleSessionCard({
    required this.sessionSummary,
    required this.totalSessions,
    required this.summaryDate,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final attendance = sessionSummary.attendance;
    final isCompleted = attendance.status == AttendanceStatus.completed;
    final isInterrupted = attendance.status == AttendanceStatus.interrupted;

    final statusLabel = isCompleted
        ? 'COMPLETED'
        : isInterrupted
            ? 'PAUSED'
            : 'ON DUTY';
    final statusColor = isCompleted
        ? const Color(0xFF059669)
        : isInterrupted
            ? const Color(0xFFD97706)
            : const Color(0xFF2563EB);
    final statusBg = isCompleted
        ? const Color(0xFFECFDF5)
        : isInterrupted
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFEFF6FF);

    return InkWell(
      onTap: () => _showSessionDetailSheet(context, sessionSummary, summaryDate, controller),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Badge, Status & Direct "View Map" Action
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    totalSessions > 1 ? 'SESSION #${sessionSummary.sessionIndex}' : 'DUTY SESSION',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SessionRouteMapPage(
                          sessionSummary: sessionSummary,
                          sessionDate: summaryDate,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.explore_rounded, size: 13, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          'View Map',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Check In Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Icon(Icons.login_rounded, size: 13, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Check In: ',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                          Text(
                            Fmt.time(attendance.checkInAt),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1.5),
                      GeoAddressText(
                        latitude: attendance.checkInLatitude,
                        longitude: attendance.checkInLongitude,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Check Out Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: attendance.checkOutAt != null ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: attendance.checkOutAt != null ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Icon(
                    attendance.checkOutAt != null ? Icons.logout_rounded : Icons.pending_rounded,
                    size: 13,
                    color: attendance.checkOutAt != null ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Check Out: ',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                          Text(
                            attendance.checkOutAt != null ? Fmt.time(attendance.checkOutAt) : 'In Progress',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: attendance.checkOutAt != null ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      if (attendance.checkOutLatitude != null && attendance.checkOutLongitude != null) ...[
                        const SizedBox(height: 1.5),
                        GeoAddressText(
                          latitude: attendance.checkOutLatitude!,
                          longitude: attendance.checkOutLongitude!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (sessionSummary.siteNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sessionSummary.siteNames.map((site) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apartment_rounded, size: 11, color: Color(0xFF2563EB)),
                        const SizedBox(width: 3.5),
                        Text(
                          site,
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),

            // Metrics Strip for this session
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _SessionMetricItem(
                    icon: Icons.timer_outlined,
                    label: Fmt.duration(attendance.workedDuration),
                  ),
                  const Spacer(),
                  _SessionMetricItem(
                    icon: Icons.route_rounded,
                    label: Fmt.distance(sessionSummary.distanceMeters),
                  ),
                  const Spacer(),
                  _SessionMetricItem(
                    icon: Icons.domain_rounded,
                    label: '${sessionSummary.siteVisitCount} Site${sessionSummary.siteVisitCount == 1 ? "" : "s"}',
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetailSheet(
    BuildContext context,
    DaySessionSummary session,
    DateTime date,
    AppController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      elevation: 16,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final steps = session.steps;
        final isCompleted = session.attendance.status == AttendanceStatus.completed;
        final isInterrupted = session.attendance.status == AttendanceStatus.interrupted;
        final statusLabel = isCompleted
            ? 'COMPLETED'
            : isInterrupted
                ? 'PAUSED'
                : 'ON DUTY';
        final statusColor = isCompleted
            ? const Color(0xFF059669)
            : isInterrupted
                ? const Color(0xFFD97706)
                : const Color(0xFF2563EB);
        final statusBg = isCompleted
            ? const Color(0xFFECFDF5)
            : isInterrupted
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFEFF6FF);

        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Session Specific Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Session #${session.sessionIndex} Details',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chronological session events and route timeline',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        Fmt.date(date),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Prominent "View Route on Map" Button ─────────────────────
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SessionRouteMapPage(
                          sessionSummary: session,
                          sessionDate: date,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x332563EB),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.explore_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'View Route on Map',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Metrics row for this session
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DetailMetricItem(
                          icon: Icons.timer_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          label: 'Duration',
                          value: Fmt.duration(session.duration),
                        ),
                      ),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: _DetailMetricItem(
                          icon: Icons.route_rounded,
                          iconColor: const Color(0xFF059669),
                          label: 'Distance',
                          value: Fmt.distance(session.distanceMeters),
                        ),
                      ),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: _DetailMetricItem(
                          icon: Icons.apartment_rounded,
                          iconColor: const Color(0xFF2563EB),
                          label: 'Sites',
                          value: '${session.siteVisitCount}',
                        ),
                      ),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: _DetailMetricItem(
                          icon: Icons.pause_circle_outline_rounded,
                          iconColor: const Color(0xFFD97706),
                          label: 'Holds',
                          value: '${session.stationaryEvents.length}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Events Title
                Text(
                  'SESSION EVENTS TIMELINE',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),

                // Strict Chronological Steps: Clock In -> Holds -> Sites -> Clock Out
                for (var i = 0; i < steps.length; i++)
                  _TimelineStepTile(
                    step: steps[i],
                    isFirst: i == 0,
                    isLast: i == steps.length - 1,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DetailMetricItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailMetricItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}

class _SessionMetricItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SessionMetricItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF2563EB)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _TimelineStepTile extends StatelessWidget {
  final SessionStep step;
  final bool isFirst;
  final bool isLast;

  const _TimelineStepTile({
    required this.step,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg, borderCol) = switch (step.type) {
      SessionStepType.checkIn => (
          Icons.login_rounded,
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
        ),
      SessionStepType.siteClockIn => (
          Icons.apartment_rounded,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
        ),
      SessionStepType.siteClockOut => (
          Icons.business_rounded,
          const Color(0xFF0284C7),
          const Color(0xFFE0F2FE),
          const Color(0xFFBAE6FD),
        ),
      SessionStepType.hold => (
          Icons.pause_circle_rounded,
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
        ),
      SessionStepType.checkOut => (
          Icons.logout_rounded,
          const Color(0xFFEF4444),
          const Color(0xFFFEF2F2),
          const Color(0xFFFECACA),
        ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Stepper Indicator Rail (Icon Node + Connecting Line) ────
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderCol, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, size: 15, color: color),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Step Content Card ──────────────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
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
                          step.title,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          Fmt.time(step.time),
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (step.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                  if (step.location != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GeoAddressText(
                            latitude: step.location!.latitude,
                            longitude: step.location!.longitude,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0369A1),
                              height: 1.25,
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryPlaceholder extends StatelessWidget {
  final String dateLabel;
  final bool isToday;
  final VoidCallback onSelectToday;
  final VoidCallback onPickCustomDate;
  final VoidCallback onRefresh;

  const _EmptyHistoryPlaceholder({
    required this.dateLabel,
    required this.isToday,
    required this.onSelectToday,
    required this.onPickCustomDate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 28,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Sessions for $dateLabel',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isToday
                ? 'No duty sessions or site check-ins have been recorded today yet.'
                : 'No attendance check-ins or tracking duty were recorded on this date.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 16),
          if (!isToday)
            ElevatedButton.icon(
              onPressed: onSelectToday,
              icon: const Icon(Icons.today_rounded, size: 16),
              label: Text('View Today', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Refresh', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}
