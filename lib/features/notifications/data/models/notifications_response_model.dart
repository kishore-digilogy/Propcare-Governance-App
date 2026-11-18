import 'package:equatable/equatable.dart';

import 'notification_item_model.dart';

class NotificationsResponseModel extends Equatable {
  final List<NotificationItemModel> items;
  final int unread;
  final int total;
  final int limit;
  final int offset;

  const NotificationsResponseModel({
    required this.items,
    required this.unread,
    this.total = 0,
    this.limit = 40,
    this.offset = 0,
  });

  bool get hasMore => items.length >= limit;

  factory NotificationsResponseModel.fromJson(
    Map<String, dynamic> json, {
    int defaultLimit = 40,
    int defaultOffset = 0,
  }) {
    final rawList = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => NotificationItemModel.fromJson(e))
        .toList();

    final unreadCount = json['unread'] is num
        ? (json['unread'] as num).toInt()
        : parsedItems.where((i) => i.unread).length;

    final totalCount = json['total'] is num
        ? (json['total'] as num).toInt()
        : parsedItems.length;

    return NotificationsResponseModel(
      items: parsedItems,
      unread: unreadCount,
      total: totalCount,
      limit: json['limit'] is num ? (json['limit'] as num).toInt() : defaultLimit,
      offset: json['offset'] is num ? (json['offset'] as num).toInt() : defaultOffset,
    );
  }

  NotificationsResponseModel copyWith({
    List<NotificationItemModel>? items,
    int? unread,
    int? total,
    int? limit,
    int? offset,
  }) {
    return NotificationsResponseModel(
      items: items ?? this.items,
      unread: unread ?? this.unread,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [items, unread, total, limit, offset];
}
