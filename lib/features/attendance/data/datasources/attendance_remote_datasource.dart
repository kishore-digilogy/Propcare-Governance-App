import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/attendance_site_model.dart';
import '../models/site_activity_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceBySiteModel> getAttendanceBySite();
  Future<SiteActivitiesResponseModel> getSiteActivities({
    required String siteId,
    int limit = 100,
    int offset = 0,
  });
  Future<ActivityVisitModel> markAttendance({
    required String activityId,
    required String type, // 'checkin' | 'checkout'
    required double latitude,
    required double longitude,
    required double accuracy,
    required String capturedAt,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final Dio _dio;

  AttendanceRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  @override
  Future<AttendanceBySiteModel> getAttendanceBySite() async {
    const path = '/activities/attendance-by-site';
    final fullUrl = '${_dio.options.baseUrl}$path';

    developer.log('🌐 Attendance API call → $fullUrl', name: 'Attendance');

    try {
      final response = await _dio.get(
        path,
        options: Options(
          headers: const {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );

      developer.log(
        '✅ Attendance response [${response.statusCode}]\n${response.data}',
        name: 'Attendance',
      );

      if (response.data is Map<String, dynamic>) {
        return AttendanceBySiteModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return AttendanceBySiteModel.empty;
    } on DioException catch (e) {
      developer.log('❌ Attendance API error: ${e.message}', name: 'Attendance');
      rethrow;
    } catch (e) {
      developer.log('❌ Attendance unexpected error: $e', name: 'Attendance');
      rethrow;
    }
  }

  @override
  Future<SiteActivitiesResponseModel> getSiteActivities({
    required String siteId,
    int limit = 100,
    int offset = 0,
  }) async {
    const path = '/activities';
    final queryParams = {
      'kind': 'GOVERNANCE',
      'siteId': siteId,
      'limit': limit,
      'offset': offset,
    };
    final fullUrl = '${_dio.options.baseUrl}$path?$queryParams';

    developer.log('🌐 Site Activities API call → $fullUrl', name: 'Attendance');

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(
          headers: const {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );

      developer.log(
        '✅ Site Activities response [${response.statusCode}]\n${response.data}',
        name: 'Attendance',
      );

      if (response.data is Map) {
        return SiteActivitiesResponseModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) {
          return SiteActivitiesResponseModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      return SiteActivitiesResponseModel.empty;
    } on DioException catch (e) {
      developer.log(
        '❌ Site Activities API error: ${e.message}',
        name: 'Attendance',
      );
      rethrow;
    } catch (e) {
      developer.log(
        '❌ Site Activities unexpected error: $e',
        name: 'Attendance',
      );
      rethrow;
    }
  }

  @override
  Future<ActivityVisitModel> markAttendance({
    required String activityId,
    required String type,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String capturedAt,
  }) async {
    final path = '/activities/$activityId/attendance';
    final payload = {
      'type': type,
      'geo': {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'capturedAt': capturedAt,
      },
    };

    final fullUrl = '${_dio.options.baseUrl}$path';
    developer.log(
      '🌐 Mark Attendance API call → $fullUrl with payload: $payload',
      name: 'Attendance',
    );

    try {
      final response = await _dio.post(
        path,
        data: payload,
        options: Options(
          headers: const {
            'Content-Type': 'application/json',
          },
        ),
      );

      developer.log(
        '✅ Mark Attendance response [${response.statusCode}]\n${response.data}',
        name: 'Attendance',
      );

      if (response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        final activityData = map['activity'] is Map
            ? Map<String, dynamic>.from(map['activity'] as Map)
            : (map['item'] is Map
                ? Map<String, dynamic>.from(map['item'] as Map)
                : map);
        return ActivityVisitModel.fromJson(activityData);
      }

      throw Exception('Invalid response format from attendance API');
    } on DioException catch (e) {
      developer.log('❌ Mark Attendance API error: ${e.message}', name: 'Attendance');
      final msg = e.response?.data is Map && (e.response?.data as Map)['message'] != null
          ? (e.response?.data as Map)['message'].toString()
          : (e.message ?? 'Failed to submit attendance');
      throw Exception(msg);
    } catch (e) {
      developer.log('❌ Mark Attendance unexpected error: $e', name: 'Attendance');
      rethrow;
    }
  }
}

