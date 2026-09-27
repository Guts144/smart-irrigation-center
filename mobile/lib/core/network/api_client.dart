import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'session_events.dart';

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

/// The Dio instance every feature uses to talk to the AquaSense backend.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final sessionEvents = ref.watch(sessionEventsProvider);

  final dio = Dio(_baseOptions());
  dio.interceptors.add(AuthInterceptor(
    storage: storage,
    // Plain client (no interceptors) for the refresh call and the retry.
    refreshDio: Dio(_baseOptions()),
    onSessionExpired: sessionEvents.notifyExpired,
  ));
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      responseHeader: false,
      // Never log bodies: they contain passwords and tokens.
      requestBody: false,
      responseBody: false,
    ));
  }
  return dio;
});
