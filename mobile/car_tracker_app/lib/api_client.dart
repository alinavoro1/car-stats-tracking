import 'dart:math' as math;

import 'package:dio/dio.dart';

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

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
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  String? _token;

  /// Apelat când serverul răspunde cu 401 (sesiune expirată).
  void Function()? onUnauthorized;

  void setToken(String? token) {
    _token = token;
  }

  bool get hasToken => _token != null;

  Future<void> checkHealth() async {
    try {
      final response = await _dio.get<Object>('/health');
      final data = response.data;
      if (data is Map && data['status'] == 'ok') {
        return;
      }
      throw const ApiException('Răspuns neașteptat de la server.');
    } on DioException catch (error) {
      throw ApiException(
        _describeError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<AuthUser> register(String email, String password) async {
    try {
      final response = await _dio.post<Object>(
        '/auth/register',
        data: {'email': email, 'password': password},
      );
      return AuthUser.fromJson(
        _jsonMap(response.data, 'Răspuns neașteptat la înregistrare.'),
      );
    } on DioException catch (error) {
      throw ApiException(
        _describeError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<AuthSession> login(String email, String password) async {
    try {
      final response = await _dio.post<Object>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = _jsonMap(
        response.data,
        'Răspuns neașteptat la autentificare.',
      );
      final token = data['access_token'];
      final user = data['user'];
      if (token is! String || user is! Map) {
        throw const ApiException('Răspuns neașteptat la autentificare.');
      }
      return AuthSession(
        token: token,
        user: AuthUser.fromJson(Map<String, dynamic>.from(user)),
      );
    } on DioException catch (error) {
      throw ApiException(
        _describeError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<AuthUser> fetchMe() async {
    try {
      final response = await _dio.get<Object>('/auth/me');
      return AuthUser.fromJson(
        _jsonMap(response.data, 'Răspuns neașteptat de la server.'),
      );
    } on DioException catch (error) {
      throw ApiException(
        _describeError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Map<String, dynamic> _jsonMap(Object? data, String message) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw ApiException(message);
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
      throw ApiException(
        _describeError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// ADMIN-02: toate călătoriile, pentru rolul admin.
  Future<List<Trip>> fetchAdminTrips() async {
    try {
      final response = await _dio.get<Object>('/admin/trips');
      final data = response.data;
      if (data is! List) {
        throw const ApiException('Răspuns neașteptat de la server.');
      }
      return data
          .whereType<Map>()
          .map((json) => Trip.fromApi(Map<String, dynamic>.from(json)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException(
        _describeError(error),
        statusCode: error.response?.statusCode,
      );
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
          return data['detail'] as String;
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
