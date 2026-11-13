import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:propcare_governance/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:propcare_governance/features/auth/presentation/bloc/auth_event.dart';
import 'package:propcare_governance/features/auth/presentation/bloc/auth_state.dart';
import 'package:propcare_governance/features/auth/presentation/pages/login_page.dart';
import 'package:propcare_governance/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:propcare_governance/features/splash/presentation/pages/splash_page.dart';

class _MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _MockAuthBloc() : super(const AuthInitial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS Layout & Overflow Tests', () {
    testWidgets('OnboardingPage renders without overflow on iPhone 15/16 Pro dimensions',
        (tester) async {
      // iPhone 15 Pro: 393 x 852 with top padding 59 (Dynamic Island)
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Smart Property\nManagement'), findsOneWidget);
      // Top bar must be pinned to the top (under Dynamic Island / status bar ~59px + 12px padding)
      final skipDy = tester.getTopLeft(find.text('Skip')).dy;
      expect(skipDy, lessThan(85.0));
      expect(skipDy, greaterThanOrEqualTo(59.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('OnboardingPage renders without overflow on iPhone SE dimensions',
        (tester) async {
      // iPhone SE: 375 x 667 with top padding 20
      tester.view.physicalSize = const Size(375 * 2, 667 * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.view.padding = const FakeViewPadding(top: 20 * 2, bottom: 0);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      // Top bar must be pinned at the top on iPhone SE (20px status bar + 12px padding)
      final skipDySE = tester.getTopLeft(find.text('Skip')).dy;
      expect(skipDySE, lessThan(50.0));
      expect(skipDySE, greaterThanOrEqualTo(20.0));
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SplashPage renders without overflow on iPhone 15/16 Pro',
        (tester) async {
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(SplashPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginPage renders adaptive card on iPad dimensions (810x1080)',
        (tester) async {
      tester.view.physicalSize = const Size(810 * 2, 1080 * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.view.padding = const FakeViewPadding(top: 24 * 2, bottom: 20 * 2);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>(
            create: (_) => _MockAuthBloc(),
            child: const LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify the form is constrained to max-width 480 (adaptive card)
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
      final formSize = tester.getSize(formFinder);
      expect(formSize.width, lessThanOrEqualTo(480.0));
    });

    testWidgets('OnboardingPage renders adaptively on iPad dimensions (810x1080)',
        (tester) async {
      tester.view.physicalSize = const Size(810 * 2, 1080 * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.view.padding = const FakeViewPadding(top: 24 * 2, bottom: 20 * 2);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
