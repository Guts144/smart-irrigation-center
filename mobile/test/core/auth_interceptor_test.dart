import 'package:aquasense_mobile/core/network/auth_interceptor.dart';
import 'package:aquasense_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemoryTokenStorage storage;
  late int expiredCalls;

  setUp(() {
    storage = InMemoryTokenStorage(const AuthTokens(accessToken: 'old-access', refreshToken: 'refresh-1'));
    expiredCalls = 0;
  });

  Dio buildDio(FakeAdapter adapter) {
    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;
    return Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(
        storage: storage,
        refreshDio: refreshDio,
        onSessionExpired: () => expiredCalls++,
      ));
  }

  test('attaches the bearer token', () async {
    final adapter = FakeAdapter((_) => (status: 200, body: {'ok': true}));
    await buildDio(adapter).get('/api/auth/me');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer old-access');
  });

  test('does not attach a token when skipAuth is set', () async {
    final adapter = FakeAdapter((_) => (status: 200, body: {}));
    await buildDio(adapter).post('/api/auth/mobile/login', options: Options(extra: {AuthInterceptor.skipAuth: true}));

    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('refreshes on 401, saves new tokens and retries the request', () async {
    final adapter = FakeAdapter((o) {
      if (o.path == '/api/auth/mobile/refresh') {
        expect(o.data, {'refreshToken': 'refresh-1'});
        return (status: 200, body: {'user': userJson(), 'accessToken': 'new-access', 'refreshToken': 'refresh-2', 'expiresIn': 900});
      }
      final auth = o.headers['Authorization'];
      return auth == 'Bearer new-access' ? (status: 200, body: userJson()) : (status: 401, body: null);
    });

    final response = await buildDio(adapter).get<Map<String, dynamic>>('/api/auth/me');

    expect(response.data!['email'], 'farmer@aquasense.io');
    expect(adapter.requests.map((r) => r.path), ['/api/auth/me', '/api/auth/mobile/refresh', '/api/auth/me']);
    expect(storage.tokens!.accessToken, 'new-access');
    expect(storage.tokens!.refreshToken, 'refresh-2');
    expect(expiredCalls, 0);
  });

  test('concurrent 401s trigger only one refresh', () async {
    var refreshes = 0;
    final adapter = FakeAdapter((o) {
      if (o.path == '/api/auth/mobile/refresh') {
        refreshes++;
        return (status: 200, body: {'user': userJson(), 'accessToken': 'new-access', 'refreshToken': 'refresh-2', 'expiresIn': 900});
      }
      return o.headers['Authorization'] == 'Bearer new-access' ? (status: 200, body: {}) : (status: 401, body: null);
    });
    final dio = buildDio(adapter);

    await Future.wait([dio.get('/api/pro/sensors'), dio.get('/api/pro/connection'), dio.get('/api/auth/me')]);

    expect(refreshes, 1);
  });

  test('clears tokens and reports expiry when the refresh token is rejected', () async {
    final adapter = FakeAdapter((o) => (status: 401, body: {'detail': 'Invalid refresh token'}));

    await expectLater(
      buildDio(adapter).get('/api/auth/me'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(storage.tokens, isNull);
    expect(expiredCalls, 1);
  });

  test('keeps tokens when refresh fails for a non-auth reason', () async {
    final adapter = FakeAdapter((o) => o.path == '/api/auth/mobile/refresh'
        ? (status: 503, body: {'detail': 'down'})
        : (status: 401, body: null));

    await expectLater(buildDio(adapter).get('/api/auth/me'), throwsA(isA<DioException>()));
    expect(storage.tokens, isNotNull);
    expect(expiredCalls, 0);
  });

  test('passes through non-401 errors untouched', () async {
    final adapter = FakeAdapter((_) => (status: 402, body: {'detail': 'Pro subscription required'}));

    await expectLater(
      buildDio(adapter).get('/api/pro/sensors'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 402)),
    );
    expect(adapter.requests, hasLength(1));
  });
}
