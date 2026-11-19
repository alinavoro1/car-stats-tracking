import 'package:geolocator/geolocator.dart';

import 'config.dart';

/// Accesul la geolocator este izolat aici, ca restul aplicației să nu
/// depindă direct de API-ul pluginului.
class LocationService {
  AndroidSettings get _streamSettings => AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConfig.locationDistanceFilterMeters,
        intervalDuration: AppConfig.locationInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Car Tracker',
          notificationText: 'Înregistrare călătorie activă',
          notificationChannelName: 'Tracking călătorie',
          setOngoing: true,
        ),
      );

  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Stream<Position> positionStream() =>
      Geolocator.getPositionStream(locationSettings: _streamSettings);

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
