import 'package:car_tracker_app/ui_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatarea distanței folosește metri sub 1 km', () {
    expect(formatDistance(500), '500 m');
    expect(formatDistance(1500), '1.50 km');
  });

  test('viteza este convertită din m/s în km/h', () {
    expect(formatSpeed(10), '36 km/h');
  });

  test('duratele sunt lizibile', () {
    expect(formatDuration(65), '1m 05s');
    expect(formatDuration(3660), '1h 01m');
    expect(formatClock(const Duration(minutes: 1, seconds: 5)), '00:01:05');
  });
}
