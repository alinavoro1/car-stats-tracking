import 'dart:math' as math;

import 'models.dart';

/// Raza medie a Pământului, folosită în formula Haversine.
const double earthRadiusMeters = 6371000.0;

/// GPS-07: reguli de filtrare, documentate în documentation/decisions.md.
const double maxGpsAccuracyMeters = 50.0;
const double maxPlausibleSpeedMps = 100.0; // ~360 km/h
const double minMovingDistanceMeters = 5.0;

/// STAT-04: un segment este „în deplasare” dacă viteza implicită este de
/// cel puțin 1 m/s (~3.6 km/h) și distanța depășește zgomotul GPS.
const double movingSpeedThresholdMps = 1.0;

/// Întreruperile de semnal mai lungi nu sunt considerate staționare.
const int maxSegmentGapSeconds = 60;

/// Distanța în metri dintre două coordonate, prin formula Haversine.
double haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  if (!_isCoordinateValid(lat1, lon1) || !_isCoordinateValid(lat2, lon2)) {
    throw ArgumentError('Coordonate GPS invalide.');
  }

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusMeters * math.asin(math.sqrt(a));
}

class AnalysisResult {
  const AnalysisResult({
    required this.validPoints,
    required this.invalidPointIds,
    required this.distanceMeters,
    required this.maxSpeedMps,
    required this.movingDurationSeconds,
    required this.stationaryDurationSeconds,
    required this.totalDurationSeconds,
    required this.averageSpeedMps,
  });

  final List<GpsPoint> validPoints;
  final List<String> invalidPointIds;
  final double distanceMeters;
  final double maxSpeedMps;
  final int movingDurationSeconds;
  final int stationaryDurationSeconds;
  final int totalDurationSeconds;
  final double averageSpeedMps;
}

/// Calculează distanța și statisticile dintr-o listă de puncte GPS.
/// Punctele invalide sunt raportate separat și nu contribuie la calcule.
AnalysisResult analyzeTrip(
  List<GpsPoint> points, {
  required DateTime startedAt,
  DateTime? endedAt,
}) {
  final ordered = [...points]
    ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));

  final valid = <GpsPoint>[];
  final invalidIds = <String>[];
  var distanceMeters = 0.0;
  var maxSpeedMps = 0.0;
  var movingSeconds = 0;
  var stationarySeconds = 0;
  GpsPoint? previous;

  for (final point in ordered) {
    if (!_isPointAcceptable(point)) {
      invalidIds.add(point.id);
      continue;
    }

    if (previous != null) {
      final seconds = point.recordedAt
              .difference(previous.recordedAt)
              .inMilliseconds /
          1000.0;
      if (seconds <= 0) {
        // Timestamp duplicat sau ordine cronologică invalidă.
        invalidIds.add(point.id);
        continue;
      }

      final segmentMeters = haversineMeters(
        previous.latitude,
        previous.longitude,
        point.latitude,
        point.longitude,
      );
      final impliedSpeedMps = segmentMeters / seconds;
      if (impliedSpeedMps > maxPlausibleSpeedMps) {
        // Salt GPS nerealist: punctul este exclus.
        invalidIds.add(point.id);
        continue;
      }

      distanceMeters += segmentMeters;
      if (seconds <= maxSegmentGapSeconds) {
        if (impliedSpeedMps >= movingSpeedThresholdMps &&
            segmentMeters >= minMovingDistanceMeters) {
          movingSeconds += seconds.round();
        } else {
          stationarySeconds += seconds.round();
        }
      }
    }

    valid.add(point);
    final gpsSpeed = point.speedMps;
    if (gpsSpeed != null && gpsSpeed > maxSpeedMps) {
      maxSpeedMps = gpsSpeed;
    }
    previous = point;
  }

  final end = endedAt ??
      (valid.isEmpty ? startedAt : valid.last.recordedAt);
  final rawTotalSeconds = end.difference(startedAt).inSeconds;
  final totalSeconds = rawTotalSeconds > 0 ? rawTotalSeconds : 0;
  final averageSpeedMps =
      movingSeconds > 0 ? distanceMeters / movingSeconds : 0.0;

  return AnalysisResult(
    validPoints: valid,
    invalidPointIds: invalidIds,
    distanceMeters: distanceMeters,
    maxSpeedMps: maxSpeedMps,
    movingDurationSeconds: movingSeconds,
    stationaryDurationSeconds: stationarySeconds,
    totalDurationSeconds: totalSeconds,
    averageSpeedMps: averageSpeedMps,
  );
}

bool _isPointAcceptable(GpsPoint point) {
  if (!_isCoordinateValid(point.latitude, point.longitude)) {
    return false;
  }
  final accuracy = point.accuracyMeters;
  if (accuracy != null &&
      (!accuracy.isFinite || accuracy < 0 || accuracy > maxGpsAccuracyMeters)) {
    return false;
  }
  final speed = point.speedMps;
  if (speed != null &&
      (!speed.isFinite || speed < 0 || speed > maxPlausibleSpeedMps)) {
    return false;
  }
  return true;
}

bool _isCoordinateValid(double latitude, double longitude) {
  return latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

double _toRadians(double degrees) => degrees * math.pi / 180.0;
