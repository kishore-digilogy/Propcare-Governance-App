import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../network/dio_client.dart';
import '../storage/hive_storage.dart';
import '../storage/storage_keys.dart';
import 'location_service.dart';

/// Status model representing the live state of location tracking for an activity.
class LocationTrackingStatus {
  final bool isTracking;
  final String? activityId;
  final String? siteName;
  final bool isOnHold;
  final LocationResult? lastPingLocation;
  final DateTime? lastPingTime;
  final int pingsSent;
  final double? distanceFromLastPing;
  final String message;

  const LocationTrackingStatus({
    this.isTracking = false,
    this.activityId,
    this.siteName,
    this.isOnHold = false,
    this.lastPingLocation,
    this.lastPingTime,
    this.pingsSent = 0,
    this.distanceFromLastPing,
    this.message = 'Tracking idle',
  });

  LocationTrackingStatus copyWith({
    bool? isTracking,
    String? activityId,
    String? siteName,
    bool? isOnHold,
    LocationResult? lastPingLocation,
    DateTime? lastPingTime,
    int? pingsSent,
    double? distanceFromLastPing,
    String? message,
  }) {
    return LocationTrackingStatus(
      isTracking: isTracking ?? this.isTracking,
      activityId: activityId ?? this.activityId,
      siteName: siteName ?? this.siteName,
      isOnHold: isOnHold ?? this.isOnHold,
      lastPingLocation: lastPingLocation ?? this.lastPingLocation,
      lastPingTime: lastPingTime ?? this.lastPingTime,
      pingsSent: pingsSent ?? this.pingsSent,
      distanceFromLastPing: distanceFromLastPing ?? this.distanceFromLastPing,
      message: message ?? this.message,
    );
  }
}

