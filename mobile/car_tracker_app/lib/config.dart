/// Setări care pot fi modificate fără a rescrie logica aplicației.
class AppConfig {
  AppConfig._();

  /// Adresa API-ului, configurabilă la build:
  /// `--dart-define=API_BASE_URL=http://<host>:8000/api/v1`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// GPS-06: actualizare la cel mult 5 secunde sau 10 metri.
  static const Duration locationInterval = Duration(seconds: 5);
  static const int locationDistanceFilterMeters = 10;

  /// Punctele se trimit în loturi (CLAUDE.md, secțiunea 4).
  static const int syncBatchSize = 200;
}
