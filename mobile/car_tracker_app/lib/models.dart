enum TripStatus {
  active,
  completed,
  cancelled,
  interrupted;

  static TripStatus fromDb(String value) => TripStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => TripStatus.interrupted,
      );
}

enum SyncState {
  pending,
  syncing,
  synced,
  failed;

  static SyncState fromDb(String value) => SyncState.values.firstWhere(
        (state) => state.name == value,
        orElse: () => SyncState.pending,
      );
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
  });

  final int id;
  final String email;
  final String role;

  bool get isAdmin => role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'email': email,
        'role': role,
      };
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

/// Călătorie stocată local. Distanța este în metri, viteza în m/s.
class Trip {
  const Trip({
    required this.id,
    required this.startedAt,
    required this.status,
    this.ownerEmail = '',
    this.endedAt,
    this.distanceMeters = 0,
    this.averageSpeedMps = 0,
    this.maxSpeedMps = 0,
    this.movingDurationSeconds = 0,
    this.totalDurationSeconds = 0,
    this.syncState = SyncState.pending,
    this.syncError,
  });

  final String id;
  final DateTime startedAt;
  final String ownerEmail;
  final DateTime? endedAt;
  final TripStatus status;
  final double distanceMeters;
  final double averageSpeedMps;
  final double maxSpeedMps;
  final int movingDurationSeconds;
  final int totalDurationSeconds;
  final SyncState syncState;
  final String? syncError;

  Trip complete({
    required DateTime endedAt,
    required double distanceMeters,
    required double averageSpeedMps,
    required double maxSpeedMps,
    required int movingDurationSeconds,
    required int totalDurationSeconds,
  }) {
    return Trip(
      id: id,
      startedAt: startedAt,
      ownerEmail: ownerEmail,
      endedAt: endedAt,
      status: TripStatus.completed,
      distanceMeters: distanceMeters,
      averageSpeedMps: averageSpeedMps,
      maxSpeedMps: maxSpeedMps,
      movingDurationSeconds: movingDurationSeconds,
      totalDurationSeconds: totalDurationSeconds,
      syncState: SyncState.pending,
    );
  }

  Trip withStatus(TripStatus newStatus, {DateTime? endedAt}) {
    return Trip(
      id: id,
      startedAt: startedAt,
      ownerEmail: ownerEmail,
      endedAt: endedAt ?? this.endedAt,
      status: newStatus,
      distanceMeters: distanceMeters,
      averageSpeedMps: averageSpeedMps,
      maxSpeedMps: maxSpeedMps,
      movingDurationSeconds: movingDurationSeconds,
      totalDurationSeconds: totalDurationSeconds,
      syncState: syncState,
      syncError: syncError,
    );
  }

  Trip withSyncState(SyncState state, {String? error}) {
    return Trip(
      id: id,
      startedAt: startedAt,
      ownerEmail: ownerEmail,
      endedAt: endedAt,
      status: status,
      distanceMeters: distanceMeters,
      averageSpeedMps: averageSpeedMps,
      maxSpeedMps: maxSpeedMps,
      movingDurationSeconds: movingDurationSeconds,
      totalDurationSeconds: totalDurationSeconds,
      syncState: state,
      syncError: error,
    );
  }

  factory Trip.fromMap(Map<String, Object?> map) {
    return Trip(
      id: map['id'] as String,
      startedAt: DateTime.parse(map['started_at'] as String).toUtc(),
      ownerEmail: (map['owner_email'] as String?) ?? '',
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.parse(map['ended_at'] as String).toUtc(),
      status: TripStatus.fromDb(map['status'] as String),
      distanceMeters: (map['distance_meters'] as num).toDouble(),
      averageSpeedMps: (map['average_speed_mps'] as num).toDouble(),
      maxSpeedMps: (map['max_speed_mps'] as num).toDouble(),
      movingDurationSeconds:
          (map['moving_duration_seconds'] as num).toInt(),
      totalDurationSeconds:
          (map['total_duration_seconds'] as num).toInt(),
      syncState: SyncState.fromDb(map['sync_state'] as String),
      syncError: map['sync_error'] as String?,
    );
  }

  /// Călătorie venită din API-ul de administrare (include proprietarul).
  factory Trip.fromApi(Map<String, dynamic> json) {
    final endedAt = json['ended_at'] as String?;
    return Trip(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String).toUtc(),
      ownerEmail: (json['user_email'] as String?) ?? '',
      endedAt: endedAt == null ? null : DateTime.parse(endedAt).toUtc(),
      status: TripStatus.fromDb(json['status'] as String),
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      averageSpeedMps: (json['average_speed_mps'] as num).toDouble(),
      maxSpeedMps: (json['max_speed_mps'] as num).toDouble(),
      movingDurationSeconds:
          (json['moving_duration_seconds'] as num).toInt(),
      totalDurationSeconds:
          (json['total_duration_seconds'] as num).toInt(),
      syncState: SyncState.synced,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'started_at': startedAt.toUtc().toIso8601String(),
      'owner_email': ownerEmail,
      'ended_at': endedAt?.toUtc().toIso8601String(),
      'status': status.name,
      'distance_meters': distanceMeters,
      'average_speed_mps': averageSpeedMps,
      'max_speed_mps': maxSpeedMps,
      'moving_duration_seconds': movingDurationSeconds,
      'total_duration_seconds': totalDurationSeconds,
      'sync_state': syncState.name,
      'sync_error': syncError,
    };
  }
}

/// Punct GPS stocat local. `isValid` marchează punctele acceptate la calcule.
class GpsPoint {
  const GpsPoint({
    required this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.sequenceNumber,
    this.speedMps,
    this.accuracyMeters,
    this.altitudeMeters,
    this.isValid = true,
  });

  final String id;
  final String tripId;
  final double latitude;
  final double longitude;
  final double? speedMps;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final DateTime recordedAt;
  final int sequenceNumber;
  final bool isValid;

  /// Punct venit din API-ul de administrare.
  factory GpsPoint.fromApi(
    Map<String, dynamic> json, {
    required String tripId,
  }) {
    return GpsPoint(
      id: json['id'] as String,
      tripId: tripId,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedMps: (json['speed_mps'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
      altitudeMeters: (json['altitude_meters'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String).toUtc(),
      sequenceNumber: (json['sequence_number'] as num).toInt(),
    );
  }

  factory GpsPoint.fromMap(Map<String, Object?> map) {
    return GpsPoint(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speedMps: (map['speed_mps'] as num?)?.toDouble(),
      accuracyMeters: (map['accuracy_meters'] as num?)?.toDouble(),
      altitudeMeters: (map['altitude_meters'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String).toUtc(),
      sequenceNumber: map['sequence_number'] as int,
      isValid: (map['is_valid'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_mps': speedMps,
      'accuracy_meters': accuracyMeters,
      'altitude_meters': altitudeMeters,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      'sequence_number': sequenceNumber,
      'is_valid': isValid ? 1 : 0,
    };
  }
}
