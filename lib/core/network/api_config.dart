/// Build-time network configuration.
///
/// Supplied via `--dart-define` so nothing environment-specific is committed
/// and per-flavour builds work without a code change
/// (`03-flutter-security-guard.md`):
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://api.your-host.com
/// ```
abstract final class ApiConfig {
  /// Placeholder default — replace via `--dart-define` per environment.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}
