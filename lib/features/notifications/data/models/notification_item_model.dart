import 'package:equatable/equatable.dart';

class NotificationItemModel extends Equatable {
  final String id;
  final String? userId;
  final String? siteId;
  final String? activityId;
  final String type;
  final String title;
  final String message;
  final String? dedupeKey;
  final String? readAt;
  final String createdAt;
  final String? updatedAt;
  final String category;
  final String? href;
  final bool unread;

  const NotificationItemModel({
    required this.id,
    this.userId,
    this.siteId,
    this.activityId,
    required this.type,
    required this.title,
    required this.message,
    this.dedupeKey,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
    required this.category,
    this.href,
    required this.unread,
  });

  bool get isRead => !unread || (readAt != null && readAt!.isNotEmpty);

  NotificationItemModel copyWith({
    String? id,
    String? userId,
    String? siteId,
    String? activityId,
    String? type,
    String? title,
    String? message,
    String? dedupeKey,
    String? readAt,
    String? createdAt,
    String? updatedAt,
    String? category,
    String? href,
    bool? unread,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      siteId: siteId ?? this.siteId,
      activityId: activityId ?? this.activityId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      href: href ?? this.href,
      unread: unread ?? this.unread,
    );
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    final readAtVal = json['readAt']?.toString();
    final unreadVal = json['unread'] == true || (json['unread'] == null && (readAtVal == null || readAtVal.isEmpty));

    return NotificationItemModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      siteId: json['siteId']?.toString(),
      activityId: json['activityId']?.toString(),
      type: json['type']?.toString() ?? 'SYSTEM',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      dedupeKey: json['dedupeKey']?.toString(),
      readAt: readAtVal,
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt']?.toString(),
      category: json['category']?.toString() ?? 'General',
      href: json['href']?.toString(),
      unread: unreadVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'siteId': siteId,
      'activityId': activityId,
      'type': type,
      'title': title,
      'message': message,
      'dedupeKey': dedupeKey,
      'readAt': readAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'category': category,
      'href': href,
      'unread': unread,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        siteId,
        activityId,
        type,
        title,
        message,
        dedupeKey,
        readAt,
        createdAt,
        updatedAt,
        category,
        href,
        unread,
      ];
}
