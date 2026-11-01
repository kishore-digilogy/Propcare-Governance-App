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
      final response = await _dio.get(path);

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
      );

      developer.log(
        '✅ Site Activities response [${response.statusCode}]\n${response.data}',
        name: 'Attendance',
      );

      if (response.data is Map<String, dynamic>) {
        return SiteActivitiesResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
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
}

