import 'dart:convert';
import 'dart:typed_data';

import 'package:aquasense_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// In-memory replacement for the Keychain/Keystore-backed storage.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}

typedef FakeHandler = ({int status, Object? body}) Function(RequestOptions options);

/// Dio adapter that answers requests from a handler and records them.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final FakeHandler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final result = handler(options);
    return ResponseBody.fromString(
      result.body == null ? '' : jsonEncode(result.body),
      result.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> userJson({bool pro = false, String role = 'USER'}) => {
      'id': 7,
      'email': 'farmer@aquasense.io',
      'fullName': 'Test Farmer',
      'role': role,
      'subscriptionStatus': pro ? 'ACTIVE' : 'NONE',
      'pro': pro,
    };
