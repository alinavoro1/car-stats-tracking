import 'package:car_tracker_app/models.dart';
import 'package:car_tracker_app/trip_stats.dart';
import 'package:flutter_test/flutter_test.dart';

GpsPoint point({
  required int sequence,
  required double latitude,
  required double longitude,
  required DateTime recordedAt,
  double? speedMps,
  double? accuracyMeters,
}) {
  return GpsPoint(
    id: 'p$sequence',
    tripId: 'trip-1',
    latitude: latitude,
    longitude: longitude,
    recordedAt: recordedAt,
    sequenceNumber: sequence,
    speedMps: speedMps,
    accuracyMeters: accuracyMeters,
  );
}

void main() {
  final start = DateTime.utc(2026, 1, 1, 12);

  group('Haversine', () {
    test('două puncte identice au distanță zero', () {
      expect(haversineMeters(44.0, 26.0, 44.0, 26.0), 0);
    });

    test('un grad de longitudine la ecuator este ~111 km', () {
      final distance = haversineMeters(0, 0, 0, 1);
      expect(distance, closeTo(111195, 200));
    });

    test('respinge coordonatele invalide', () {
      expect(() => haversineMeters(91, 0, 0, 0), throwsArgumentError);
      expect(() => haversineMeters(0, 181, 0, 0), throwsArgumentError);
    });
  });

  group('Statistici', () {
    test('călătorie fără puncte', () {
      final result = analyzeTrip(
        const [],
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 5)),
      );
      expect(result.distanceMeters, 0);
      expect(result.movingDurationSeconds, 0);
      expect(result.totalDurationSeconds, 300);
      expect(result.averageSpeedMps, 0);
      expect(result.maxSpeedMps, 0);
    });

    test('un singur punct nu produce distanță', () {
      final result = analyzeTrip(
        [
          point(
            sequence: 0,
            latitude: 44.0,
            longitude: 26.0,
            recordedAt: start,
            speedMps: 10,
          ),
        ],
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 30)),
      );
      expect(result.validPoints.length, 1);
      expect(result.distanceMeters, 0);
      expect(result.maxSpeedMps, 10);
      expect(result.movingDurationSeconds, 0);
    });

    test('două puncte identice în timp diferit înseamnă staționare', () {
      final result = analyzeTrip(
        [
          point(sequence: 0, latitude: 44.0, longitude: 26.0, recordedAt: start),
          point(
            sequence: 1,
            latitude: 44.0,
            longitude: 26.0,
            recordedAt: start.add(const Duration(seconds: 10)),
          ),
        ],
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 10)),
      );
      expect(result.distanceMeters, 0);
      expect(result.movingDurationSeconds, 0);
      expect(result.stationaryDurationSeconds, 10);
    });

    test('două puncte cunoscute produc distanță și viteză medie', () {
      final result = analyzeTrip(
        [
          point(
            sequence: 0,
            latitude: 44.0,
            longitude: 26.0,
            recordedAt: start,
            speedMps: 5,
          ),
          point(
            sequence: 1,
            latitude: 44.0009,
            longitude: 26.0,
            recordedAt: start.add(const Duration(seconds: 20)),
            speedMps: 12,
          ),
        ],
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 20)),
      );
      expect(result.validPoints.length, 2);
      expect(result.distanceMeters, closeTo(100.07, 2));
      expect(result.movingDurationSeconds, 20);
      expect(result.maxSpeedMps, 12);
      expect(result.averageSpeedMps, closeTo(5.0, 0.2));
    });

    test('punctele cu acuratețe slabă sunt excluse', () {
      final result = analyzeTrip(
        [
          point(sequence: 0, latitude: 44.0, longitude: 26.0, recordedAt: start),
          point(
            sequence: 1,
            latitude: 44.0005,
            longitude: 26.0,
            recordedAt: start.add(const Duration(seconds: 10)),
            accuracyMeters: 80,
          ),
          point(
            sequence: 2,
            latitude: 44.0009,
            longitude: 26.0,
            recordedAt: start.add(const Duration(seconds: 20)),
          ),
        ],
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 20)),
      );
      expect(result.invalidPointIds, contains('p1'));
      expect(result.validPoints.map((p) => p.id), ['p0', 'p2']);
      expect(result.distanceMeters, closeTo(100.07, 2));
    });

    test('viteza lipsă este ignorată, fără excepții', () {
      final result = analyzeTrip(
        [
          point(sequence: 0, latitude: 44.0, longitude: 26.0, recordedAt: start),
          point(
            sequence: 1,
            latitude: 44.0009,
            longitude: 26.0,
            recordedAt: start.add(const Duration(seconds: 20)),
          ),
        ],
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 20)),
      );
      expect(result.maxSpeedMps, 0);
      expect(result.distanceMeters, greaterThan(0));
    });

    test('saltul GPS nerealist este eliminat din distanță', () {
      final result = analyzeTrip(
        [
          point(sequence: 0, latitude: 44.0, longitude: 26.0, recordedAt: start),
          point(
            sequence: 1,
            latitude: 44.01,
            longitude: 26.0,
            recordedAt: start.add(const Duration(seconds: 1)),
          ),
        ],
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 10)),
      );
      expect(result.invalidPointIds, contains('p1'));
      expect(result.validPoints.length, 1);
      expect(result.distanceMeters, 0);
    });

    test('viteza imposibilă invalidează punctul', () {
      final result = analyzeTrip(
        [
          point(
            sequence: 0,
            latitude: 44.0,
            longitude: 26.0,
            recordedAt: start,
            speedMps: 150,
          ),
        ],
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 10)),
      );
      expect(result.invalidPointIds, contains('p0'));
      expect(result.maxSpeedMps, 0);
    });

    test('durată zero este tratată', () {
      final result = analyzeTrip(
        [
          point(sequence: 0, latitude: 44.0, longitude: 26.0, recordedAt: start),
        ],
        startedAt: start,
        endedAt: start,
      );
      expect(result.totalDurationSeconds, 0);
      expect(result.averageSpeedMps, 0);
    });

    test('opririle sunt separate de timpul de deplasare', () {
      final result = analyzeTrip(
        [
          point(sequence: 0, latitude: 44.0, longitude: 25.0, recordedAt: start),
          point(
            sequence: 1,
            latitude: 44.0,
            longitude: 25.001,
            recordedAt: start.add(const Duration(seconds: 10)),
          ),
          point(
            sequence: 2,
            latitude: 44.0,
            longitude: 25.001,
            recordedAt: start.add(const Duration(seconds: 30)),
          ),
          point(
            sequence: 3,
            latitude: 44.0,
            longitude: 25.001,
            recordedAt: start.add(const Duration(seconds: 40)),
          ),
        ],
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 40)),
      );
      expect(result.movingDurationSeconds, 10);
      expect(result.stationaryDurationSeconds, 30);
      expect(result.distanceMeters, greaterThan(50));
    });
  });
}
