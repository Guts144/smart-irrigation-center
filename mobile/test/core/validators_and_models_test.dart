import 'package:aquasense_mobile/core/network/api_exception.dart';
import 'package:aquasense_mobile/core/router/app_router.dart';
import 'package:aquasense_mobile/core/validation/validators.dart';
import 'package:aquasense_mobile/features/auth/application/auth_controller.dart';
import 'package:aquasense_mobile/features/auth/data/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
      expect(Validators.email(' farmer@aquasense.io '), isNull);
      expect(Validators.email('${'a' * 76}@x.io', maxLength: 80), isNotNull);
      expect(Validators.email('${'a' * 75}@x.io', maxLength: 80), isNull);
    });

    test('newPassword matches backend @Size(min = 8, max = 100)', () {
      expect(Validators.newPassword('1234567'), 'Password must be at least 8 characters');
      expect(Validators.newPassword('12345678'), isNull);
      expect(Validators.newPassword('a' * 101), isNotNull);
    });

    test('fullName and confirmPassword', () {
      expect(Validators.fullName('   '), 'Full name is required');
      expect(Validators.fullName('a' * 101), isNotNull);
      expect(Validators.confirmPassword('abc', 'abd'), 'Passwords do not match');
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
    });
  });

  group('User', () {
    test('parses UserResponse', () {
      final user = User.fromJson(userJson(pro: true));
      expect(user.id, 7);
      expect(user.subscriptionStatus, 'ACTIVE');
      expect(user.hasProAccess, isTrue);
    });

    test('admins have Pro access without a subscription', () {
      expect(User.fromJson(userJson(role: 'ADMIN')).hasProAccess, isTrue);
      expect(User.fromJson(userJson()).hasProAccess, isFalse);
    });
  });

  group('ApiException.fromDio', () {
    DioException withResponse(int status, Object? data) {
      final options = RequestOptions(path: '/x');
      return DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: status, data: data),
        type: DioExceptionType.badResponse,
      );
    }

    test('uses the ProblemDetail detail message', () {
      final e = ApiException.fromDio(withResponse(409, {'title': 'Conflict', 'detail': 'Email already registered'}));
      expect(e.message, 'Email already registered');
      expect(e.isConflict, isTrue);
    });

    test('falls back to a generic message per status', () {
      expect(ApiException.fromDio(withResponse(402, '')).message, 'A Pro subscription is required.');
    });

    test('reports unreachable server', () {
      final e = ApiException.fromDio(
        DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError),
      );
      expect(e.message, contains('Cannot reach'));
    });
  });

  group('authRedirect', () {
    final signedIn = Authenticated(User.fromJson(userJson()));

    test('holds on splash while restoring', () {
      expect(authRedirect(const AuthRestoring(), Routes.home), Routes.splash);
      expect(authRedirect(const AuthRestoring(), Routes.splash), isNull);
      expect(authRedirect(const AuthRestoreFailed('offline'), Routes.login), Routes.splash);
    });

    test('guests can only see login and register', () {
      expect(authRedirect(const Unauthenticated(), Routes.home), Routes.login);
      expect(authRedirect(const Unauthenticated(), Routes.splash), Routes.login);
      expect(authRedirect(const Unauthenticated(), Routes.register), isNull);
    });

    test('signed-in users skip auth screens', () {
      expect(authRedirect(signedIn, Routes.login), Routes.home);
      expect(authRedirect(signedIn, Routes.splash), Routes.home);
      expect(authRedirect(signedIn, Routes.home), isNull);
    });
  });
}
