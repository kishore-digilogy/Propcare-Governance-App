import 'package:equatable/equatable.dart';

import '../../data/models/notification_item_model.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationItemModel> allItems;
  final int unreadCount;
  final String activeFilter; // 'ALL', 'UNREAD', 'GOVERNANCE', 'ISSUE'
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final int limit;
  final String? actionMessage;

  const NotificationsLoaded({
    required this.allItems,
    required this.unreadCount,
    this.activeFilter = 'ALL',
    this.isLoadingMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.limit = 40,
    this.actionMessage,
  });

  List<NotificationItemModel> get filteredItems {
    switch (activeFilter.toUpperCase()) {
      case 'UNREAD':
        return allItems.where((i) => i.unread).toList();
      case 'READ':
        return allItems.where((i) => i.isRead).toList();
      case 'GOVERNANCE':
        return allItems
            .where((i) =>
                i.category.toLowerCase().contains('governance') ||
                i.type.toLowerCase().contains('assignment') ||
                i.type.toLowerCase().contains('mapping'))
            .toList();
      case 'ISSUE':
        return allItems
            .where((i) =>
                i.category.toLowerCase().contains('issue') ||
                i.type.toLowerCase().contains('issue') ||
                i.type.toLowerCase().contains('tat') ||
                i.type.toLowerCase().contains('action'))
            .toList();
      case 'ALL':
      default:
        return allItems;
    }
  }

  int get unreadCategoryCount => allItems.where((i) => i.unread).length;
  int get governanceCount => allItems
      .where((i) =>
          i.category.toLowerCase().contains('governance') ||
          i.type.toLowerCase().contains('assignment') ||
          i.type.toLowerCase().contains('mapping'))
      .length;
  int get issuesCount => allItems
      .where((i) =>
          i.category.toLowerCase().contains('issue') ||
          i.type.toLowerCase().contains('issue') ||
          i.type.toLowerCase().contains('tat') ||
          i.type.toLowerCase().contains('action'))
      .length;

  NotificationsLoaded copyWith({
    List<NotificationItemModel>? allItems,
    int? unreadCount,
    String? activeFilter,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    int? limit,
    String? actionMessage,
  }) {
    return NotificationsLoaded(
      allItems: allItems ?? this.allItems,
      unreadCount: unreadCount ?? this.unreadCount,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        allItems,
        unreadCount,
        activeFilter,
        isLoadingMore,
        hasMore,
        offset,
        limit,
        actionMessage,
      ];
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
