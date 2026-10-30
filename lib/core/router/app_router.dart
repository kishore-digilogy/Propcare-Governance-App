import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/app_shell.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../storage/hive_storage.dart';

/// Named route paths.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
}

/// GoRouter instance with redirect logic:
///   - First launch  → onboarding → login
///   - Token exists  → dashboard
///   - No token      → login
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  redirect: (BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    // Let splash handle its own navigation
    if (location == AppRoutes.splash) return null;
    // Let onboarding through freely
    if (location == AppRoutes.onboarding) return null;

    final hasToken = HiveStorage.authToken != null &&
        HiveStorage.authToken!.isNotEmpty;

    // If token exists and user tries to visit login/onboarding → dashboard
    if (hasToken &&
        (location == AppRoutes.login || location == AppRoutes.onboarding)) {
      return AppRoutes.dashboard;
    }

    // If no token and user tries to visit dashboard → login
    if (!hasToken && location == AppRoutes.dashboard) {
      return AppRoutes.login;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (_, __) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      builder: (_, __) => const AppShell(),
    ),
  ],
);
