import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches `Authorization: Bearer <access token>` and transparently refreshes
/// the access token (15 min lifetime) once when the backend answers 401.
///
/// Extends [QueuedInterceptor] so that when several requests fail with 401 at
/// the same time only the first one refreshes; the others see the new token
/// and simply retry.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage storage,
    required Dio refreshDio,
    required void Function() onSessionExpired,
  })  : _storage = storage,
        _refreshDio = refreshDio,
        _onSessionExpired = onSessionExpired;

  /// Set `options.extra[skipAuth] = true` on requests that must not carry or
  /// refresh a token (login, register, refresh itself).
  static const skipAuth = 'skipAuth';
  static const _retried = 'authRetried';

  final TokenStorage _storage;
  final Dio _refreshDio;
  final void Function() _onSessionExpired;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[skipAuth] != true) {
      final tokens = await _storage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized || options.extra[skipAuth] == true || options.extra[_retried] == true) {
      return handler.next(err);
    }

    final tokens = await _storage.read();
    if (tokens == null) {
      _onSessionExpired();
      return handler.next(err);
    }

    try {
      var accessToken = tokens.accessToken;
      final usedToken = (options.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');

      // Another queued request may already have refreshed while we waited.
      if (usedToken == accessToken) {
        final response = await _refreshDio.post<Map<String, dynamic>>(
          '/api/auth/mobile/refresh',
          data: {'refreshToken': tokens.refreshToken},
        );
        final body = response.data!;
        accessToken = body['accessToken'] as String;
        await _storage.save(AuthTokens(
          accessToken: accessToken,
          refreshToken: body['refreshToken'] as String,
        ));
      }

      options.headers['Authorization'] = 'Bearer $accessToken';
      options.extra[_retried] = true;
      handler.resolve(await _refreshDio.fetch(options));
    } on DioException catch (refreshError) {
      if (refreshError.response?.statusCode == 401) {
        await _storage.clear();
        _onSessionExpired();
        return handler.next(err);
      }
      // Network failure during refresh/retry: keep the tokens, surface the error.
      handler.next(refreshError);
    }
  }
}
