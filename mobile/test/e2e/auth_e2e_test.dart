/// End-to-end auth check against a running backend (dev profile on :8081).
///
/// Skipped by default. Run with:
///   ./backend/run-dev.sh
///   cd mobile && flutter test test/e2e --dart-define=E2E=true
library;

import 'package:aquasense_mobile/core/network/api_exception.dart';
import 'package:aquasense_mobile/core/network/auth_interceptor.dart';
import 'package:aquasense_mobile/core/storage/token_storage.dart';
import 'package:aquasense_mobile/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

const _enabled = bool.fromEnvironment('E2E');
const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8081');

void main() {
  late InMemoryTokenStorage storage;
  late AuthRepository repo;
  var expired = 0;

  setUp(() {
    storage = InMemoryTokenStorage();
    final dio = Dio(BaseOptions(baseUrl: _baseUrl, contentType: Headers.jsonContentType));
    dio.interceptors.add(AuthInterceptor(
      storage: storage,
      refreshDio: Dio(BaseOptions(baseUrl: _baseUrl, contentType: Headers.jsonContentType)),
      onSessionExpired: () => expired++,
    ));
    repo = AuthRepository(dio, storage);
  });

  test('register, login, me, refresh and logout', () async {
    final email = 'e2e-${DateTime.now().millisecondsSinceEpoch}@aquasense.io';

    final registered = await repo.register(fullName: 'E2E Farmer', email: email, password: 'secret123');
    expect(registered.email, email);
    expect(registered.hasProAccess, isFalse);
    expect(storage.tokens, isNotNull);

    await expectLater(
      repo.register(fullName: 'E2E Farmer', email: email, password: 'secret123'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );

    await expectLater(
      repo.login(email: email, password: 'wrong-password'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'status', 401)
          .having((e) => e.message, 'message', 'Invalid email or password')),
    );

    // Corrupt the access token: the interceptor must refresh and retry.
    storage.tokens = AuthTokens(accessToken: 'expired', refreshToken: storage.tokens!.refreshToken);
    final me = await repo.me();
    expect(me.email, email);
    expect(storage.tokens!.accessToken, isNot('expired'));

    // Bad refresh token: session expires and restore reports no user.
    storage.tokens = const AuthTokens(accessToken: 'expired', refreshToken: 'bad');
    expect(await repo.restoreSession(), isNull);
    expect(storage.tokens, isNull);
    expect(expired, 1);

    final admin = await repo.login(email: 'admin@aquasense.io', password: 'admin123');
    expect(admin.hasProAccess, isTrue);
    expect(await repo.restoreSession(), isNotNull);

    await repo.logout();
    expect(await repo.restoreSession(), isNull);
  }, skip: _enabled ? false : 'Needs a running backend: --dart-define=E2E=true');
}
