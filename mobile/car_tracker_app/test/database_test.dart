import 'dart:io';

import 'package:car_tracker_app/database.dart';
import 'package:car_tracker_app/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Trip trip({
  String id = 'trip-1',
  String ownerEmail = 'user@example.com',
  TripStatus status = TripStatus.active,
  SyncState syncState = SyncState.pending,
  DateTime? startedAt,
  DateTime? endedAt,
}) {
  return Trip(
    id: id,
    startedAt: startedAt ?? DateTime.utc(2026, 1, 1, 12),
    ownerEmail: ownerEmail,
    endedAt: endedAt,
    status: status,
    distanceMeters: 1000,
    averageSpeedMps: 10,
    maxSpeedMps: 15,
    movingDurationSeconds: 100,
    totalDurationSeconds: 120,
    syncState: syncState,
  );
}

GpsPoint point(String id, String tripId, int sequence) {
  return GpsPoint(
    id: id,
    tripId: tripId,
    latitude: 44.0,
    longitude: 26.0,
    recordedAt: DateTime.utc(2026, 1, 1, 12).add(Duration(seconds: sequence)),
    sequenceNumber: sequence,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase database;

  setUp(() async {
    database = await AppDatabase.open(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await database.close();
  });

  test('călătoria activă este salvată și recuperată', () async {
    await database.insertTrip(trip());
    final active = await database.getActiveTrip('user@example.com');
    expect(active, isNotNull);
    expect(active!.id, 'trip-1');
    expect(active.status, TripStatus.active);
  });

  test('punctele sunt citite în ordine după secvență', () async {
    await database.insertTrip(trip());
    await database.insertPoint(point('p2', 'trip-1', 2));
    await database.insertPoint(point('p0', 'trip-1', 0));
    await database.insertPoint(point('p1', 'trip-1', 1));

    final points = await database.getPoints('trip-1');
    expect(points.map((item) => item.sequenceNumber), [0, 1, 2]);
  });

  test('punctele filtrate pot fi marcate invalide', () async {
    await database.insertTrip(trip());
    await database.insertPoint(point('p0', 'trip-1', 0));
    await database.insertPoint(point('p1', 'trip-1', 1));

    await database.markPointsInvalid(['p1']);
    final points = await database.getPoints('trip-1');
    expect(points.firstWhere((item) => item.id == 'p1').isValid, isFalse);
    expect(points.firstWhere((item) => item.id == 'p0').isValid, isTrue);
  });

  test('doar călătoriile finalizate și nesincronizate sunt în așteptare',
      () async {
    await database.insertTrip(trip(id: 'active'));
    await database.insertTrip(
      trip(
        id: 'pending',
        status: TripStatus.completed,
        endedAt: DateTime.utc(2026, 1, 1, 13),
      ),
    );
    await database.insertTrip(
      trip(
        id: 'synced',
        status: TripStatus.completed,
        syncState: SyncState.synced,
        endedAt: DateTime.utc(2026, 1, 1, 13),
      ),
    );

    final pending =
        await database.getPendingSyncTrips('user@example.com');
    expect(pending.map((item) => item.id), ['pending']);
  });

  test('călătoriile vechi sunt atribuite primului cont', () async {
    await database.insertTrip(trip(ownerEmail: ''));

    expect(await database.getTrips('user@example.com'), isEmpty);

    await database.claimUnownedTrips('user@example.com');

    final claimed = await database.getTrips('user@example.com');
    expect(claimed.map((item) => item.id), ['trip-1']);
    expect(await database.getTrips('other@example.com'), isEmpty);
  });

  test('fiecare utilizator vede doar călătoriile proprii', () async {
    await database.insertTrip(trip(id: 'a', ownerEmail: 'a@example.com'));
    await database.insertTrip(trip(id: 'b', ownerEmail: 'b@example.com'));

    expect(
      (await database.getTrips('a@example.com')).map((item) => item.id),
      ['a'],
    );
    expect(
      (await database.getTrips('b@example.com')).map((item) => item.id),
      ['b'],
    );
  });

  test('starea de sincronizare și eroarea sunt persistate', () async {
    await database.insertTrip(
      trip(
        id: 'completed',
        status: TripStatus.completed,
        endedAt: DateTime.utc(2026, 1, 1, 13),
      ),
    );

    await database.updateSyncState(
      'completed',
      SyncState.failed,
      error: 'Server indisponibil',
    );

    final stored = await database.getTrip('completed');
    expect(stored!.syncState, SyncState.failed);
    expect(stored.syncError, 'Server indisponibil');
  });

  test('ștergerea călătoriei șterge și punctele', () async {
    await database.insertTrip(trip());
    await database.insertPoint(point('p0', 'trip-1', 0));

    await database.deleteTrip('trip-1');

    expect(await database.getTrip('trip-1'), isNull);
    expect(await database.getPoints('trip-1'), isEmpty);
  });

  test('datele persistă după redeschiderea bazei', () async {
    final directory = Directory.systemTemp.createTempSync('car_tracker_test');
    final path = p.join(directory.path, 'persist.db');

    final first = await AppDatabase.open(path: path);
    await first.insertTrip(trip());
    await first.close();

    final second = await AppDatabase.open(path: path);
    final stored = await second.getTrip('trip-1');
    await second.close();
    directory.deleteSync(recursive: true);

    expect(stored, isNotNull);
    expect(stored!.status, TripStatus.active);
  });
}
