import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:propcare_governance/injection_container.dart';
import 'package:propcare_governance/features/tracking/data/db/app_database.dart';
import 'package:propcare_governance/features/tracking/data/models/attendance.dart';
import 'package:propcare_governance/features/tracking/data/models/day_story.dart';
import 'package:propcare_governance/features/tracking/data/models/site_attendance.dart';
import 'package:propcare_governance/features/tracking/data/models/tracking.dart';
import 'package:propcare_governance/features/tracking/core/utils/geo.dart';
import 'package:propcare_governance/features/tracking/presentation/pages/field_tracking_page.dart';
import 'package:propcare_governance/features/tracking/presentation/pages/session_route_map_page.dart';
import 'package:propcare_governance/features/tracking/presentation/pages/tracking_session_history_page.dart';
import 'package:propcare_governance/features/tracking/core/utils/tracking_exception.dart';
import 'package:propcare_governance/features/tracking/presentation/widgets/dashboard_tracking_header.dart';
import 'package:propcare_governance/features/tracking/services/location_service.dart';
import 'package:propcare_governance/features/tracking/services/tracking_controller.dart';
import 'package:propcare_governance/features/tracking/services/tracking/demo_location.dart';
import 'package:propcare_governance/features/tracking/services/tracking/simulated_tracking_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late AppController controller;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    database = AppDatabase.forTesting();
    controller = AppController(
      database: database,
      platform: SimulatedTrackingPlatform(batteryProvider: () async => 87),
    );

    if (sl.isRegistered<AppController>()) {
      sl.unregister<AppController>();
    }
    sl.registerSingleton<AppController>(controller);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    controller.dispose();
    await database.close();
  });

  group('DashboardTrackingHeader Widget Tests', () {
    testWidgets('renders compact attendance card on dashboard', (tester) async {
      await tester.runAsync(() async {
        await controller.bootstrap();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardTrackingHeader(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Header on dashboard only shows clean Daily Attendance duty card
      expect(find.byType(DashboardTrackingHeader), findsOneWidget);
      expect(find.text('DAILY ATTENDANCE'), findsOneWidget);
      expect(find.text('Check In for Duty'), findsOneWidget);

      // Site clock and map are NOT in the dashboard scrollview anymore
      expect(find.text('SITE CLOCK IN / OUT'), findsNothing);
      expect(find.text('LIVE FIELD RADAR'), findsNothing);

      // Verify GPS & history button (battery percentage removed)
      expect(find.byIcon(Icons.gps_fixed_rounded), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);

      expect(tester.takeException(), isNull);
    });

    testWidgets('FieldTrackingPage renders site clock in/out, radar map and history action', (tester) async {
      await tester.runAsync(() async {
        await controller.bootstrap();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FieldTrackingPage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Separate page has the Site Clock In/Out card and Live Radar Map
      expect(find.byType(FieldTrackingPage), findsOneWidget);
      expect(find.text('Live Field Tracking'), findsOneWidget);
      expect(find.text('SITE CLOCK IN / OUT'), findsOneWidget);
      expect(find.text('LIVE FIELD RADAR'), findsOneWidget);
      expect(find.text('DUTY DURATION'), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('TrackingSessionHistoryPage renders overview totals and session list', (tester) async {
      await tester.runAsync(() async {
        await controller.bootstrap();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: TrackingSessionHistoryPage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TrackingSessionHistoryPage), findsOneWidget);
      expect(find.text('Session History'), findsOneWidget);
      expect(find.text('FIELD TOTALS OVERVIEW'), findsOneWidget);
      expect(find.text('DUTY SESSIONS'), findsOneWidget);
      expect(find.text('All Days'), findsNothing);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Pick Date'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('SessionRouteMapPage renders session route map, stats, and stops carousel', (tester) async {
      await tester.runAsync(() async {
        await controller.bootstrap();
      });

      final now = DateTime.now();
      final sampleAttendance = AttendanceRecord(
        id: 'att-test-1',
        employeeId: 'emp-1',
        sessionId: 'sess-test-1',
        officeId: 'off-1',
        checkInAt: now.subtract(const Duration(hours: 2)),
        checkInLatitude: 12.9249,
        checkInLongitude: 80.1000,
        checkInAccuracy: 5,
        checkInBattery: 90,
        checkOutAt: now.subtract(const Duration(hours: 1)),
        checkOutLatitude: 12.9300,
        checkOutLongitude: 80.1100,
        checkOutAccuracy: 5,
        checkOutBattery: 85,
        status: AttendanceStatus.completed,
        totalDurationSeconds: 3600,
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      final sampleSession = DaySessionSummary(
        sessionIndex: 1,
        attendance: sampleAttendance,
        distanceMeters: 4500,
        siteVisitCount: 1,
        siteNames: const ['Casagrand Suncity'],
        siteVisits: [
          SiteAttendance(
            id: 'site-att-1',
            employeeId: 'emp-1',
            sessionId: 'sess-test-1',
            siteId: 'site-1',
            siteName: 'Casagrand Suncity',
            checkInAt: now.subtract(const Duration(minutes: 90)),
            checkInLatitude: 12.9270,
            checkInLongitude: 80.1050,
            checkInAccuracy: 5,
            checkInBattery: 88,
            checkOutAt: now.subtract(const Duration(minutes: 70)),
            checkOutLatitude: 12.9275,
            checkOutLongitude: 80.1055,
            status: SiteVisitStatus.completed,
            durationSeconds: 1200,
          ),
        ],
        stationaryEvents: [
          StationaryEvent(
            id: 'hold-1',
            employeeId: 'emp-1',
            sessionId: 'sess-test-1',
            latitude: 12.9255,
            longitude: 80.1010,
            accuracy: 4,
            status: StationaryStatus.completed,
            startAt: now.subtract(const Duration(minutes: 105)),
            endAt: now.subtract(const Duration(minutes: 95)),
            durationSeconds: 600,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SessionRouteMapPage(
            sessionSummary: sampleSession,
            sessionDate: now,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Header
      expect(find.text('SESSION #1 ROUTE'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);

      // Metric pills
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Holds'), findsOneWidget);

      // Section title & stops
      expect(find.textContaining('SESSION STOPS'), findsOneWidget);
      expect(find.text('Clock In'), findsOneWidget);
      expect(find.text('Clock Out'), findsOneWidget);
      expect(find.text('Hold · 10m'), findsOneWidget);
      expect(find.text('Site Clock In'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('DashboardTrackingHeader location field shows permission enable prompt when not granted', (tester) async {
      await tester.runAsync(() async {
        await controller.bootstrap();
      });

      // Force foreground permission to false to simulate first-time state
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        controller.permissions = const PermissionReport(
          locationServiceEnabled: true,
          foreground: false,
          background: false,
          notifications: false,
          precise: true,
          simulated: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DashboardTrackingHeader(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Enable Location Permission'), findsOneWidget);
        expect(find.text('Tap to allow GPS and fetch your field address'), findsOneWidget);
        expect(find.text('Enable'), findsOneWidget);

        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Cannot check out of duty while an active site visit exists', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await tester.runAsync(() async {
          await controller.bootstrap();
          await controller.officeCheckIn();
          final targetSite = controller.sites.first;
          DemoLocationProvider.instance.moveTo(targetSite.point);
          controller.position = targetSite.point;
          await controller.siteCheckIn(targetSite);
        });

        expect(controller.hasActiveSiteVisit, isTrue);

        // 1. Controller method throws AppException
        expect(
          () => controller.officeCheckOut(),
          throwsA(isA<AppException>().having((e) => e.code, 'code', 'active_site_visit')),
        );

        // 2. Dashboard UI prevents checkout and displays warning dialog
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DashboardTrackingHeader(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Tap checkout button
        final checkOutBtn = find.byIcon(Icons.logout_rounded);
        expect(checkOutBtn, findsOneWidget);
        await tester.tap(checkOutBtn);
        await tester.pumpAndSettle();

        expect(find.text('Site Check-Out Required'), findsOneWidget);
        expect(find.text('Go to Site & Clock Out'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Tapping Check In for Duty shows confirmation dialog with current location', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await tester.runAsync(() async {
          await controller.bootstrap();
        });

        controller.position = const GeoPoint(12.9249, 80.1000);
        controller.currentAddress =
            'Casagrand Suncity, Vandalur – Kelambakkam Road, Chennai';
        controller.accuracy = 5;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DashboardTrackingHeader(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final checkInBtn = find.text('Check In for Duty');
        expect(checkInBtn, findsOneWidget);

        // Tap Check In
        await tester.tap(checkInBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Dialog appears with confirmation details
        expect(find.text('Confirm Duty Check-In'), findsOneWidget);
        expect(find.text('CURRENT LOCATION'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Casagrand Suncity, Vandalur – Kelambakkam Road, Chennai'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('±5m'),
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Confirm & Check In'), findsOneWidget);

        // Tap Cancel - dialog dismisses and user is NOT checked in
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Confirm Duty Check-In'), findsNothing);
        expect(controller.isCheckedIn, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
