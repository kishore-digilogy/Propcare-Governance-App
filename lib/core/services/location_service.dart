import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';

/// Holds the captured geolocation coordinates and metadata.
class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String capturedAt;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'capturedAt': capturedAt,
      };
}

/// Helper service for verifying permissions and obtaining GPS coordinates.
class LocationService {
  /// Test hook to mock geolocation in widget and unit tests.
  static Future<LocationResult> Function()? mockLocationProvider;

  /// Requests permissions if needed and retrieves the current GPS coordinates.
  static Future<LocationResult> getCurrentLocation() async {
    if (mockLocationProvider != null) {
      return await mockLocationProvider!();
    }

    // 1. Check if device location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled on your device. Please turn on GPS.',
      );
    }

    // 2. Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied. Please allow location access to record attendance.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable them in your device settings.',
      );
    }

    // 3. Obtain current position
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      developer.log(
        'getCurrentPosition timed out or failed, falling back to last known position: $e',
        name: 'LocationService',
      );
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        position = lastKnown;
      } else {
        throw Exception(
          'Unable to acquire GPS coordinates. Please ensure you have a clear GPS signal and try again.',
        );
      }
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      capturedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }
}

