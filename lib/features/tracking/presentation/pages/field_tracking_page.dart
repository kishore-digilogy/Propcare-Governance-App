import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../core/config/tracking_config.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../core/widgets/google_route_map.dart';
import '../../data/models/place.dart';
import '../../services/tracking_controller.dart';
import 'tracking_session_history_page.dart';

/// Dedicated Field Tracking & Site Attendance Page.
/// Opens when the user checks in or taps "Open Live Radar & Site Clock".
class FieldTrackingPage extends StatefulWidget {
  const FieldTrackingPage({super.key});

  @override
  State<FieldTrackingPage> createState() => _FieldTrackingPageState();
}

class _FieldTrackingPageState extends State<FieldTrackingPage> {
  late final AppController _controller;
  Site? _selectedSite;

  @override
  void initState() {
    super.initState();
    _controller = sl<AppController>();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final office = _controller.office ?? OfficeConfig.fromMap(AppConfig.office.toMap());
        final sites = _controller.sites.isNotEmpty
            ? _controller.sites
            : AppConfig.sites.map((s) => Site.fromMap(s.toMap())).toList();
        final activeSiteVisit = _controller.activeSiteVisit;
        final isCheckedIn = _controller.isCheckedIn;
        final isLive = _controller.isTrackingLive;

        // Auto select closest site if none chosen
        final closest = _controller.findClosestSite();
        final activeSite = (sites.any((s) => s.id == _selectedSite?.id)
                ? _selectedSite
                : null) ??
            closest?.site ??
            (sites.isNotEmpty ? sites.first : null);

        final attendance = _controller.attendance;

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
                  'Live Field Tracking',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  isLive ? 'Background GPS is actively streaming' : 'Tracking paused',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isLive ? const Color(0xFF059669) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, size: 20, color: Color(0xFF334155)),
                tooltip: 'Session History',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrackingSessionHistoryPage()),
                ),
              ),
              const SizedBox(width: 4),
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
                    const Icon(Icons.gps_fixed_rounded, size: 12, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Text(
                      _controller.position != null ? '±${_controller.accuracy.round()}m' : 'GPS Ready',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Live Status Badge
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isLive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isLive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isLive ? 'LIVE' : 'OFFLINE',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isLive ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              final siteClockSection = _DedicatedSiteClockCard(
                controller: _controller,
                sites: sites,
                activeSiteVisit: activeSiteVisit,
                selectedSite: activeSite,
                isCheckedIn: isCheckedIn,
                onSiteSelected: (site) => setState(() => _selectedSite = site),
                onSiteCheckIn: (site) => _handleSiteCheckIn(site),
                onSiteCheckOut: () => _handleSiteCheckOut(),
              );

              final mapSection = _DedicatedLiveMapCard(
                office: office,
                sites: sites,
                currentPosition: _controller.position,
                accuracy: _controller.accuracy,
                route: _controller.recentLocations.reversed.map((e) => e.point).toList(),
                activeSiteId: activeSiteVisit?.siteId,
                isLive: isLive,
              );

              final statsRow = _DutyStatsRow(
                attendance: attendance,
                controller: _controller,
                onCheckOut: () => _handleOfficeCheckOut(),
              );

              if (isWide) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    statsRow,
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: siteClockSection),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: mapSection),
                      ],
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  statsRow,
                  const SizedBox(height: 14),
                  siteClockSection,
                  const SizedBox(height: 14),
                  mapSection,
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleSiteCheckIn(Site site) async {
    try {
      await _controller.siteCheckIn(site);
      if (mounted) {
        AppSnackBar.success(
          context,
          title: 'Site Check-In',
          message: 'Successfully clocked in at ${site.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, message: e.toString());
      }
    }
  }

  Future<void> _handleSiteCheckOut() async {
    try {
      await _controller.siteCheckOut();
      if (mounted) {
        AppSnackBar.info(
          context,
          title: 'Site Check-Out',
          message: 'Clocked out from site visit.',
        );
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
        title: Text('End Field Duty?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'This will stop background tracking and record your departure time.',
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Check Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.officeCheckOut();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.error(context, message: e.toString());
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duty Stats Row (Live Stopwatch + GPS Status + Check Out Option)
// ─────────────────────────────────────────────────────────────────────────────

class _DutyStatsRow extends StatelessWidget {
  final dynamic attendance;
  final AppController controller;
  final VoidCallback onCheckOut;

  const _DutyStatsRow({
    required this.attendance,
    required this.controller,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.timer_outlined, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DUTY DURATION',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if (attendance != null)
                  _DedicatedLiveClockWidget(
                    startAt: attendance.checkInAt,
                    endAt: attendance.checkOutAt,
                    fontSize: 20,
                    color: const Color(0xFF0F172A),
                  )
                else
                  Text(
                    '00:00:00',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              backgroundColor: const Color(0xFFFEF2F2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: onCheckOut,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: Text(
              'End Duty',
              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedicated Site Clock Card
// ─────────────────────────────────────────────────────────────────────────────

class _DedicatedSiteClockCard extends StatelessWidget {
  final AppController controller;
  final List<Site> sites;
  final dynamic activeSiteVisit;
  final Site? selectedSite;
  final bool isCheckedIn;
  final ValueChanged<Site> onSiteSelected;
  final ValueChanged<Site> onSiteCheckIn;
  final VoidCallback onSiteCheckOut;

  const _DedicatedSiteClockCard({
    required this.controller,
    required this.sites,
    required this.activeSiteVisit,
    required this.selectedSite,
    required this.isCheckedIn,
    required this.onSiteSelected,
    required this.onSiteCheckIn,
    required this.onSiteCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveVisit = activeSiteVisit != null;
    final targetSite = selectedSite ?? (sites.isNotEmpty ? sites.first : null);
    final distance = targetSite != null ? controller.distanceToSite(targetSite) : null;
    final isInside = targetSite != null && distance != null && controller.isInsideSite(targetSite, distance);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasActiveVisit ? const Color(0xFF3B82F6).withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
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
                child: const Icon(Icons.business_rounded, size: 16, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Text(
                'SITE CLOCK IN / OUT',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (hasActiveVisit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    'VISITING',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasActiveVisit) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeSiteVisit.siteName ?? 'Active Site',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Clocked in at ${Fmt.time(activeSiteVisit.checkInAt)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _DedicatedLiveClockWidget(
                  startAt: activeSiteVisit.checkInAt,
                  fontSize: 20,
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: controller.busy ? null : onSiteCheckOut,
                icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                label: Text(
                  'Clock Out from Site',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            if (sites.isNotEmpty)
              _SiteSelectorTile(
                targetSite: targetSite,
                distance: distance,
                isInside: isInside,
                onTap: () => _showSitePickerSheet(
                  context,
                  sites: sites,
                  currentSite: targetSite,
                  controller: controller,
                  onSelect: onSiteSelected,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isInside ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 15,
                  color: isInside ? const Color(0xFF10B981) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isInside
                        ? 'Inside site geofence (${targetSite.radiusMeters.round()}m radius) • Ready'
                        : distance != null
                            ? '${Fmt.distance(distance)} to site entrance (Geofence: ${targetSite?.radiusMeters.round() ?? 0}m)'
                            : 'Select site to clock in',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isInside ? const Color(0xFF059669) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: (controller.busy || targetSite == null)
                    ? null
                    : () => onSiteCheckIn(targetSite),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  'Site Clock In',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSitePickerSheet(
    BuildContext context, {
    required List<Site> sites,
    required Site? currentSite,
    required AppController controller,
    required ValueChanged<Site> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      elevation: 12,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.domain_rounded, size: 18, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Select Assigned Site',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Text(
                        '${sites.length} sites',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose your destination site to verify geofence and clock in.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final site = sites[i];
                      final isSelected = site.id == currentSite?.id;
                      final dist = controller.distanceToSite(site);
                      final inside = dist != null && controller.isInsideSite(site, dist);

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelect(site);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: inside
                                      ? const Color(0xFFECFDF5)
                                      : (isSelected ? const Color(0xFFDBEAFE) : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: inside ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.location_city_rounded,
                                  color: inside ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      site.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: inside ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: inside ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: inside ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                inside
                                                    ? 'In Geofence (${site.radiusMeters.round()}m)'
                                                    : dist != null
                                                        ? '${Fmt.distance(dist)} away'
                                                        : 'Radius: ${site.radiusMeters.round()}m',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: inside ? const Color(0xFF059669) : const Color(0xFF475569),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 22,
                                )
                              else
                                const Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: Color(0xFFCBD5E1),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
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
}

class _SiteSelectorTile extends StatelessWidget {
  final Site? targetSite;
  final double? distance;
  final bool isInside;
  final VoidCallback onTap;

  const _SiteSelectorTile({
    required this.targetSite,
    required this.distance,
    required this.isInside,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInside ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
            width: isInside ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isInside ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.apartment_rounded,
                color: isInside ? const Color(0xFF059669) : const Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetSite?.name ?? 'Select Target Site',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isInside ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          isInside
                              ? 'Inside Geofence (${targetSite?.radiusMeters.round() ?? 0}m)'
                              : distance != null
                                  ? '${Fmt.distance(distance!)} from site'
                                  : 'Locating field position...',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isInside ? const Color(0xFF059669) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedicated Live Map Card
// ─────────────────────────────────────────────────────────────────────────────

class _DedicatedLiveMapCard extends StatefulWidget {
  final OfficeConfig office;
  final List<Site> sites;
  final GeoPoint? currentPosition;
  final double accuracy;
  final List<GeoPoint> route;
  final String? activeSiteId;
  final bool isLive;

  const _DedicatedLiveMapCard({
    required this.office,
    required this.sites,
    required this.currentPosition,
    required this.accuracy,
    required this.route,
    required this.activeSiteId,
    required this.isLive,
  });

  @override
  State<_DedicatedLiveMapCard> createState() => _DedicatedLiveMapCardState();
}

class _DedicatedLiveMapCardState extends State<_DedicatedLiveMapCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map_rounded, size: 16, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE FIELD RADAR',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                  tooltip: _expanded ? 'Collapse Map' : 'Expand Map',
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(21)),
            child: SizedBox(
              height: _expanded ? 380 : 250,
              width: double.infinity,
              child: GoogleRouteMap(
                office: widget.office,
                sites: widget.sites,
                current: widget.currentPosition,
                accuracy: widget.accuracy,
                route: widget.route,
                activeSiteId: widget.activeSiteId,
                height: _expanded ? 380 : 250,
                radius: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DedicatedLiveClockWidget extends StatefulWidget {
  final DateTime startAt;
  final DateTime? endAt;
  final double fontSize;
  final Color color;

  const _DedicatedLiveClockWidget({
    required this.startAt,
    this.endAt,
    this.fontSize = 24,
    this.color = const Color(0xFF0F172A),
  });

  @override
  State<_DedicatedLiveClockWidget> createState() => _DedicatedLiveClockWidgetState();
}

class _DedicatedLiveClockWidgetState extends State<_DedicatedLiveClockWidget> {
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
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: widget.color,
      ),
    );
  }
}
