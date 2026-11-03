import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/activities/presentation/pages/activity_execution_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/app_shell.dart';
import '../../features/governance_matrix/presentation/pages/governance_matrix_page.dart';
import '../../features/issues/presentation/pages/issues_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../storage/hive_storage.dart';

/// Named route paths.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String issues = '/issues';
  static const String governanceMatrix = '/governance-matrix';
  static const String reports = '/reports';
  static const String activityExecution = '/activity-execution/:id';
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

    final hasSession = HiveStorage.isLoggedIn;

    // If session exists and user tries to visit login/onboarding → dashboard
    if (hasSession &&
        (location == AppRoutes.login || location == AppRoutes.onboarding)) {
      return AppRoutes.dashboard;
    }

    // If no session and user tries to visit dashboard → login
    if (!hasSession && location == AppRoutes.dashboard) {
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
    GoRoute(
      path: AppRoutes.issues,
      name: 'issues',
      builder: (_, __) => const IssuesPage(),
    ),
    GoRoute(
      path: AppRoutes.governanceMatrix,
      name: 'governanceMatrix',
      builder: (_, __) => const GovernanceMatrixPage(),
    ),
    GoRoute(
      path: AppRoutes.reports,
      name: 'reports',
      builder: (_, __) => const ReportsPage(),
    ),
    GoRoute(
      path: AppRoutes.activityExecution,
      name: 'activityExecution',
      builder: (_, state) => ActivityExecutionPage(
        activityId: state.pathParameters['id'] ?? '',
      ),
    ),
  ],
);
