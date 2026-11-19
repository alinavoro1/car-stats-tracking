import 'dart:math' as math;

import 'package:dio/dio.dart';

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Comunicația cu backend-ul FastAPI. Adresa vine din [AppConfig].
class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;

  Future<void> checkHealth() async {
    try {
      final response = await _dio.get<Object>('/health');
      final data = response.data;
      if (data is Map && data['status'] == 'ok') {
        return;
      }
      throw const ApiException('Răspuns neașteptat de la server.');
    } on DioException catch (error) {
      throw ApiException(_describeError(error));
    }
  }

  /// Sincronizează o călătorie finalizată: metadate, puncte în loturi,
  /// apoi finalizarea. Retrimiterea este sigură (ID-uri stabile).
  Future<void> syncTrip(Trip trip, List<GpsPoint> points) async {
    final endedAt = trip.endedAt;
    if (endedAt == null) {
      throw const ApiException('Călătoria nu are oră de finalizare.');
    }

    try {
      await _dio.post<Object>(
        '/trips',
        data: {
          'id': trip.id,
          'started_at': trip.startedAt.toUtc().toIso8601String(),
        },
      );

      for (var start = 0; start < points.length; start += AppConfig.syncBatchSize) {
        final end = math.min(start + AppConfig.syncBatchSize, points.length);
        final chunk = points.sublist(start, end);
        await _dio.post<Object>(
          '/trips/${trip.id}/points/batch',
          data: {
            'points': chunk.map(_pointPayload).toList(),
          },
        );
      }

      await _dio.post<Object>(
        '/trips/${trip.id}/complete',
        data: {
          'ended_at': endedAt.toUtc().toIso8601String(),
          'distance_meters': trip.distanceMeters,
          'average_speed_mps': trip.averageSpeedMps,
          'max_speed_mps': trip.maxSpeedMps,
          'moving_duration_seconds': trip.movingDurationSeconds,
          'total_duration_seconds': trip.totalDurationSeconds,
        },
      );
    } on DioException catch (error) {
      throw ApiException(_describeError(error));
    }
  }

  Map<String, Object?> _pointPayload(GpsPoint point) {
    return {
      'id': point.id,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'speed_mps': point.speedMps,
      'accuracy_meters': point.accuracyMeters,
      'altitude_meters': point.altitudeMeters,
      'recorded_at': point.recordedAt.toUtc().toIso8601String(),
      'sequence_number': point.sequenceNumber,
    };
  }

  String _describeError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Serverul nu a răspuns la timp.';
      case DioExceptionType.connectionError:
        return 'Nu există conexiune la server. Verifică internetul și adresa API.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final data = error.response?.data;
        if (data is Map && data['detail'] is String) {
          return 'Eroare $status: ${data['detail']}';
        }
        return 'Serverul a răspuns cu eroarea $status.';
      case DioExceptionType.cancel:
        return 'Cererea a fost anulată.';
      case DioExceptionType.badCertificate:
        return 'Certificatul serverului nu este valid.';
      case DioExceptionType.unknown:
        return 'Conexiunea la server a eșuat.';
    }
  }
}
