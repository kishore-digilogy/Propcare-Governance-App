import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/activities/presentation/pages/activity_execution_page.dart';
import 'package:propcare_governance/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:propcare_governance/features/notifications/data/models/notification_item_model.dart';
import 'package:propcare_governance/features/notifications/data/models/notifications_response_model.dart';
import 'package:propcare_governance/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:propcare_governance/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:propcare_governance/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:propcare_governance/features/notifications/presentation/pages/notifications_page.dart';

class MockNotificationsRemoteDataSource implements NotificationsRemoteDataSource {
  NotificationsResponseModel response;
  final List<String> markedReadIds = [];

  MockNotificationsRemoteDataSource({required this.response});

  @override
  Future<NotificationsResponseModel> getNotifications({int limit = 40, int offset = 0}) async {
    return response;
  }

  @override
  Future<NotificationItemModel> markAsRead(String notificationId) async {
    markedReadIds.add(notificationId);
    return NotificationItemModel(
      id: notificationId,
      type: 'TAT',
      title: 'Action point TAT alert',
      message: 'Test · due 2026-11-03',
      createdAt: '2026-11-16T18:30:27.255Z',
      category: 'Issue',
      readAt: '2026-11-18T09:51:40.573Z',
      unread: false,
    );
  }
}

final sampleNotificationJson = {
  "id": "e157afd0-43de-4988-8dda-a81595503676",
  "userId": "da90efc5-72e7-4e27-8d36-1739bb0314c4",
  "siteId": "bac7c24c-4c5c-4c2e-8b09-d035ef2ad8c4",
  "activityId": null,
  "type": "TAT",
  "title": "Action point TAT alert",
  "message": "Test · due 2026-11-03",
  "dedupeKey": "tat:a0ab41d4-c02f-4676-8c8a-44e289a5c352:2026-11-17",
  "readAt": null,
  "createdAt": "2026-11-16T18:30:27.255Z",
  "updatedAt": "2026-11-16T18:30:27.255Z",
  "category": "Issue",
  "href": "/sites/bac7c24c-4c5c-4c2e-8b09-d035ef2ad8c4",
  "unread": true
};

final sampleGovernanceNotificationJson = {
  "id": "9898220d-e1d9-484c-85fe-5e0e3dfc38f1",
  "userId": "da90efc5-72e7-4e27-8d36-1739bb0314c4",
  "siteId": "b926c362-20f3-4ab2-a7f7-9c32d890439e",
  "activityId": "d7a54255-a682-4714-adb5-db7e9080beba",
  "type": "ASSIGNMENT",
  "title": "A governance activity has been assigned",
  "message": "CRRM Visit",
  "dedupeKey": "assigned:d7a54255-a682-4714-adb5-db7e9080beba:da90efc5-72e7-4e27-8d36-1739bb0314c4",
  "readAt": null,
  "createdAt": "2026-11-02T03:38:01.431Z",
  "updatedAt": "2026-11-02T03:38:01.431Z",
  "category": "Governance",
  "href": "/activities/d7a54255-a682-4714-adb5-db7e9080beba",
  "unread": true
};

