import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  final int limit;
  final int offset;
  final bool refresh;

  const LoadNotifications({
    this.limit = 40,
    this.offset = 0,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [limit, offset, refresh];
}

class LoadMoreNotifications extends NotificationsEvent {
  const LoadMoreNotifications();
}

class MarkNotificationAsRead extends NotificationsEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class ChangeNotificationFilter extends NotificationsEvent {
  final String filter; // 'ALL', 'UNREAD', 'GOVERNANCE', 'ISSUE'

  const ChangeNotificationFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

class MarkAllNotificationsAsRead extends NotificationsEvent {
  const MarkAllNotificationsAsRead();
}
