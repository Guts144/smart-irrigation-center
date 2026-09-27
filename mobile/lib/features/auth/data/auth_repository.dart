import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/storage/token_storage.dart';
import 'user.dart';

/// Talks to `/api/auth/*` and owns the stored tokens.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  static final _noAuth = Options(extra: {AuthInterceptor.skipAuth: true});

  /// `POST /api/auth/mobile/login` — returns the user and stores both tokens.
  Future<User> login({required String email, required String password}) async {
    final body = await _call(() => _dio.post<Map<String, dynamic>>(
          '/api/auth/mobile/login',
          data: {'email': email.trim(), 'password': password},
          options: _noAuth,
        ));
    await _storage.save(AuthTokens(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
    ));
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  /// `POST /api/auth/register`, then signs in (register itself issues no tokens).
  Future<User> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _call(() => _dio.post<Map<String, dynamic>>(
          '/api/auth/register',
          data: {'fullName': fullName.trim(), 'email': email.trim(), 'password': password},
          options: _noAuth,
        ));
    return login(email: email, password: password);
  }

  /// `GET /api/auth/me` — always returns fresh subscription status.
  Future<User> me() async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/api/auth/me'));
    return User.fromJson(body);
  }

  /// Returns the signed-in user, or `null` when there is no valid session.
  /// Network errors are rethrown so the caller can offer a retry instead of
  /// logging the user out while offline.
  Future<User?> restoreSession() async {
    if (await _storage.read() == null) return null;
    try {
      return await me();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _storage.clear();
        return null;
      }
      rethrow;
    }
  }

  /// JWTs are stateless on the backend, so logging out means forgetting them.
  Future<void> logout() => _storage.clear();

  Future<Map<String, dynamic>> _call(Future<Response<Map<String, dynamic>>> Function() request) async {
    try {
      final response = await request();
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});