void main() {
  group('Notifications Models Tests', () {
    test('NotificationItemModel parses user JSON payload correctly', () {
      final model = NotificationItemModel.fromJson(sampleNotificationJson);
      expect(model.id, 'e157afd0-43de-4988-8dda-a81595503676');
      expect(model.type, 'TAT');
      expect(model.title, 'Action point TAT alert');
      expect(model.message, 'Test · due 2026-11-03');
      expect(model.category, 'Issue');
      expect(model.unread, isTrue);
      expect(model.isRead, isFalse);
    });

    test('NotificationsResponseModel parses response with unread count', () {
      final res = NotificationsResponseModel.fromJson({
        'items': [sampleNotificationJson, sampleGovernanceNotificationJson],
        'unread': 62,
        'limit': 40,
        'offset': 0,
      });

      expect(res.items.length, 2);
      expect(res.unread, 62);
      expect(res.limit, 40);
      expect(res.offset, 0);
    });
  });

  group('NotificationsBloc Tests', () {
    test('loads notifications successfully and emits NotificationsLoaded', () async {
      final res = NotificationsResponseModel.fromJson({
        'items': [sampleNotificationJson, sampleGovernanceNotificationJson],
        'unread': 62,
      });
      final ds = MockNotificationsRemoteDataSource(response: res);
      final bloc = NotificationsBloc(dataSource: ds);

      final futureExpect = expectLater(
        bloc.stream,
        emitsInOrder([
          const NotificationsLoading(),
          isA<NotificationsLoaded>()
              .having((s) => s.allItems.length, 'allItems', 2)
              .having((s) => s.unreadCount, 'unreadCount', 62)
              .having((s) => s.activeFilter, 'activeFilter', 'ALL'),
        ]),
      );

      bloc.add(const LoadNotifications());
      await futureExpect;
    });

    test('marks single notification as read and calls remote API', () async {
      final res = NotificationsResponseModel.fromJson({
        'items': [sampleNotificationJson],
        'unread': 1,
      });
      final ds = MockNotificationsRemoteDataSource(response: res);
      final bloc = NotificationsBloc(dataSource: ds);

      bloc.add(const LoadNotifications());
      await bloc.stream.firstWhere((s) => s is NotificationsLoaded);

      final readFuture = expectLater(
        bloc.stream,
        emits(
          isA<NotificationsLoaded>()
              .having((s) => s.allItems.first.unread, 'unread', isFalse)
              .having((s) => s.unreadCount, 'unreadCount', 0),
        ),
      );

      bloc.add(const MarkNotificationAsRead('e157afd0-43de-4988-8dda-a81595503676'));
      await readFuture;
      expect(ds.markedReadIds.contains('e157afd0-43de-4988-8dda-a81595503676'), isTrue);
    });

    test('changes filter tab smoothly', () async {
      final res = NotificationsResponseModel.fromJson({
        'items': [sampleNotificationJson, sampleGovernanceNotificationJson],
        'unread': 2,
      });
      final ds = MockNotificationsRemoteDataSource(response: res);
      final bloc = NotificationsBloc(dataSource: ds);

      bloc.add(const LoadNotifications());
      await bloc.stream.firstWhere((s) => s is NotificationsLoaded);

      bloc.add(const ChangeNotificationFilter('GOVERNANCE'));
      final state = await bloc.stream.firstWhere((s) => s is NotificationsLoaded) as NotificationsLoaded;

      expect(state.activeFilter, 'GOVERNANCE');
      expect(state.filteredItems.length, 1);
      expect(state.filteredItems.first.category, 'Governance');
    });
  });

  group('NotificationsPage Widget Tests', () {
    testWidgets('renders NotificationsPage with header, unread badge, filters and card items', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final res = NotificationsResponseModel.fromJson({
        'items': [sampleNotificationJson, sampleGovernanceNotificationJson],
        'unread': 62,
      });
      final ds = MockNotificationsRemoteDataSource(response: res);
      final bloc = NotificationsBloc(dataSource: ds);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('62 unread'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);

      // Verify Filter Tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Governance'), findsWidgets);
      expect(find.text('Issues'), findsWidgets);

      // Verify Cards
      expect(find.text('Action point TAT alert'), findsOneWidget);
      expect(find.text('Test · due 2026-11-03'), findsOneWidget);
      expect(find.text('A governance activity has been assigned'), findsOneWidget);
      expect(find.text('CRRM Visit'), findsOneWidget);

      // Tapping "Mark as read" updates item
      expect(find.text('Mark as read'), findsWidgets);
      await tester.tap(find.text('Mark as read').first);
      await tester.pumpAndSettle();

      expect(ds.markedReadIds, contains('e157afd0-43de-4988-8dda-a81595503676'));
    });

    testWidgets('renders Empty State when no unread notifications exist', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final res = NotificationsResponseModel.fromJson({
        'items': [],
        'unread': 0,
      });
      final ds = MockNotificationsRemoteDataSource(response: res);
      final bloc = NotificationsBloc(dataSource: ds);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications found'), findsOneWidget);
      expect(find.text('New governance activities, TAT alerts, and assignments will appear here.'), findsOneWidget);
    });

    testWidgets('Tapping notification redirects to respective screen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final res = NotificationsResponseModel.fromJson({
        'items': [
          sampleGovernanceNotificationJson, // has activityId: d7a54255...
        ],
        'unread': 1,
      });
      final ds = MockNotificationsRemoteDataSource(response: res);
      final bloc = NotificationsBloc(dataSource: ds);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Tap governance activity notification card
      await tester.tap(find.text('A governance activity has been assigned'));
      await tester.pump(); // Start transition
      await tester.pump(const Duration(milliseconds: 300)); // Complete route transition

      // Verify it marked as read and navigated to ActivityExecutionPage
      expect(find.byType(ActivityExecutionPage), findsOneWidget);
    });
  });
}
