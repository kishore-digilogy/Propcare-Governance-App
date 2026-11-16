import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/utils/tracking_exception.dart';
import '../core/utils/geo.dart';
import 'tracking/demo_location.dart';

class LocationFix {
  const LocationFix({
    required this.point,
    required this.accuracy,
    required this.timestamp,
    this.speed,
    this.simulated = false,
  });

  final GeoPoint point;
  final double accuracy;
  final DateTime timestamp;
  final double? speed;
  final bool simulated;
}

class PermissionReport {
  const PermissionReport({
    required this.locationServiceEnabled,
    required this.foreground,
    required this.background,
    required this.notifications,
    required this.precise,
    this.simulated = false,
  });

  final bool locationServiceEnabled;
  final bool foreground;
  final bool background;
  final bool notifications;
  final bool precise;
  final bool simulated;

  bool get canTrack => locationServiceEnabled && foreground && (background || simulated);
  bool get isReady => canTrack && notifications;

  List<String> get issues {
    if (simulated) return const [];
    final list = <String>[];
    if (!locationServiceEnabled) list.add('Location services are switched off');
    if (!foreground) list.add('Location permission is required');
    if (!background) list.add('"Always allow" is required for background tracking');
    if (!notifications) list.add('Notifications are required for the tracking service');
    if (!precise) list.add('Precise location improves geofence accuracy');
    return list;
  }

  static const PermissionReport demo = PermissionReport(
    locationServiceEnabled: true,
    foreground: true,
    background: true,
    notifications: true,
    precise: true,
    simulated: true,
  );
}

class LocationService {
  bool get isMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<PermissionReport> checkPermissions({bool request = false}) async {
    if (!isMobile) return PermissionReport.demo;

    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      var foreground = await Permission.location.status;
      var background = await Permission.locationAlways.status;
      var notifications = await Permission.notification.status;

      if (request) {
        // 1. Request location permission first so the user sees the OS prompt immediately
        if (!foreground.isGranted) {
          try {
            foreground = await Permission.location.request();
          } catch (_) {}
        }

        // Secondary check via Geolocator directly to guarantee native iOS/Android prompt
        var geoPerm = await Geolocator.checkPermission();
        if (geoPerm == LocationPermission.denied) {
          try {
            geoPerm = await Geolocator.requestPermission();
          } catch (_) {}
        }

        final isForeGranted = foreground.isGranted ||
            geoPerm == LocationPermission.whileInUse ||
            geoPerm == LocationPermission.always;

        // 2. Request background location if foreground was granted
        if (isForeGranted && !background.isGranted && geoPerm != LocationPermission.always) {
          try {
            background = await Permission.locationAlways.request();
          } catch (_) {}
        }

        // 3. Request notifications (optional, doesn't block location)
        if (!notifications.isGranted) {
          try {
            notifications = await Permission.notification.request();
          } catch (_) {}
        }

        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      final geoFinal = await Geolocator.checkPermission();
      final foregroundGranted = foreground.isGranted ||
          geoFinal == LocationPermission.whileInUse ||
          geoFinal == LocationPermission.always;
      final backgroundGranted = background.isGranted || geoFinal == LocationPermission.always;

      var precise = true;
      try {
        final accuracy = await Geolocator.getLocationAccuracy();
        precise = accuracy != LocationAccuracyStatus.reduced;
      } catch (_) {
        // Not supported on every OEM build — assume precise.
      }

      return PermissionReport(
        locationServiceEnabled: serviceEnabled,
        foreground: foregroundGranted,
        background: backgroundGranted,
        notifications: notifications.isGranted,
        precise: precise,
      );
    } catch (_) {
      return PermissionReport.demo;
    }
  }

  Future<PermissionReport> requestPermissions() => checkPermissions(request: true);

  Future<LocationFix> currentFix({bool allowSimulatedFallback = true}) async {
    if (!isMobile) {
      return LocationFix(
        point: DemoLocationProvider.instance.position,
        accuracy: DemoLocationProvider.instance.accuracy,
        timestamp: DateTime.now(),
        speed: 0,
        simulated: true,
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw AppException('Location services are switched off. Turn on GPS to continue.', code: 'gps_off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw AppException(
        'Location permission is required to verify your attendance.',
        code: 'permission_denied',
      );
    }

    Position? last;
    try {
      last = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    // Fast path: if a recent fix (within 15 minutes) is already cached by OS, return immediately
    if (last != null) {
      final age = DateTime.now().difference(last.timestamp);
      if (age < const Duration(minutes: 15)) {
        return LocationFix(
          point: GeoPoint(last.latitude, last.longitude),
          accuracy: last.accuracy,
          timestamp: last.timestamp,
          speed: last.speed,
        );
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LocationFix(
        point: GeoPoint(position.latitude, position.longitude),
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        speed: position.speed,
      );
    } on LocationServiceDisabledException {
      throw AppException('Location services are switched off. Turn on GPS to continue.', code: 'gps_off');
    } on PermissionDeniedException {
      throw AppException('Location permission was denied.', code: 'permission_denied');
    } catch (error) {
      if (last != null) {
        return LocationFix(
          point: GeoPoint(last.latitude, last.longitude),
          accuracy: last.accuracy,
          timestamp: last.timestamp,
          speed: last.speed,
        );
      }
      if (allowSimulatedFallback) {
        return LocationFix(
          point: DemoLocationProvider.instance.position,
          accuracy: DemoLocationProvider.instance.accuracy,
          timestamp: DateTime.now(),
          simulated: true,
        );
      }
      throw AppException(
        'Could not get a GPS fix. Move to an open area and try again.',
        code: 'gps_timeout',
      );
    }
  }

  Future<void> openAppSettingsPage() => openAppSettings();

  Future<void> openLocationSettingsPage() => Geolocator.openLocationSettings();
}
