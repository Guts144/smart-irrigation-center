import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/home_screen.dart';

class Routes {
  Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
}

/// Pure redirect rules, kept separate so they can be unit tested.
String? authRedirect(AuthState auth, String location) {
  const guestOnly = {Routes.login, Routes.register};

  return switch (auth) {
    AuthRestoring() || AuthRestoreFailed() => location == Routes.splash ? null : Routes.splash,
    Unauthenticated() => guestOnly.contains(location) ? null : Routes.login,
    Authenticated() => (guestOnly.contains(location) || location == Routes.splash) ? Routes.home : null,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bridges Riverpod auth state to GoRouter so redirects re-run on login/logout.
  final authChanges = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref
    ..listen(authControllerProvider, (_, next) => authChanges.value = next)
    ..onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authChanges,
    redirect: (context, state) => authRedirect(authChanges.value, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
    ],
  );
});
