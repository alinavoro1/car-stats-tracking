import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Baza de date locală SQLite (OFF-01). Toate orele sunt stocate în UTC.
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static Future<AppDatabase> open({String? path}) async {
    final databasePath =
        path ?? p.join(await getDatabasesPath(), 'car_tracker.db');
    final db = await openDatabase(
      databasePath,
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        started_at TEXT NOT NULL,
        owner_email TEXT NOT NULL DEFAULT '',
        ended_at TEXT,
        status TEXT NOT NULL,
        distance_meters REAL NOT NULL DEFAULT 0,
        average_speed_mps REAL NOT NULL DEFAULT 0,
        max_speed_mps REAL NOT NULL DEFAULT 0,
        moving_duration_seconds INTEGER NOT NULL DEFAULT 0,
        total_duration_seconds INTEGER NOT NULL DEFAULT 0,
        sync_state TEXT NOT NULL DEFAULT 'pending',
        sync_error TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE points (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed_mps REAL,
        accuracy_meters REAL,
        altitude_meters REAL,
        recorded_at TEXT NOT NULL,
        sequence_number INTEGER NOT NULL,
        is_valid INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
        UNIQUE (trip_id, sequence_number)
      )
    ''');
    await db.execute('CREATE INDEX idx_points_trip ON points(trip_id)');
    await db.execute('CREATE INDEX idx_trips_owner ON trips(owner_email)');
  }

  static Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE trips ADD COLUMN owner_email TEXT NOT NULL DEFAULT ''",
      );
      await db.execute('CREATE INDEX idx_trips_owner ON trips(owner_email)');
    }
  }

  Future<void> insertTrip(Trip trip) async {
    await _db.insert('trips', trip.toMap());
  }

  Future<void> updateTrip(Trip trip) async {
    await _db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<Trip?> getTrip(String id) async {
    final rows = await _db.query('trips', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Trip.fromMap(rows.first);
  }

  Future<Trip?> getActiveTrip(String ownerEmail) async {
    final rows = await _db.query(
      'trips',
      where: 'status = ? AND owner_email = ?',
      whereArgs: [TripStatus.active.name, ownerEmail],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Trip.fromMap(rows.first);
  }

  Future<List<Trip>> getTrips(String ownerEmail) async {
    final rows = await _db.query(
      'trips',
      where: 'owner_email = ?',
      whereArgs: [ownerEmail],
      orderBy: 'started_at DESC',
    );
    return rows.map(Trip.fromMap).toList();
  }

  Future<List<Trip>> getPendingSyncTrips(String ownerEmail) async {
    final rows = await _db.query(
      'trips',
      where: 'status = ? AND sync_state != ? AND owner_email = ?',
      whereArgs: [
        TripStatus.completed.name,
        SyncState.synced.name,
        ownerEmail,
      ],
      orderBy: 'started_at ASC',
    );
    return rows.map(Trip.fromMap).toList();
  }

  /// Călătoriile create înainte de autentificare sunt atribuite primului
  /// cont care se autentifică pe acest dispozitiv.
  Future<void> claimUnownedTrips(String ownerEmail) async {
    await _db.update(
      'trips',
      {'owner_email': ownerEmail},
      where: "owner_email = ''",
    );
  }

  Future<void> updateSyncState(
    String tripId,
    SyncState state, {
    String? error,
  }) async {
    await _db.update(
      'trips',
      {'sync_state': state.name, 'sync_error': error},
      where: 'id = ?',
      whereArgs: [tripId],
    );
  }

  Future<void> deleteTrip(String id) async {
    await _db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertPoint(GpsPoint point) async {
    await _db.insert('points', point.toMap());
  }

  Future<List<GpsPoint>> getPoints(String tripId) async {
    final rows = await _db.query(
      'points',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'sequence_number ASC',
    );
    return rows.map(GpsPoint.fromMap).toList();
  }

  Future<void> close() => _db.close();

  Future<void> markPointsInvalid(List<String> pointIds) async {
    if (pointIds.isEmpty) {
      return;
    }
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final id in pointIds) {
        batch.update(
          'points',
          {'is_valid': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
