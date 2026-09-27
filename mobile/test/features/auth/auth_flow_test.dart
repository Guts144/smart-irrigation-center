import 'package:aquasense_mobile/core/network/api_exception.dart';
import 'package:aquasense_mobile/features/auth/application/auth_controller.dart';
import 'package:aquasense_mobile/features/auth/data/auth_repository.dart';
import 'package:aquasense_mobile/features/auth/data/user.dart';
import 'package:aquasense_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  final farmer = User.fromJson(userJson());

  setUp(() => repo = MockAuthRepository());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
      ],
      child: const AquaSenseApp(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('splash stays visible for 4 seconds before going home', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => farmer);
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const AquaSenseApp(),
    ));

    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Welcome, Test Farmer'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Test Farmer'), findsOneWidget);
  });

  testWidgets('no stored session shows the login screen', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => null);
    await pumpApp(tester);

    expect(find.text('Sign in'), findsWidgets);
    expect(find.byKey(const Key('login-email')), findsOneWidget);
  });

  testWidgets('stored session goes straight to home', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => farmer);
    await pumpApp(tester);

    expect(find.text('Welcome, Test Farmer'), findsOneWidget);
    expect(find.text('Free plan'), findsOneWidget);
  });

  testWidgets('offline restore offers a retry', (tester) async {
    var calls = 0;
    when(() => repo.restoreSession()).thenAnswer((_) async {
      if (calls++ == 0) throw const ApiException('Cannot reach the AquaSense server. Check your connection.');
      return farmer;
    });
    await pumpApp(tester);

    expect(find.textContaining('Cannot reach'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Test Farmer'), findsOneWidget);
  });

  testWidgets('login validates, shows server errors, then signs in', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => null);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    verifyNever(() => repo.login(email: any(named: 'email'), password: any(named: 'password')));

    when(() => repo.login(email: any(named: 'email'), password: 'wrong'))
        .thenThrow(const ApiException('Invalid email or password', statusCode: 401));
    await tester.enterText(find.byKey(const Key('login-email')), 'farmer@aquasense.io');
    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password'), findsOneWidget);

    when(() => repo.login(email: any(named: 'email'), password: 'secret123')).thenAnswer((_) async => farmer);
    await tester.enterText(find.byKey(const Key('login-password')), 'secret123');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Test Farmer'), findsOneWidget);
  });

  testWidgets('register validates the form and signs the user in', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => null);
    when(() => repo.register(fullName: 'Test Farmer', email: 'farmer@aquasense.io', password: 'secret123'))
        .thenAnswer((_) async => farmer);
    await pumpApp(tester);

    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('register-name')), 'Test Farmer');
    await tester.enterText(find.byKey(const Key('register-email')), 'farmer@aquasense.io');
    await tester.enterText(find.byKey(const Key('register-password')), 'short');
    await tester.enterText(find.byKey(const Key('register-confirm')), 'different');
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register-password')), 'secret123');
    await tester.enterText(find.byKey(const Key('register-confirm')), 'secret123');
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Test Farmer'), findsOneWidget);
  });

  testWidgets('logout returns to login after confirmation', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => farmer);
    when(() => repo.logout()).thenAnswer((_) async {});
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    verify(() => repo.logout()).called(1);
    expect(find.byKey(const Key('login-email')), findsOneWidget);
  });
}
