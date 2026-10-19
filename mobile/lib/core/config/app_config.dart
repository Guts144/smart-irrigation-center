import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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
    if (kIsWeb) return 'http://localhost:8081';
    return Platform.isAndroid ? 'http://10.0.2.2:8081' : 'http://localhost:8081';
  }

  static String get wsUrl {
    final base = apiBaseUrl;
    return '${base.replaceFirst('http', 'ws')}/ws';
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
