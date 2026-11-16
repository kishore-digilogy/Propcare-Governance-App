import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../injection_container.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/geo_address_text.dart';
import '../../core/widgets/google_route_map.dart';
import '../../data/models/attendance.dart';
import '../../data/models/day_story.dart';
import '../../data/models/tracking.dart';
import '../../services/geo_address_service.dart';
import '../../services/tracking_controller.dart';

/// Full-screen visual Route Map page for a single duty session.
/// Displays clear tracking polyline, distinct markers for Clock In, Clock Out,
/// Holds, Sites, and Current Location, plus an interactive step inspector.
class SessionRouteMapPage extends StatefulWidget {
  final DaySessionSummary sessionSummary;
  final DateTime sessionDate;

  const SessionRouteMapPage({
    super.key,
    required this.sessionSummary,
    required this.sessionDate,
  });

  @override
  State<SessionRouteMapPage> createState() => _SessionRouteMapPageState();
}

class _SessionRouteMapPageState extends State<SessionRouteMapPage> {
  late final AppController _controller;
  GoogleMapController? _mapController;

  bool _isLoadingLocations = true;
  List<LocationRecord> _sessionLocations = [];
  MapType _mapType = MapType.normal;
  int _selectedStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = sl<AppController>();
    _loadSessionRoute();
  }

  Future<void> _loadSessionRoute() async {
    try {
      final locs = await _controller.locationsForSession(
        widget.sessionSummary.attendance.sessionId,
      );
      if (mounted) {
        setState(() {
          _sessionLocations = locs;
          _isLoadingLocations = false;
        });
        _precacheAddresses();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  void _precacheAddresses() {
    final att = widget.sessionSummary.attendance;
    GeoAddressService.instance.resolve(att.checkInLatitude, att.checkInLongitude);
    if (att.checkOutLatitude != null && att.checkOutLongitude != null) {
      GeoAddressService.instance.resolve(att.checkOutLatitude!, att.checkOutLongitude!);
    }
    for (final stop in widget.sessionSummary.stationaryEvents) {
      GeoAddressService.instance.resolve(stop.latitude, stop.longitude);
    }
    for (final site in widget.sessionSummary.siteVisits) {
      GeoAddressService.instance.resolve(site.checkInLatitude, site.checkInLongitude);
    }
  }

  void _cycleMapType() {
    setState(() {
      switch (_mapType) {
        case MapType.normal:
          _mapType = MapType.terrain;
          break;
        case MapType.terrain:
          _mapType = MapType.hybrid;
          break;
        default:
          _mapType = MapType.normal;
          break;
      }
    });
  }

  List<LatLng> _polylinePoints() {
    if (_sessionLocations.isNotEmpty) {
      final sorted = [..._sessionLocations]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      return sorted.map((l) => LatLng(l.latitude, l.longitude)).toList(growable: false);
    }

    // Fallback connecting key step locations if fine breadcrumbs are not yet loaded
    final points = <LatLng>[];
    final att = widget.sessionSummary.attendance;
    points.add(LatLng(att.checkInLatitude, att.checkInLongitude));

    for (final stop in widget.sessionSummary.stationaryEvents) {
      points.add(LatLng(stop.latitude, stop.longitude));
    }
    for (final site in widget.sessionSummary.siteVisits) {
      points.add(LatLng(site.checkInLatitude, site.checkInLongitude));
    }
    if (att.checkOutLatitude != null && att.checkOutLongitude != null) {
      points.add(LatLng(att.checkOutLatitude!, att.checkOutLongitude!));
    }
    return points;
  }

  Set<Polyline> _polylines() {
    final pts = _polylinePoints();
    if (pts.length < 2) return {};

    return {
      Polyline(
        polylineId: PolylineId('route_${widget.sessionSummary.attendance.sessionId}'),
        points: pts,
        color: const Color(0xFF2563EB),
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        geodesic: true,
      ),
    };
  }

  Set<Marker> _markers() {
    final markers = <Marker>{};
    final att = widget.sessionSummary.attendance;

    // 🟢 1. Clock In Marker (Green)
    markers.add(
      Marker(
        markerId: const MarkerId('marker_clock_in'),
        position: LatLng(att.checkInLatitude, att.checkInLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '🟢 Clock In · ${Fmt.time(att.checkInAt)}',
          snippet: GeoAddressService.instance.getCached(att.checkInLatitude, att.checkInLongitude) ??
              'Duty started here',
        ),
      ),
    );

    // ⏸️ 2. Hold Markers (Orange / Amber)
    for (var i = 0; i < widget.sessionSummary.stationaryEvents.length; i++) {
      final stop = widget.sessionSummary.stationaryEvents[i];
      markers.add(
        Marker(
          markerId: MarkerId('marker_hold_${stop.id}'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: '⏸️ Hold #${i + 1} (${Fmt.durationCompact(stop.duration)})',
            snippet: GeoAddressService.instance.getCached(stop.latitude, stop.longitude) ??
                'Hold at ${Fmt.time(stop.startAt)}',
          ),
        ),
      );
    }

    // 🏢 3. Site Markers (Azure / Blue)
    for (var i = 0; i < widget.sessionSummary.siteVisits.length; i++) {
      final site = widget.sessionSummary.siteVisits[i];
      markers.add(
        Marker(
          markerId: MarkerId('marker_site_${site.id}'),
          position: LatLng(site.checkInLatitude, site.checkInLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: '🏢 Site: ${site.siteName}',
            snippet: 'Visited ${Fmt.time(site.checkInAt)} · ${site.status.label}',
          ),
        ),
      );
    }

    // 🛑 4. Clock Out Marker (Red)
    if (att.checkOutLatitude != null && att.checkOutLongitude != null && att.checkOutAt != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('marker_clock_out'),
          position: LatLng(att.checkOutLatitude!, att.checkOutLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🛑 Clock Out · ${Fmt.time(att.checkOutAt!)}',
            snippet: GeoAddressService.instance.getCached(att.checkOutLatitude!, att.checkOutLongitude!) ??
                'Duty ended here · ${Fmt.duration(att.workedDuration)}',
          ),
        ),
      );
    }

    // 📍 5. Current Live Location (Cyan) if session is currently active
    if (att.status == AttendanceStatus.active && _controller.position != null) {
      final cur = _controller.position!;
      markers.add(
        Marker(
          markerId: const MarkerId('marker_current_live'),
          position: LatLng(cur.latitude, cur.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(
            title: '📍 Current Location (Live)',
            snippet: 'Accuracy ±${_controller.accuracy.round()}m',
          ),
        ),
      );
    }

    return markers;
  }

  void _fitBounds() {
    final controller = _mapController;
    if (controller == null) return;

    final allPoints = <LatLng>[];
    final att = widget.sessionSummary.attendance;
    allPoints.add(LatLng(att.checkInLatitude, att.checkInLongitude));

    if (att.checkOutLatitude != null && att.checkOutLongitude != null) {
      allPoints.add(LatLng(att.checkOutLatitude!, att.checkOutLongitude!));
    }
    for (final stop in widget.sessionSummary.stationaryEvents) {
      allPoints.add(LatLng(stop.latitude, stop.longitude));
    }
    for (final site in widget.sessionSummary.siteVisits) {
      allPoints.add(LatLng(site.checkInLatitude, site.checkInLongitude));
    }
    for (final loc in _sessionLocations) {
      allPoints.add(LatLng(loc.latitude, loc.longitude));
    }

    if (allPoints.isEmpty) return;

    var minLat = allPoints.first.latitude;
    var maxLat = allPoints.first.latitude;
    var minLng = allPoints.first.longitude;
    var maxLng = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    if ((maxLat - minLat).abs() < 0.0001 && (maxLng - minLng).abs() < 0.0001) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(allPoints.first, 16));
      return;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  void _focusStep(int index, SessionStep step) {
    setState(() => _selectedStepIndex = index);
    final controller = _mapController;
    if (controller == null) return;

    final loc = step.location;
    if (loc != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 17),
      );

      final markerId = switch (step.type) {
        SessionStepType.checkIn => const MarkerId('marker_clock_in'),
        SessionStepType.checkOut => const MarkerId('marker_clock_out'),
        SessionStepType.hold => null,
        SessionStepType.siteClockIn || SessionStepType.siteClockOut => null,
      };

      if (markerId != null) {
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (mounted) controller.showMarkerInfoWindow(markerId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final att = widget.sessionSummary.attendance;
    final isCompleted = att.status == AttendanceStatus.completed;
    final isInterrupted = att.status == AttendanceStatus.interrupted;
    final steps = widget.sessionSummary.steps;

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

    final initialTarget = LatLng(att.checkInLatitude, att.checkInLongitude);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Map View (Google Maps on mobile / Fallback Canvas on Desktop/Test) ──
          Positioned.fill(
            child: supportsGoogleMaps
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(target: initialTarget, zoom: 15),
                    mapType: _mapType,
                    markers: _markers(),
                    polylines: _polylines(),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    onMapCreated: (ctrl) {
                      _mapController = ctrl;
                      Future<void>.delayed(const Duration(milliseconds: 400), () {
                        if (mounted) _fitBounds();
                      });
                    },
                  )
                : _MapFallbackCanvas(
                    sessionSummary: widget.sessionSummary,
                    routePoints: _polylinePoints(),
                  ),
          ),

          // ── Top Header Bar ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'SESSION #${widget.sessionSummary.sessionIndex} ROUTE',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                Fmt.date(widget.sessionDate),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _cycleMapType,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: const Icon(Icons.layers_rounded, size: 17, color: Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _fitBounds,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.crop_free_rounded, size: 17, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                    if (_isLoadingLocations) ...[
                      const SizedBox(height: 6),
                      const ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: Color(0xFF2563EB),
                          backgroundColor: Color(0xFFEFF6FF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Map Legend Floating Pill ────────────────────────────────────
          Positioned(
            top: 86,
            left: 16,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x140F172A), blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendChip(color: const Color(0xFF059669), label: 'Start'),
                    const SizedBox(width: 8),
                    _LegendChip(color: const Color(0xFFD97706), label: 'Hold'),
                    const SizedBox(width: 8),
                    _LegendChip(color: const Color(0xFF0284C7), label: 'Site'),
                    const SizedBox(width: 8),
                    _LegendChip(color: const Color(0xFFEF4444), label: 'End'),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Floating Card with Metrics & Step Carousel ──────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1E0F172A),
                      blurRadius: 24,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metric Strip
                    Row(
                      children: [
                        Expanded(
                          child: _RouteMetricTile(
                            icon: Icons.timer_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF5F3FF),
                            label: 'Duration',
                            value: Fmt.duration(widget.sessionSummary.duration),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RouteMetricTile(
                            icon: Icons.route_rounded,
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFECFDF5),
                            label: 'Distance',
                            value: Fmt.distance(widget.sessionSummary.distanceMeters),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RouteMetricTile(
                            icon: Icons.apartment_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                            label: 'Sites',
                            value: '${widget.sessionSummary.siteVisitCount}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RouteMetricTile(
                            icon: Icons.pause_circle_outline_rounded,
                            iconColor: const Color(0xFFD97706),
                            iconBg: const Color(0xFFFFFBEB),
                            label: 'Holds',
                            value: '${widget.sessionSummary.stationaryEvents.length}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section Title
                    Row(
                      children: [
                        Text(
                          'SESSION STOPS (${steps.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap stop to view on map',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Horizontal Stops Carousel
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: steps.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          final isSelected = index == _selectedStepIndex;
                          return _StepCardItem(
                            step: step,
                            stepNumber: index + 1,
                            isSelected: isSelected,
                            onTap: () => _focusStep(index, step),
                          );
                        },
                      ),
                    ),

                    // Active Step Location & Address details
                    if (steps.isNotEmpty && _selectedStepIndex < steps.length) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: steps[_selectedStepIndex].location != null
                                  ? GeoAddressText(
                                      latitude: steps[_selectedStepIndex].location!.latitude,
                                      longitude: steps[_selectedStepIndex].location!.longitude,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF334155),
                                      ),
                                      maxLines: 1,
                                    )
                                  : Text(
                                      steps[_selectedStepIndex].subtitle,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _RouteMetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _RouteMetricTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 12, color: iconColor),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
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
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _StepCardItem extends StatelessWidget {
  final SessionStep step;
  final int stepNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const _StepCardItem({
    required this.step,
    required this.stepNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (step.type) {
      SessionStepType.checkIn => (
          Icons.login_rounded,
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
        ),
      SessionStepType.hold => (
          Icons.pause_circle_outline_rounded,
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
        ),
      SessionStepType.siteClockIn => (
          Icons.apartment_rounded,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
        ),
      SessionStepType.siteClockOut => (
          Icons.business_rounded,
          const Color(0xFF0284C7),
          const Color(0xFFE0F2FE),
        ),
      SessionStepType.checkOut => (
          Icons.logout_rounded,
          const Color(0xFFEF4444),
          const Color(0xFFFEF2F2),
        ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 135,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                  child: Icon(icon, size: 12, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    Fmt.time(step.time),
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              step.title,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback radar canvas for desktop and widget test environments where native Google Maps is disabled.
class _MapFallbackCanvas extends StatelessWidget {
  final DaySessionSummary sessionSummary;
  final List<LatLng> routePoints;

  const _MapFallbackCanvas({
    required this.sessionSummary,
    required this.routePoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF334155), width: 2),
                ),
                child: const Icon(Icons.explore_rounded, size: 30, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 16),
              Text(
                'Route Visualization Ready',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${routePoints.length} tracking points · ${sessionSummary.steps.length} key session events',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
