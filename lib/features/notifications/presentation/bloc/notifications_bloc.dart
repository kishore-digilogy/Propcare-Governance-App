import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/models/notification_item_model.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRemoteDataSource dataSource;

  NotificationsBloc({required this.dataSource}) : super(const NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<ChangeNotificationFilter>(_onChangeNotificationFilter);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    if (!event.refresh && state is! NotificationsLoaded) {
      emit(const NotificationsLoading());
    }

    try {
      final res = await dataSource.getNotifications(
        limit: event.limit,
        offset: event.offset,
      );

      emit(NotificationsLoaded(
        allItems: res.items,
        unreadCount: res.unread,
        activeFilter: (state is NotificationsLoaded)
            ? (state as NotificationsLoaded).activeFilter
            : 'ALL',
        hasMore: res.items.length >= event.limit,
        offset: event.offset,
        limit: event.limit,
      ));
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    final s = state;
    if (s is! NotificationsLoaded || s.isLoadingMore || !s.hasMore) return;

    emit(s.copyWith(isLoadingMore: true));

    final nextOffset = s.offset + s.limit;
    try {
      final res = await dataSource.getNotifications(
        limit: s.limit,
        offset: nextOffset,
      );

      final existingIds = s.allItems.map((e) => e.id).toSet();
      final newItems = res.items.where((e) => !existingIds.contains(e.id)).toList();
      final combined = [...s.allItems, ...newItems];

      emit(s.copyWith(
        allItems: combined,
        unreadCount: res.unread,
        isLoadingMore: false,
        hasMore: res.items.length >= s.limit,
        offset: nextOffset,
      ));
    } catch (e) {
      developer.log('LoadMoreNotifications error: $e');
      emit(s.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final s = state;
    if (s is! NotificationsLoaded) return;

    final target = s.allItems.firstWhere(
      (i) => i.id == event.notificationId,
      orElse: () => NotificationItemModel(
        id: '',
        type: '',
        title: '',
        message: '',
        createdAt: '',
        category: '',
        unread: false,
      ),
    );

    if (target.id.isEmpty || target.isRead) return;

    // Optimistic update
    final updatedList = s.allItems.map((i) {
      if (i.id == event.notificationId) {
        return i.copyWith(
          unread: false,
          readAt: DateTime.now().toIso8601String(),
        );
      }
      return i;
    }).toList();

    final newUnreadCount = (s.unreadCount > 0) ? s.unreadCount - 1 : 0;
    emit(s.copyWith(
      allItems: updatedList,
      unreadCount: newUnreadCount,
    ));

    // Fire API call
    try {
      await dataSource.markAsRead(event.notificationId);
    } catch (e) {
      developer.log('Failed to mark notification as read on backend: $e');
    }
  }

  void _onChangeNotificationFilter(
    ChangeNotificationFilter event,
    Emitter<NotificationsState> emit,
  ) {
    final s = state;
    if (s is NotificationsLoaded) {
      emit(s.copyWith(activeFilter: event.filter));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final s = state;
    if (s is! NotificationsLoaded) return;

    final unreadItems = s.allItems.where((i) => i.unread).toList();
    if (unreadItems.isEmpty) return;

    // Optimistically update all to read
    final nowStr = DateTime.now().toIso8601String();
    final updatedList = s.allItems.map((i) {
      if (i.unread) {
        return i.copyWith(unread: false, readAt: nowStr);
      }
      return i;
    }).toList();

    emit(s.copyWith(
      allItems: updatedList,
      unreadCount: 0,
      actionMessage: 'All marked as read',
    ));

    // Fire API for unread items in background
    for (final item in unreadItems) {
      try {
        await dataSource.markAsRead(item.id);
      } catch (_) {}
    }
  }
}
