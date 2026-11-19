import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'api_client.dart';
import 'database.dart';
import 'location_service.dart';
import 'models.dart';
import 'trip_stats.dart';

class TripStartError {
  const TripStartError(
    this.message, {
    this.openLocationSettings = false,
    this.openAppSettings = false,
  });

  final String message;
  final bool openLocationSettings;
  final bool openAppSettings;
}

/// Starea aplicației și ciclul de viață al călătoriei active.
class TripController extends ChangeNotifier {
  TripController({
    required this.db,
    required this.api,
    required this.ownerEmail,
    LocationService? locationService,
  }) : locationService = locationService ?? LocationService() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((result) => result != ConnectivityResult.none);
      if (online) {
        unawaited(syncPendingTrips());
      }
    });
  }

  final AppDatabase db;
  final ApiClient api;
  final String ownerEmail;
  final LocationService locationService;

  final _uuid = const Uuid();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Position>? _positionSub;
  Future<void> _writeQueue = Future.value();

  Trip? _activeTrip;
  List<GpsPoint> _activePoints = [];
  AnalysisResult? _liveAnalysis;
  List<Trip> _history = [];
  List<Trip> _completedTrips = [];
  int _nextSequence = 0;

  bool _tracking = false;
  bool _starting = false;
  bool _finishing = false;
  bool _syncAllInProgress = false;
  bool _disposed = false;
  final Set<String> _syncingTripIds = {};

  String? _gpsError;
  Position? _lastGpsSample;

  Trip? get activeTrip => _activeTrip;
  List<GpsPoint> get activePoints => List.unmodifiable(_activePoints);
  AnalysisResult? get liveAnalysis => _liveAnalysis;
  List<Trip> get historyTrips => List.unmodifiable(_history);
  List<Trip> get completedTrips => List.unmodifiable(_completedTrips);
  bool get isTracking => _tracking;
  String? get gpsError => _gpsError;
  Position? get lastGpsSample => _lastGpsSample;

  double get totalDistanceMeters => _completedTrips.fold(
        0,
        (total, trip) => total + trip.distanceMeters,
      );

  Trip? get lastTrip =>
      _completedTrips.isEmpty ? null : _completedTrips.first;

  List<Trip> get unsyncedTrips => _completedTrips
      .where((trip) => trip.syncState != SyncState.synced)
      .toList();

  Future<void> initialize() async {
    // Călătoriile create înainte de autentificare aparțin primului cont.
    await db.claimUnownedTrips(ownerEmail);
    final active = await db.getActiveTrip(ownerEmail);
    if (active != null) {
      _activeTrip = active;
      _activePoints = await db.getPoints(active.id);
      _nextSequence =
          _activePoints.isEmpty ? 0 : _activePoints.last.sequenceNumber + 1;
      _liveAnalysis = analyzeTrip(_activePoints, startedAt: active.startedAt);
    }
    await refreshHistory();
    unawaited(syncPendingTrips());
  }

  Future<void> refreshHistory() async {
    final trips = await db.getTrips(ownerEmail);
    _history = trips
        .where((trip) => trip.status != TripStatus.active)
        .toList(growable: false);
    _completedTrips = trips
        .where((trip) => trip.status == TripStatus.completed)
        .toList(growable: false);
    _notify();
  }

  Future<TripStartError?> startTrip() async {
    if (_starting || _activeTrip != null) {
      return const TripStartError('Există deja o călătorie activă.');
    }
    _starting = true;
    try {
      final problem = await _checkTrackingReady();
      if (problem != null) {
        return problem;
      }

      await _requestNotificationPermission();

      final trip = Trip(
        id: _uuid.v4(),
        startedAt: DateTime.now().toUtc(),
        ownerEmail: ownerEmail,
        status: TripStatus.active,
      );
      await db.insertTrip(trip);

      _activeTrip = trip;
      _activePoints = [];
      _nextSequence = 0;
      _gpsError = null;
      _liveAnalysis = analyzeTrip(const [], startedAt: trip.startedAt);
      _startStream();
      _notify();
      return null;
    } finally {
      _starting = false;
    }
  }

  /// Continuă o călătorie rămasă activă după închiderea aplicației.
  Future<TripStartError?> resumeTracking() async {
    if (_activeTrip == null) {
      return const TripStartError('Nu există o călătorie activă.');
    }
    if (_positionSub != null) {
      return null;
    }
    final problem = await _checkTrackingReady();
    if (problem != null) {
      return problem;
    }
    _gpsError = null;
    _startStream();
    _notify();
    return null;
  }

  Future<TripStartError?> _checkTrackingReady() async {
    if (!await locationService.isLocationServiceEnabled()) {
      return const TripStartError(
        'Serviciul de localizare este oprit. Activează GPS-ul telefonului.',
        openLocationSettings: true,
      );
    }

    var permission = await locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await locationService.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const TripStartError(
        'Permisiunea de localizare este refuzată permanent. '
        'Permite accesul din setările aplicației.',
        openAppSettings: true,
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return const TripStartError(
        'Permisiunea de localizare este necesară pentru înregistrare.',
      );
    }
    return null;
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await Permission.notification.request();
    } catch (_) {
      // Notificarea este utilă, dar tracking-ul nu depinde de ea.
    }
  }

  void _startStream() {
    if (_positionSub != null) {
      return;
    }
    _tracking = true;
    _positionSub = locationService.positionStream().listen(
      _onPosition,
      onError: (Object error) {
        _positionSub = null;
        _tracking = false;
        _gpsError =
            'Fluxul GPS s-a oprit. Verifică permisiunile și serviciul de localizare.';
        _notify();
      },
      onDone: () {
        _positionSub = null;
        _tracking = false;
        _notify();
      },
    );
  }

  void _onPosition(Position position) {
    final trip = _activeTrip;
    if (trip == null) {
      return;
    }

    final point = GpsPoint(
      id: _uuid.v4(),
      tripId: trip.id,
      latitude: position.latitude,
      longitude: position.longitude,
      speedMps: position.hasSpeed &&
              position.speed.isFinite &&
              position.speed >= 0
          ? position.speed
          : null,
      accuracyMeters: position.hasAccuracy &&
              position.accuracy.isFinite &&
              position.accuracy >= 0
          ? position.accuracy
          : null,
      altitudeMeters:
          position.hasAltitude && position.altitude.isFinite
              ? position.altitude
              : null,
      recordedAt: position.timestamp.toUtc(),
      sequenceNumber: _nextSequence,
    );
    _nextSequence += 1;
    _activePoints = [..._activePoints, point];
    _liveAnalysis = analyzeTrip(_activePoints, startedAt: trip.startedAt);
    _notify();

    // Scrierea imediată în SQLite (OFF-03), serializată pentru a evita
    // două inserări simultane cu aceeași secvență.
    _writeQueue = _writeQueue.then((_) async {
      try {
        await db.insertPoint(point);
      } catch (_) {
        _gpsError = 'Punctul GPS nu a putut fi salvat local.';
        _notify();
      }
    });
  }

  Future<String?> stopTrip() async {
    if (_finishing) {
      return null;
    }
    final trip = _activeTrip;
    if (trip == null) {
      return 'Nu există o călătorie activă.';
    }
    _finishing = true;
    try {
      await _endStream();
      await _writeQueue;

      final points = await db.getPoints(trip.id);
      final endedAt = DateTime.now().toUtc();
      final analysis = analyzeTrip(
        points,
        startedAt: trip.startedAt,
        endedAt: endedAt,
      );
      await db.markPointsInvalid(analysis.invalidPointIds);

      final completed = trip.complete(
        endedAt: endedAt,
        distanceMeters: analysis.distanceMeters,
        averageSpeedMps: analysis.averageSpeedMps,
        maxSpeedMps: analysis.maxSpeedMps,
        movingDurationSeconds: analysis.movingDurationSeconds,
        totalDurationSeconds: analysis.totalDurationSeconds,
      );
      await db.updateTrip(completed);

      _activeTrip = null;
      _activePoints = [];
      _liveAnalysis = null;
      _gpsError = null;
      _notify();
      await refreshHistory();
      unawaited(syncTrip(completed));
      return null;
    } finally {
      _finishing = false;
    }
  }

  Future<String?> cancelTrip() async {
    if (_finishing) {
      return null;
    }
    final trip = _activeTrip;
    if (trip == null) {
      return 'Nu există o călătorie activă.';
    }
    _finishing = true;
    try {
      await _endStream();
      await _writeQueue;
      await db.updateTrip(
        trip.withStatus(TripStatus.cancelled, endedAt: DateTime.now().toUtc()),
      );
      _activeTrip = null;
      _activePoints = [];
      _liveAnalysis = null;
      _gpsError = null;
      _notify();
      await refreshHistory();
      return null;
    } finally {
      _finishing = false;
    }
  }

  Future<void> _endStream() async {
    final subscription = _positionSub;
    _positionSub = null;
    _tracking = false;
    await subscription?.cancel();
  }

  Future<List<GpsPoint>> loadPoints(String tripId) => db.getPoints(tripId);

  Future<String?> syncTrip(Trip trip) async {
    if (trip.status != TripStatus.completed) {
      return 'Doar călătoriile finalizate pot fi sincronizate.';
    }
    return _syncTrip(trip);
  }

  Future<String?> _syncTrip(Trip trip) async {
    if (_syncingTripIds.contains(trip.id)) {
      return null;
    }
    _syncingTripIds.add(trip.id);
    try {
      final points = await db.getPoints(trip.id);
      final validPoints =
          points.where((point) => point.isValid).toList(growable: false);

      await db.updateSyncState(trip.id, SyncState.syncing);
      _replaceHistoryTrip(trip.withSyncState(SyncState.syncing));
      _notify();

      await api.syncTrip(trip, validPoints);

      await db.updateSyncState(trip.id, SyncState.synced);
      _replaceHistoryTrip(trip.withSyncState(SyncState.synced));
      _notify();
      return null;
    } on ApiException catch (error) {
      await _markSyncFailed(trip, error.message);
      return error.message;
    } catch (_) {
      await _markSyncFailed(trip, 'Sincronizarea a eșuat.');
      return 'Sincronizarea a eșuat.';
    } finally {
      _syncingTripIds.remove(trip.id);
    }
  }

  Future<void> _markSyncFailed(Trip trip, String message) async {
    await db.updateSyncState(trip.id, SyncState.failed, error: message);
    _replaceHistoryTrip(trip.withSyncState(SyncState.failed, error: message));
    _notify();
  }

  Future<String?> syncPendingTrips() async {
    if (_syncAllInProgress) {
      return null;
    }
    final pending = await db.getPendingSyncTrips(ownerEmail);
    if (pending.isEmpty) {
      return null;
    }

    _syncAllInProgress = true;
    String? lastError;
    try {
      for (final trip in pending) {
        final error = await _syncTrip(trip);
        if (error != null) {
          lastError = error;
        }
      }
    } finally {
      _syncAllInProgress = false;
    }
    return lastError;
  }

  void _replaceHistoryTrip(Trip updated) {
    _history = _history
        .map((trip) => trip.id == updated.id ? updated : trip)
        .toList(growable: false);
    _completedTrips = _completedTrips
        .map((trip) => trip.id == updated.id ? updated : trip)
        .toList(growable: false);
  }

  Future<String?> checkBackend() async {
    try {
      await api.checkHealth();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// GPS-03: verifică o singură poziție, pentru diagnostic.
  Future<String?> checkGps() async {
    if (!await locationService.isLocationServiceEnabled()) {
      return 'Serviciul de localizare este oprit.';
    }
    var permission = await locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await locationService.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return 'Permisiunea de localizare nu este acordată.';
    }

    final position = await locationService.getCurrentPosition();
    if (position == null) {
      return 'Poziția curentă nu a putut fi obținută.';
    }
    _lastGpsSample = position;
    _notify();
    return null;
  }

  Future<bool> openAppSettings() => locationService.openAppSettings();

  Future<bool> openLocationSettings() =>
      locationService.openLocationSettings();

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final connectivity = _connectivitySubscription;
    final position = _positionSub;
    _connectivitySubscription = null;
    _positionSub = null;
    if (connectivity != null) {
      unawaited(connectivity.cancel());
    }
    if (position != null) {
      unawaited(position.cancel());
    }
    super.dispose();
  }
}
