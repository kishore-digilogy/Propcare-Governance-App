import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../core/utils/formatters.dart';
import '../../services/tracking_controller.dart';
import '../pages/field_tracking_page.dart';
import '../pages/tracking_session_history_page.dart';

/// Clean & Compact Attendance Duty Card for Dashboard Header.
/// When user checks in for duty, it starts tracking and opens the dedicated FieldTrackingPage.
class DashboardTrackingHeader extends StatefulWidget {
  const DashboardTrackingHeader({super.key});

  @override
  State<DashboardTrackingHeader> createState() =>
      _DashboardTrackingHeaderState();
}

class _DashboardTrackingHeaderState extends State<DashboardTrackingHeader> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = sl<AppController>();
    if (_controller.booting) {
      _controller.bootstrap();
    } else if (_controller.position == null &&
        _controller.hasLocationPermission) {
      _controller.refreshCurrentPosition(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.booting) {
          return Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Initializing Field Tracking Engine...',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        final isCheckedIn = _controller.isCheckedIn;
        final isLive = _controller.isTrackingLive;
        final distanceToOffice = _controller.distanceToOffice;
        final insideOffice =
            distanceToOffice != null &&
            _controller.isInsideOffice(distanceToOffice);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notice Banner if any
            if (_controller.notice != null) ...[
              _NoticePill(
                message: _controller.notice!,
                isError: false,
                onDismiss: _controller.dismissNotice,
              ),
              const SizedBox(height: 12),
            ],
            if (_controller.error != null) ...[
              _NoticePill(
                message: _controller.error!,
                isError: true,
                onDismiss: () => setState(() => _controller.error = null),
              ),
              const SizedBox(height: 12),
            ],

            // ── Clean Single Duty Attendance Card ─────────────────────
            _AttendanceDutyCard(
              controller: _controller,
              isCheckedIn: isCheckedIn,
              isLive: isLive,
              insideOffice: insideOffice,
              distanceToOffice: distanceToOffice,
              onCheckIn: _handleOfficeCheckIn,
              onCheckOut: _handleOfficeCheckOut,
              onOpenTrackingPage: _openTrackingPage,
              onOpenHistory: _openHistoryPage,
            ),
          ],
        );
      },
    );
  }

  void _openTrackingPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FieldTrackingPage()));
  }

  void _openHistoryPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrackingSessionHistoryPage()),
    );
  }

  Future<void> _handleOfficeCheckIn() async {
    try {
      await _controller.officeCheckIn();
      if (mounted) {
        _openTrackingPage();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, message: e.toString());
      }
    }
  }

  Future<void> _handleOfficeCheckOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Field Duty?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will stop background location tracking, log your final location and battery level, and close today\'s attendance session.',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Check Out',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.officeCheckOut();
      } catch (e) {
        if (mounted) {
          AppSnackBar.error(context, message: e.toString());
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day Duty Attendance Card
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceDutyCard extends StatelessWidget {
  final AppController controller;
  final bool isCheckedIn;
  final bool isLive;
  final bool insideOffice;
  final double? distanceToOffice;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final VoidCallback onOpenTrackingPage;
  final VoidCallback onOpenHistory;

  const _AttendanceDutyCard({
    required this.controller,
    required this.isCheckedIn,
    required this.isLive,
    required this.insideOffice,
    required this.distanceToOffice,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onOpenTrackingPage,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final attendance = controller.attendance;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLive
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive ? const Color(0x0C10B981) : const Color(0x0A0F172A),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Status Row
          Row(
            children: [
              _StatusBeacon(
                label: isLive
                    ? 'TRACKING LIVE'
                    : isCheckedIn
                    ? 'DUTY PAUSED'
                    : 'OFF DUTY',
                color: isLive
                    ? const Color(0xFF10B981)
                    : isCheckedIn
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF64748B),
                isPulsing: isLive,
              ),
              const Spacer(),
              // Session History Button
              InkWell(
                onTap: onOpenHistory,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'History',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // GPS Accuracy Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gps_fixed_rounded,
                      size: 12,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.position != null
                          ? '±${controller.accuracy.round()}m'
                          : 'GPS Ready',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Timer & Duty Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCheckedIn
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isCheckedIn
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6))
                              .withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isCheckedIn ? Icons.timer_outlined : Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'ON DUTY TIME' : 'DAILY ATTENDANCE',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (isCheckedIn && attendance != null)
                      _LiveClockWidget(
                        startAt: attendance.checkInAt,
                        endAt: attendance.checkOutAt,
                      )
                    else
                      Text(
                        'Not Checked In',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Current Address / Geofence Snippet (With Permission Request & Multi-Line Address)
          _LocationFieldTile(
            controller: controller,
            insideOffice: insideOffice,
            distanceToOffice: distanceToOffice,
            onOpenHistory: onOpenHistory,
          ),
          const SizedBox(height: 16),

          // ── Main Attendance Actions
          if (isCheckedIn)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: onOpenTrackingPage,
                      icon: const Icon(Icons.explore_rounded, size: 18),
                      label: Text(
                        'Field Map & Sites →',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(
                        color: Color(0xFFFCA5A5),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: controller.busy ? null : onCheckOut,
                    child: const Icon(Icons.logout_rounded, size: 20),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: controller.busy ? null : onCheckIn,
                icon: controller.busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.fingerprint_rounded, size: 20),
                label: Text(
                  'Check In for Duty',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Sub-Widgets: Status Beacon, Battery Capsule, Live Clock, Notice Pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBeacon extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPulsing;

  const _StatusBeacon({
    required this.label,
    required this.color,
    this.isPulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isPulsing
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveClockWidget extends StatefulWidget {
  final DateTime startAt;
  final DateTime? endAt;

  const _LiveClockWidget({required this.startAt, this.endAt});

  @override
  State<_LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<_LiveClockWidget> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (widget.endAt == null) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant _LiveClockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endAt != null) {
      _ticker?.cancel();
      _ticker = null;
    } else if (widget.startAt != oldWidget.startAt || _ticker == null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.endAt ?? DateTime.now();
    final diff = now.difference(widget.startAt);
    final duration = diff.isNegative ? Duration.zero : diff;

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$hours:$minutes:$seconds',
      style: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFF0F172A),
      ),
    );
  }
}

class _LocationFieldTile extends StatefulWidget {
  final AppController controller;
  final bool insideOffice;
  final double? distanceToOffice;
  final VoidCallback onOpenHistory;

  const _LocationFieldTile({
    required this.controller,
    required this.insideOffice,
    required this.distanceToOffice,
    required this.onOpenHistory,
  });

  @override
  State<_LocationFieldTile> createState() => _LocationFieldTileState();
}

class _LocationFieldTileState extends State<_LocationFieldTile> {
  bool _isRequestingPermission = false;

  Future<void> _handlePermissionRequest() async {
    setState(() => _isRequestingPermission = true);
    try {
      final report = await widget.controller.requestPermissions();
      if (report.foreground) {
        await widget.controller.refreshCurrentPosition(silent: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final needsPermission =
        controller.isMobile && !controller.hasLocationPermission;
    final hasAddress =
        controller.currentAddress != null &&
        controller.currentAddress!.isNotEmpty;

    // 1. Permission Needed state (First time or location permission disabled)
    if (needsPermission) {
      return InkWell(
        onTap: _isRequestingPermission ? null : _handlePermissionRequest,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A2563EB),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isRequestingPermission
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563EB),
                        ),
                      )
                    : const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enable Location Permission',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Tap to allow GPS and fetch your field address',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Enable',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Address obtained or locating position state
    final isLocating = controller.isLocatingPosition;
    final displayText = hasAddress
        ? controller.currentAddress!
        : (widget.insideOffice
              ? 'Inside Office Geofence'
              : widget.distanceToOffice != null
              ? '${Fmt.distance(widget.distanceToOffice!)} from Base Office'
              : isLocating
              ? 'Locating field position...'
              : 'Tap to locate field position');

    return InkWell(
      onTap: () {
        if (!hasAddress && controller.position == null) {
          controller.refreshCurrentPosition(silent: false);
        } else {
          widget.onOpenHistory();
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: isLocating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0284C7),
                      ),
                    )
                  : const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Color(0xFF0284C7),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                  height: 1.35,
                ),
                maxLines: 3, // Show on next line if overflow happened!
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: isLocating
                  ? const Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    )
                  : const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF94A3B8),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticePill extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _NoticePill({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF059669);
    final bg = isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final border = isError ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: color),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
