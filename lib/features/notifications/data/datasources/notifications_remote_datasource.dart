import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/notification_item_model.dart';
import '../models/notifications_response_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationsResponseModel> getNotifications({
    int limit = 40,
    int offset = 0,
  });

  Future<NotificationItemModel> markAsRead(String notificationId);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final Dio _dio;

  NotificationsRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  @override
  Future<NotificationsResponseModel> getNotifications({
    int limit = 40,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return NotificationsResponseModel.fromJson(
          response.data as Map<String, dynamic>,
          defaultLimit: limit,
          defaultOffset: offset,
        );
      }

      return NotificationsResponseModel(
        items: const [],
        unread: 0,
        total: 0,
        limit: limit,
        offset: offset,
      );
    } catch (e, st) {
      developer.log('NotificationsRemoteDataSourceImpl.getNotifications failed: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<NotificationItemModel> markAsRead(String notificationId) async {
    try {
      final response = await _dio.post(
        '/notifications/$notificationId/read',
      );

      if (response.data is Map<String, dynamic>) {
        return NotificationItemModel.fromJson(response.data as Map<String, dynamic>);
      }

      return NotificationItemModel(
        id: notificationId,
        type: 'SYSTEM',
        title: '',
        message: '',
        createdAt: DateTime.now().toIso8601String(),
        category: 'General',
        unread: false,
        readAt: DateTime.now().toIso8601String(),
      );
    } catch (e, st) {
      developer.log('NotificationsRemoteDataSourceImpl.markAsRead failed: $e\n$st');
      rethrow;
    }
  }
}
