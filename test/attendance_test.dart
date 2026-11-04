import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/services/location_service.dart';
import 'package:propcare_governance/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:propcare_governance/features/attendance/data/models/attendance_site_model.dart';
import 'package:propcare_governance/features/attendance/data/models/site_activity_model.dart';
import 'package:propcare_governance/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:propcare_governance/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:propcare_governance/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:propcare_governance/features/attendance/presentation/pages/attendance_page.dart';

class MockAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  final AttendanceBySiteModel siteData;
  SiteActivitiesResponseModel activitiesData;

  MockAttendanceRemoteDataSource({
    required this.siteData,
    required this.activitiesData,
  });

  @override
  Future<AttendanceBySiteModel> getAttendanceBySite() async => siteData;

  @override
  Future<SiteActivitiesResponseModel> getSiteActivities({
    required String siteId,
    int limit = 100,
    int offset = 0,
  }) async =>
      activitiesData;

  @override
  Future<ActivityVisitModel> markAttendance({
    required String activityId,
    required String type,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String capturedAt,
  }) async {
    final existing = activitiesData.items.firstWhere((a) => a.id == activityId);
    if (type == 'checkin') {
      final updatedGeo = ActivityGeoModel(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        checkInAt: capturedAt,
        checkIn: GeoPointInfo(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          capturedAt: capturedAt,
        ),
      );
      final updated = existing.copyWith(geo: updatedGeo);
      activitiesData = activitiesData.updateActivity(updated);
      return updated;
    } else {
      final updatedGeo = ActivityGeoModel(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        checkInAt: existing.geo.checkInAt,
        checkIn: existing.geo.checkIn,
        checkOutAt: capturedAt,
        checkOut: GeoPointInfo(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          capturedAt: capturedAt,
        ),
      );
      final updated = existing.copyWith(
        status: 'COMPLETED',
        geo: updatedGeo,
        completedAt: capturedAt,
      );
      activitiesData = activitiesData.updateActivity(updated);
      return updated;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleActivityJson = {
    "id": "ec164953-6a78-4fde-bf1f-17fe9efeab9d",
    "siteId": "ef261f20-3171-4f37-bb12-ad3ca34dbd18",
    "role": "FIELD_EXECUTIVE",
    "kind": "GOVERNANCE",
    "title": "Field Executive Visit",
    "assignedToId": "9247021a-b3c0-4f9c-b3f3-c86f52fdd8e6",
    "scheduledDate": "2026-11-06",
    "dueDate": "2026-11-06",
    "status": "OPEN",
    "clientType": "A+",
    "code": "ACT-EC164",
    "assignedToName": "Aijth",
    "siteName": "Digilogy",
    "siteCity": "Chennai",
    "siteClientType": "A+",
    "clusterName": "OMR",
    "functionLabel": "Operations",
    "roleLabel": "Field Executive",
    "frequencyLabel": "Weekly",
    "priority": "High",
    "statusLabel": "Assigned",
    "geo": {},
  };

  final sampleSiteJson = {
    "siteId": "ef261f20-3171-4f37-bb12-ad3ca34dbd18",
    "siteName": "Digilogy",
    "siteCode": "DIGI_001",
    "clusterName": "OMR",
    "zoneName": "Tamil Nadu",
    "siteCity": "Chennai",
    "total": 1,
    "completed": 0,
    "pending": 1,
    "complianceRate": 0,
    "todayVisits": 0,
    "status": "LIVE",
    "roleCompliance": {},
  };

  group('LocationService tests', () {
    test('mockLocationProvider returns correct coordinates', () async {
      LocationService.mockLocationProvider = () async => const LocationResult(
            latitude: 12.976009890236337,
            longitude: 80.25957019802009,
            accuracy: 35.0,
            capturedAt: "2026-11-03T09:07:08.568Z",
          );
      addTearDown(() => LocationService.mockLocationProvider = null);

      final loc = await LocationService.getCurrentLocation();
      expect(loc.latitude, closeTo(12.976, 0.001));
      expect(loc.longitude, closeTo(80.259, 0.001));
      expect(loc.accuracy, 35.0);
      expect(loc.capturedAt, "2026-11-03T09:07:08.568Z");
      expect(loc.toJson()['latitude'], loc.latitude);
    });
  });

  group('SiteActivityModel tests', () {
    test('parses checkin activity and calculates isOnSite correctly', () {
      final activity = ActivityVisitModel.fromJson(sampleActivityJson);
      expect(activity.id, 'ec164953-6a78-4fde-bf1f-17fe9efeab9d');
      expect(activity.isOnSite, isFalse);
      expect(activity.isCompleted, isFalse);
      expect(activity.formattedCheckIn, '—');
      expect(activity.formattedCheckOut, '—');

      // Check-in response
      final checkedInJson = {
        ...sampleActivityJson,
        "geo": {
          "latitude": 12.976009890236337,
          "longitude": 80.25957019802009,
          "accuracy": 35,
          "capturedAt": "2026-11-03T09:07:08.568Z",
          "checkInAt": "2026-11-03T09:07:10.412Z",
          "checkIn": {
            "latitude": 12.976009890236337,
            "longitude": 80.25957019802009,
            "accuracy": 35,
            "capturedAt": "2026-11-03T09:07:08.568Z",
          },
        },
      };

      final checkedInActivity = ActivityVisitModel.fromJson(checkedInJson);
      expect(checkedInActivity.isOnSite, isTrue);
      expect(checkedInActivity.isCompleted, isFalse);
      expect(checkedInActivity.formattedDuration, 'On site');
      expect(checkedInActivity.formattedCheckIn.contains('In'), isTrue);
    });
  });

  group('AttendanceBloc tests', () {
    test('MarkActivityAttendance checkin and checkout updates state smoothly', () async {
      final initialActivity = ActivityVisitModel.fromJson(sampleActivityJson);
      final siteItem = AttendanceSiteItemModel.fromJson(sampleSiteJson);
      final siteData = AttendanceBySiteModel(
        items: [siteItem],
        pending: 1,
        completed: 0,
      );
      final activitiesData = SiteActivitiesResponseModel(
        items: [initialActivity],
        total: 1,
        limit: 100,
        offset: 0,
        pending: 1,
        completed: 0,
      );

      final ds = MockAttendanceRemoteDataSource(
        siteData: siteData,
        activitiesData: activitiesData,
      );

      final bloc = AttendanceBloc(dataSource: ds);

      // Load attendance first
      final loadFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AttendanceLoading>(),
          isA<AttendanceLoaded>(),
        ]),
      );
      bloc.add(const LoadAttendance());
      await loadFuture;

      // Select site
      final selectFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AttendanceLoaded>().having((s) => s.isActivitiesLoading, 'loading', true),
          isA<AttendanceLoaded>()
              .having((s) => s.isActivitiesLoading, 'loading', false)
              .having((s) => s.activitiesData?.items.length, 'items', 1),
        ]),
      );
      bloc.add(SelectAttendanceSite(siteItem));
      await selectFuture;

      // Check In
      final checkInFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AttendanceLoaded>().having(
            (s) => s.submittingActivityId,
            'submittingActivityId',
            'ec164953-6a78-4fde-bf1f-17fe9efeab9d',
          ),
          isA<AttendanceLoaded>()
              .having((s) => s.submittingActivityId, 'submittingActivityId', isNull)
              .having((s) => s.attendanceActionMessage, 'msg', 'Checked in successfully')
              .having(
                (s) => s.activitiesData?.items.first.isOnSite,
                'isOnSite',
                isTrue,
              ),
        ]),
      );
      bloc.add(
        const MarkActivityAttendance(
          activityId: 'ec164953-6a78-4fde-bf1f-17fe9efeab9d',
          type: 'checkin',
          latitude: 12.976,
          longitude: 80.259,
          accuracy: 35.0,
          capturedAt: '2026-11-03T09:07:08.568Z',
        ),
      );
      await checkInFuture;

      // Check Out
      final checkOutFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AttendanceLoaded>().having(
            (s) => s.submittingActivityId,
            'submittingActivityId',
            'ec164953-6a78-4fde-bf1f-17fe9efeab9d',
          ),
          isA<AttendanceLoaded>()
              .having((s) => s.submittingActivityId, 'submittingActivityId', isNull)
              .having((s) => s.attendanceActionMessage, 'msg', 'Checked out successfully')
              .having(
                (s) => s.activitiesData?.items.first.isCompleted,
                'isCompleted',
                isTrue,
              )
              .having((s) => s.activitiesData?.completed, 'completed', 1)
              .having((s) => s.activitiesData?.pending, 'pending', 0),
        ]),
      );
      bloc.add(
        const MarkActivityAttendance(
          activityId: 'ec164953-6a78-4fde-bf1f-17fe9efeab9d',
          type: 'checkout',
          latitude: 12.976,
          longitude: 80.259,
          accuracy: 35.0,
          capturedAt: '2026-11-03T09:45:08.568Z',
        ),
      );
      await checkOutFuture;
    });
  });

  group('AttendancePage UI widget tests', () {
    testWidgets('renders "Check In" button (not "Check In to Site") and updates on tap',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      LocationService.mockLocationProvider = () async => const LocationResult(
            latitude: 12.976009890236337,
            longitude: 80.25957019802009,
            accuracy: 35.0,
            capturedAt: "2026-11-03T09:07:08.568Z",
          );
      addTearDown(() => LocationService.mockLocationProvider = null);

      final initialActivity = ActivityVisitModel.fromJson(sampleActivityJson);
      final siteItem = AttendanceSiteItemModel.fromJson(sampleSiteJson);
      final siteData = AttendanceBySiteModel(
        items: [siteItem],
        pending: 1,
        completed: 0,
      );
      final activitiesData = SiteActivitiesResponseModel(
        items: [initialActivity],
        total: 1,
        limit: 100,
        offset: 0,
        pending: 1,
        completed: 0,
      );

      final ds = MockAttendanceRemoteDataSource(
        siteData: siteData,
        activitiesData: activitiesData,
      );
      final bloc = AttendanceBloc(dataSource: ds);

      await tester.pumpWidget(
        MaterialApp(
          home: AttendancePage(bloc: bloc),
        ),
      );

      // Load attendance
      bloc.add(const LoadAttendance());
      await tester.pumpAndSettle();

      // Tap on site to view activities
      expect(find.text('Digilogy'), findsWidgets);
      await tester.tap(find.text('Digilogy').first);
      await tester.pumpAndSettle();

      // Check Activity card details
      expect(find.text('Field Executive Visit'), findsOneWidget);
      expect(find.text('ACT-EC164'), findsOneWidget);

      // MUST NOT contain old button text "Check In to Site"
      expect(find.text('Check In to Site'), findsNothing);

      // MUST contain clean "Check In"
      expect(find.text('Check In'), findsOneWidget);

      // Tap "Check In"
      await tester.tap(find.text('Check In'));
      await tester.pumpAndSettle();

      // Dialog opens with title "Check In"
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Record check-in time and verify GPS location for Field Executive Visit (ACT-EC164)?'), findsOneWidget);

      // Tap Check In inside dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Check In'));
      await tester.pumpAndSettle();

      // Should now flip to "Check Out"
      expect(find.text('Check In'), findsNothing);
      expect(find.text('Check Out to Site'), findsNothing);
      expect(find.text('Check Out from Site'), findsNothing);
      expect(find.text('Check Out'), findsOneWidget);
      expect(find.text('● On site'), findsOneWidget);
    });
  });
}
