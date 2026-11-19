/// Formatare pentru afișare; calculele rămân în metri și m/s.
String formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.round()} m';
}

String formatSpeed(double metersPerSecond) {
  return '${(metersPerSecond * 3.6).toStringAsFixed(0)} km/h';
}

String formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final secs = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${_two(minutes)}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${_two(secs)}s';
  }
  return '${secs}s';
}

String formatClock(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  return '${_two(safe.inHours)}:${_two(safe.inMinutes.remainder(60))}:'
      '${_two(safe.inSeconds.remainder(60))}';
}

String formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.day)}.${_two(local.month)}.${local.year} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
