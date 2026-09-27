import 'dart:io' show Platform;

/// Runtime configuration.
///
/// Override the backend URL at build time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8081
class AppConfig {
  AppConfig._();

  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Backend origin without the `/api` suffix.
  ///
  /// Defaults target the dev backend (port 8081). The Android emulator reaches
  /// the host machine through 10.0.2.2; the iOS simulator can use localhost.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return Platform.isAndroid ? 'http://10.0.2.2:8081' : 'http://localhost:8081';
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
