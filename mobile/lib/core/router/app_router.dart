import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/main_tab_screen.dart';
import '../../features/public/presentation/contact_screen.dart';
import '../../features/public/presentation/pricing_screen.dart';
import '../../features/public/presentation/welcome_screen.dart';
import '../../features/subscription/checkout_success_screen.dart';
import '../../features/tracking/presentation/technician_screen.dart';

class Routes {
  Routes._();

  static const root = '/';
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const pricing = '/pricing';
  static const contact = '/contact';
  static const checkoutSuccess = '/checkout/success';
  static const home = '/home';
  static const technician = '/technician';
}

/// Pure redirect rules, kept separate so they can be unit tested.
String? authRedirect(AuthState auth, String rawLocation) {
  var location = rawLocation;

  // Clean custom scheme deep links e.g. "aquasense://checkout/success?session_id=..."
  if (location.startsWith('aquasense://')) {
    final uri = Uri.parse(location);
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    final query = uri.hasQuery ? '?${uri.query}' : '';
    location = '$path$query';
  }

  if (location == Routes.root) {
    return Routes.splash;
  }

  const publicPages = {
    Routes.welcome,
    Routes.login,
    Routes.register,
    Routes.pricing,
    Routes.contact,
    Routes.checkoutSuccess,
  };

  final cleanPath = location.split('?').first;

  return switch (auth) {
    AuthRestoring() || AuthRestoreFailed() => cleanPath == Routes.splash ? null : Routes.splash,
    Unauthenticated() => publicPages.contains(cleanPath) ? null : Routes.login,
    Authenticated() => (cleanPath == Routes.login || cleanPath == Routes.register || cleanPath == Routes.splash)
        ? Routes.home
        : null,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref
    ..listen(authControllerProvider, (_, next) => authChanges.value = next)
    ..onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authChanges,
    onException: (context, state, router) {
      final loc = state.uri.toString();
      if (loc.contains('checkout/success')) {
        final sessionId = state.uri.queryParameters['session_id'];
        final param = sessionId != null ? '?session_id=$sessionId' : '';
        router.go('${Routes.checkoutSuccess}$param');
      } else {
        router.go(Routes.splash);
      }
    },
    redirect: (context, state) => authRedirect(authChanges.value, state.uri.toString()),
    routes: [
      GoRoute(path: Routes.root, redirect: (_, __) => Routes.splash),
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: Routes.pricing, builder: (_, __) => const PricingScreen()),
      GoRoute(path: Routes.contact, builder: (_, __) => const ContactScreen()),
      GoRoute(
        path: Routes.checkoutSuccess,
        builder: (_, state) => CheckoutSuccessScreen(
          sessionId: state.uri.queryParameters['session_id'],
        ),
      ),
      GoRoute(path: Routes.home, builder: (_, __) => const MainTabScreen()),
      GoRoute(path: Routes.technician, builder: (_, __) => const TechnicianScreen()),
    ],
  );
});