/// Service that manages continuous GPS location pings (every 5 minutes)
/// between Check-in and Check-out.
///
/// Features:
/// 1. Runs every 5 minutes while a site visit is active.
/// 2. Hold / Stationary Detection: If the user is on hold / stationary (< 20m movement),
///    pings are suspended until the user moves again.
/// 3. Rate-limit safe: respects server limit (> 3 min).
/// 4. Auto-saves and restores tracking state across app reloads.
class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  final Dio _dio = DioClient.instance;

  Timer? _pingTimer;
  LocationTrackingStatus _status = const LocationTrackingStatus();

  final StreamController<LocationTrackingStatus> _statusController =
      StreamController<LocationTrackingStatus>.broadcast();

  Stream<LocationTrackingStatus> get statusStream => _statusController.stream;
  LocationTrackingStatus get currentStatus => _status;

  bool get isTracking => _status.isTracking;
  String? get activeActivityId => _status.activityId;
  bool get isOnHold => _status.isOnHold;

  /// Movement threshold (in meters). If movement is less than this, user is on hold.
  static const double holdDistanceThresholdMeters = 20.0;

  /// Default ping interval: 5 minutes.
  static const Duration defaultPingInterval = Duration(minutes: 5);

  /// Test hook to override interval during testing.
  static Duration? testPingInterval;

  /// Test hook to mock ping API call.
  static Future<bool> Function(String activityId, LocationResult loc)?
      mockPingSender;

  Duration get pingInterval => testPingInterval ?? defaultPingInterval;

  /// Initializes the service and resumes active tracking if the user was checked in.
  Future<void> init() async {
    final savedActivityId =
        HiveStorage.getString(StorageKeys.activeTrackingActivityId);
    if (savedActivityId != null && savedActivityId.isNotEmpty) {
      final savedSiteName =
          HiveStorage.getString(StorageKeys.activeTrackingSiteName);
      final pingsCount =
          HiveStorage.get<int>(StorageKeys.activeTrackingPingCount) ?? 0;

      final lastLat = HiveStorage.get<double>(StorageKeys.activeTrackingLastLat);
      final lastLng = HiveStorage.get<double>(StorageKeys.activeTrackingLastLng);
      final lastPingStr =
          HiveStorage.getString(StorageKeys.activeTrackingLastPingTime);

      LocationResult? lastLoc;
      DateTime? lastTime;
      if (lastLat != null && lastLng != null) {
        lastLoc = LocationResult(
          latitude: lastLat,
          longitude: lastLng,
          accuracy: 10.0,
          capturedAt: lastPingStr ?? DateTime.now().toUtc().toIso8601String(),
        );
      }
      if (lastPingStr != null) {
        lastTime = DateTime.tryParse(lastPingStr);
      }

      _updateStatus(
        LocationTrackingStatus(
          isTracking: true,
          activityId: savedActivityId,
          siteName: savedSiteName,
          pingsSent: pingsCount,
          lastPingLocation: lastLoc,
          lastPingTime: lastTime,
          message: 'Resumed tracking session',
        ),
      );

      _startTimer();
      developer.log(
        'Resumed active tracking for activity $savedActivityId (Pings: $pingsCount)',
        name: 'LocationTracking',
      );
    }
  }

  /// Starts continuous 5-minute tracking for an activity upon check-in.
  Future<void> startTracking({
    required String activityId,
    String? siteName,
    LocationResult? initialLocation,
  }) async {
    // If already tracking another activity, stop previous first
    if (_status.isTracking && _status.activityId != activityId) {
      await stopTracking();
    }

    _status = LocationTrackingStatus(
      isTracking: true,
      activityId: activityId,
      siteName: siteName,
      lastPingLocation: initialLocation,
      lastPingTime: initialLocation != null ? DateTime.now() : null,
      pingsSent: initialLocation != null ? 1 : 0,
      isOnHold: false,
      message: 'Tracking started. Pings every 5 min.',
    );
    _statusController.add(_status);

    // Persist in local storage
    await HiveStorage.put(StorageKeys.activeTrackingActivityId, activityId);
    if (siteName != null) {
      await HiveStorage.put(StorageKeys.activeTrackingSiteName, siteName);
    }
    await HiveStorage.put(
      StorageKeys.activeTrackingStartTime,
      DateTime.now().toIso8601String(),
    );
    if (initialLocation != null) {
      await HiveStorage.put(
        StorageKeys.activeTrackingLastLat,
        initialLocation.latitude,
      );
      await HiveStorage.put(
        StorageKeys.activeTrackingLastLng,
        initialLocation.longitude,
      );
      await HiveStorage.put(
        StorageKeys.activeTrackingLastPingTime,
        initialLocation.capturedAt,
      );
      await HiveStorage.put(StorageKeys.activeTrackingPingCount, 1);
    }

    _startTimer();
    developer.log(
      'Started location tracking for $activityId (every ${pingInterval.inMinutes} mins)',
      name: 'LocationTracking',
    );
  }

  /// Stops tracking upon clock out / checkout.
  Future<void> stopTracking() async {
    _pingTimer?.cancel();
    _pingTimer = null;

    final actId = _status.activityId;
    _status = const LocationTrackingStatus(
      isTracking: false,
      message: 'Tracking stopped',
    );
    _statusController.add(_status);

    // Clean up local storage
    await HiveStorage.delete(StorageKeys.activeTrackingActivityId);
    await HiveStorage.delete(StorageKeys.activeTrackingSiteName);
    await HiveStorage.delete(StorageKeys.activeTrackingStartTime);
    await HiveStorage.delete(StorageKeys.activeTrackingLastLat);
    await HiveStorage.delete(StorageKeys.activeTrackingLastLng);
    await HiveStorage.delete(StorageKeys.activeTrackingLastPingTime);
    await HiveStorage.delete(StorageKeys.activeTrackingPingCount);

    developer.log(
      'Stopped location tracking for $actId',
      name: 'LocationTracking',
    );
  }

  void _startTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => checkAndSendPing());
  }

  /// Checks current position, applies hold / stationary detection, and sends ping if moved.
  Future<void> checkAndSendPing() async {
    if (!_status.isTracking || _status.activityId == null) {
      _pingTimer?.cancel();
      return;
    }

    try {
      final currentLoc = await LocationService.getCurrentLocation();
      final lastLoc = _status.lastPingLocation;

      // ── Hold / Stationary Detection ─────────────────────────────────────────
      // If previous ping exists, check distance moved
      if (lastLoc != null) {
        final distance = Geolocator.distanceBetween(
          lastLoc.latitude,
          lastLoc.longitude,
          currentLoc.latitude,
          currentLoc.longitude,
        );

        if (distance < holdDistanceThresholdMeters) {
          // User is staying in the same place without significant movement
          _updateStatus(
            _status.copyWith(
              isOnHold: true,
              distanceFromLastPing: distance,
              message:
                  'On Hold (${distance.toStringAsFixed(1)}m movement). Ping skipped until moved.',
            ),
          );
          developer.log(
            '⏸️ User on hold (${distance.toStringAsFixed(1)}m < ${holdDistanceThresholdMeters}m). Ping skipped.',
            name: 'LocationTracking',
          );
          return;
        }
      }

      // ── Movement Detected: Send Location Ping ───────────────────────────────
      await _sendPing(_status.activityId!, currentLoc);
    } catch (e) {
      developer.log('Error during location ping check: $e', name: 'LocationTracking');
      _updateStatus(
        _status.copyWith(
          message: 'Ping error: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  /// Sends the POST /api/activities/{id}/location-pings request.
  Future<bool> _sendPing(String activityId, LocationResult loc) async {
    if (mockPingSender != null) {
      final success = await mockPingSender!(activityId, loc);
      if (success) _recordSuccessfulPing(loc);
      return success;
    }

    final path = '/activities/$activityId/location-pings';
    final payload = {
      'geo': {
        'latitude': loc.latitude,
        'longitude': loc.longitude,
        'accuracy': loc.accuracy,
        'capturedAt': loc.capturedAt,
      },
    };

    try {
      final response = await _dio.post(path, data: payload);
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 201) {
        _recordSuccessfulPing(loc);
        developer.log(
          '📍 Location ping sent successfully for $activityId [${loc.latitude}, ${loc.longitude}]',
          name: 'LocationTracking',
        );
        return true;
      } else if (statusCode == 429) {
        developer.log(
          '⚠️ Location ping rate limited (429) for $activityId. Will retry on next 5-min cycle.',
          name: 'LocationTracking',
        );
        _updateStatus(
          _status.copyWith(message: 'Rate-limited by server (429), waiting...'),
        );
        return false;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        developer.log('⚠️ Location ping rate limited (429)', name: 'LocationTracking');
        _updateStatus(
          _status.copyWith(message: 'Server rate limit (429), waiting...'),
        );
        return false;
      }
      developer.log('❌ Location ping API error: ${e.message}', name: 'LocationTracking');
      return false;
    } catch (e) {
      developer.log('❌ Location ping error: $e', name: 'LocationTracking');
      return false;
    }
  }

  void _recordSuccessfulPing(LocationResult loc) {
    final newCount = _status.pingsSent + 1;
    final now = DateTime.now();

    _updateStatus(
      _status.copyWith(
        isOnHold: false,
        lastPingLocation: loc,
        lastPingTime: now,
        pingsSent: newCount,
        message: 'Ping #$newCount sent at ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      ),
    );

    // Save state in Hive
    HiveStorage.put(StorageKeys.activeTrackingLastLat, loc.latitude);
    HiveStorage.put(StorageKeys.activeTrackingLastLng, loc.longitude);
    HiveStorage.put(StorageKeys.activeTrackingLastPingTime, loc.capturedAt);
    HiveStorage.put(StorageKeys.activeTrackingPingCount, newCount);
  }

  void _updateStatus(LocationTrackingStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(_status);
    }
  }
}
