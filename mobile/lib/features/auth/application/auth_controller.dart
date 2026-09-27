import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/session_events.dart';
import '../data/auth_repository.dart';
import '../data/user.dart';

sealed class AuthState {
  const AuthState();
}

/// Checking stored tokens on app start.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

/// Stored tokens exist but the server could not be reached.
class AuthRestoreFailed extends AuthState {
  const AuthRestoreFailed(this.message);
  final String message;
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.sessionExpired = false});

  /// True when the user was signed out because their session ran out.
  final bool sessionExpired;
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final User user;
}

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final sub = ref.watch(sessionEventsProvider).expired.listen((_) {
      if (state is Authenticated) state = const Unauthenticated(sessionExpired: true);
    });
    ref.onDispose(sub.cancel);

    Future.microtask(() => restore(minDuration: ref.read(splashMinDurationProvider)));
    return const AuthRestoring();
  }

  /// Checks the stored session. [minDuration] keeps the splash screen visible
  /// at least that long; the session check runs in parallel with it.
  Future<void> restore({Duration minDuration = Duration.zero}) async {
    state = const AuthRestoring();
    final minDelay = Future<void>.delayed(minDuration);
    AuthState next;
    try {
      final user = await _repository.restoreSession();
      next = user == null ? const Unauthenticated() : Authenticated(user);
    } on ApiException catch (e) {
      next = AuthRestoreFailed(e.message);
    }
    await minDelay;
    state = next;
  }

  /// Throws [ApiException] so the form can show the message.
  Future<void> login({required String email, required String password}) async {
    final user = await _repository.login(email: email, password: password);
    state = Authenticated(user);
  }

  /// Throws [ApiException] so the form can show the message.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = await _repository.register(fullName: fullName, email: email, password: password);
    state = Authenticated(user);
  }

  /// Re-reads the user from the server (e.g. after a subscription change).
  Future<void> refreshUser() async {
    final user = await _repository.me();
    state = Authenticated(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const Unauthenticated();
  }
}

/// How long the splash screen stays up at launch. Overridden to zero in tests.
final splashMinDurationProvider = Provider<Duration>((ref) => const Duration(seconds: 4));

final authControllerProvider =NotifierProvider<AuthController, AuthState>(AuthController.new);
