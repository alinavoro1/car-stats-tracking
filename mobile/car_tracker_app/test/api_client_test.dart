import 'dart:convert';
import 'dart:typed_data';

import 'package:car_tracker_app/api_client.dart';
import 'package:car_tracker_app/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.statusCode = 200, this.body = '{"status":"ok"}'});

  final int statusCode;
  final String body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientWith(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'));
  dio.httpClientAdapter = adapter;
  return ApiClient(dio: dio);
}

Trip completedTrip() {
  final startedAt = DateTime.utc(2026, 1, 1, 12);
  return Trip(
    id: 'trip-1',
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 10)),
    status: TripStatus.completed,
    distanceMeters: 5000,
    averageSpeedMps: 12,
    maxSpeedMps: 20,
    movingDurationSeconds: 400,
    totalDurationSeconds: 600,
  );
}

List<GpsPoint> points(int count) {
  final start = DateTime.utc(2026, 1, 1, 12);
  return List.generate(
    count,
    (index) => GpsPoint(
      id: 'point-$index',
      tripId: 'trip-1',
      latitude: 44.0 + index * 0.00001,
      longitude: 26.0,
      recordedAt: start.add(Duration(seconds: index * 5)),
      sequenceNumber: index,
      speedMps: 10,
      accuracyMeters: 5,
    ),
  );
}

void main() {
  test('health acceptă răspunsul serverului', () async {
    final adapter = _RecordingAdapter();
    await _clientWith(adapter).checkHealth();
    expect(adapter.requests.single.path, '/health');
  });

  test('sincronizarea trimite metadate, loturi și finalizarea', () async {
    final adapter = _RecordingAdapter();
    await _clientWith(adapter).syncTrip(completedTrip(), points(250));

    expect(adapter.requests.length, 4);
    expect(adapter.requests[0].path, '/trips');
    expect(adapter.requests[1].path, '/trips/trip-1/points/batch');
    expect(adapter.requests[2].path, '/trips/trip-1/points/batch');
    expect(adapter.requests[3].path, '/trips/trip-1/complete');

    final firstBatch = adapter.requests[1].data as Map<String, dynamic>;
    final secondBatch = adapter.requests[2].data as Map<String, dynamic>;
    expect((firstBatch['points'] as List).length, 200);
    expect((secondBatch['points'] as List).length, 50);

    final firstPoint = (firstBatch['points'] as List).first as Map;
    expect(firstPoint['id'], 'point-0');
    expect(firstPoint['sequence_number'], 0);
    expect(firstPoint['recorded_at'], contains('Z'));

    final completion = adapter.requests[3].data as Map<String, dynamic>;
    expect(completion['distance_meters'], 5000);
    expect(completion['average_speed_mps'], 12);
  });

  test('eroarea de la server este raportată clar', () async {
    final adapter = _RecordingAdapter(
      statusCode: 409,
      body: '{"detail":"Există deja o călătorie activă."}',
    );

    expect(
      () => _clientWith(adapter).checkHealth(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('Există deja o călătorie activă.'),
        ),
      ),
    );
  });

  test('răspunsul de health invalid este respins', () async {
    final adapter = _RecordingAdapter(body: jsonEncode({'status': 'down'}));
    expect(
      () => _clientWith(adapter).checkHealth(),
      throwsA(isA<ApiException>()),
    );
  });

  test('login returnează tokenul și utilizatorul', () async {
    final adapter = _RecordingAdapter(
      body: jsonEncode({
        'access_token': 'token-123',
        'token_type': 'bearer',
        'user': {'id': 7, 'email': 'admin@example.com', 'role': 'admin'},
      }),
    );

    final session = await _clientWith(adapter).login(
      'admin@example.com',
      'parola12345',
    );

    expect(adapter.requests.single.path, '/auth/login');
    expect(session.token, 'token-123');
    expect(session.user.email, 'admin@example.com');
    expect(session.user.isAdmin, isTrue);
  });

  test('register parsează utilizatorul creat', () async {
    final adapter = _RecordingAdapter(
      body: jsonEncode({
        'id': 3,
        'email': 'u@example.com',
        'role': 'user',
      }),
    );

    final user = await _clientWith(adapter).register(
      'u@example.com',
      'parola12345',
    );

    expect(adapter.requests.single.path, '/auth/register');
    expect(user.email, 'u@example.com');
    expect(user.isAdmin, isFalse);
  });

  test('fetchAdminTrips parsează călătoriile cu proprietar', () async {
    final adapter = _RecordingAdapter(
      body: jsonEncode([
        {
          'id': 'trip-9',
          'started_at': '2026-01-01T12:00:00Z',
          'ended_at': '2026-01-01T12:30:00Z',
          'status': 'completed',
          'distance_meters': 1234.0,
          'average_speed_mps': 10.0,
          'max_speed_mps': 20.0,
          'moving_duration_seconds': 900,
          'total_duration_seconds': 1800,
          'user_email': 'other@example.com',
        }
      ]),
    );

    final trips = await _clientWith(adapter).fetchAdminTrips();

    expect(adapter.requests.single.path, '/admin/trips');
    expect(trips.single.id, 'trip-9');
    expect(trips.single.ownerEmail, 'other@example.com');
    expect(trips.single.status, TripStatus.completed);
  });

  test('fetchAdminTripPoints parsează punctele', () async {
    final adapter = _RecordingAdapter(
      body: jsonEncode([
        {
          'id': 'p1',
          'latitude': 44.0,
          'longitude': 26.0,
          'speed_mps': 10.0,
          'accuracy_meters': 5.0,
          'altitude_meters': 90.0,
          'recorded_at': '2026-01-01T12:00:00Z',
          'sequence_number': 0,
        }
      ]),
    );

    final points = await _clientWith(adapter)
        .fetchAdminTripPoints('trip-9');

    expect(
      adapter.requests.single.path,
      '/admin/trips/trip-9/points',
    );
    expect(points.single.tripId, 'trip-9');
    expect(points.single.sequenceNumber, 0);
  });

  test('tokenul este trimis ca Bearer', () async {
    final adapter = _RecordingAdapter(
      body: jsonEncode({'id': 1, 'email': 'a@example.com', 'role': 'user'}),
    );
    final api = _clientWith(adapter);
    api.setToken('abc');

    await api.fetchMe();

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer abc',
    );
  });
}
