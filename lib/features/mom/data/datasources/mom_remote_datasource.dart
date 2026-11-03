import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/mom_activity_model.dart';
import '../models/mom_by_site_model.dart';

abstract class MomRemoteDataSource {
  Future<MomBySiteModel> getMomBySite();
  Future<List<MomActivityModel>> getSiteMomActivities({required String siteId});
  Future<bool> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  });
}

class MomRemoteDataSourceImpl implements MomRemoteDataSource {
  final Dio _dio;

  MomRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  @override
  Future<MomBySiteModel> getMomBySite() async {
    const path = '/activities/mom-by-site';
    final fullUrl = '${_dio.options.baseUrl}$path';

    developer.log('🌐 MOM By Site API call → $fullUrl', name: 'MOM');

    try {
      final response = await _dio.get(path);

      developer.log(
        '✅ MOM By Site response [${response.statusCode}]\n${response.data}',
        name: 'MOM',
      );

      if (response.data is Map) {
        return MomBySiteModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) {
          return MomBySiteModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      return MomBySiteModel.empty;
    } on DioException catch (e) {
      developer.log('❌ MOM By Site API error: ${e.message}', name: 'MOM');
      rethrow;
    } catch (e) {
      developer.log('❌ MOM unexpected error: $e', name: 'MOM');
      rethrow;
    }
  }

  @override
  Future<List<MomActivityModel>> getSiteMomActivities({
    required String siteId,
  }) async {
    const path = '/activities';
    final queryParams = {
      'kind': 'GOVERNANCE',
      'siteId': siteId,
      'limit': 100,
      'offset': 0,
    };
    final fullUrl = '${_dio.options.baseUrl}$path?$queryParams';

    developer.log('🌐 Site MOM Activities API call → $fullUrl', name: 'MOM');

    try {
      final response = await _dio.get(path, queryParameters: queryParams);

      developer.log(
        '✅ Site MOM Activities response [${response.statusCode}]\n${response.data}',
        name: 'MOM',
      );

      Map<String, dynamic>? dataMap;
      if (response.data is Map) {
        dataMap = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) {
          dataMap = Map<String, dynamic>.from(decoded);
        }
      }

      if (dataMap != null) {
        final rawItems = dataMap['items'] as List<dynamic>? ?? [];
        final list = <MomActivityModel>[];
        for (final item in rawItems) {
          if (item is Map) {
            try {
              list.add(
                MomActivityModel.fromJson(Map<String, dynamic>.from(item)),
              );
            } catch (e, st) {
              developer.log('Error parsing MomActivityModel: $e', error: e, stackTrace: st, name: 'MOM');
            }
          }
        }
        return list;
      }

      return [];
    } on DioException catch (e) {
      developer.log('❌ Site MOM Activities error: ${e.message}', name: 'MOM');
      rethrow;
    } catch (e) {
      developer.log('❌ Site MOM Activities unexpected error: $e', name: 'MOM');
      rethrow;
    }
  }

  @override
  Future<bool> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  }) async {
    developer.log('📧 Sending MOM email for activity $activityId:\n$payload', name: 'MOM');

    // Attempt primary POST /activities/{id}/mom
    final primaryPath = '/activities/$activityId/mom';
    try {
      final response = await _dio.post(primaryPath, data: payload);
      developer.log('✅ Send MOM response [${response.statusCode}]: ${response.data}', name: 'MOM');
      return true;
    } on DioException catch (e) {
      developer.log('⚠️ Primary send MOM endpoint failed: ${e.message}, trying fallback...', name: 'MOM');
      // If 404 or 405, try PUT /activities/{id}/mom or POST /activities/mom
      try {
        final fallbackResponse = await _dio.put(primaryPath, data: payload);
        developer.log('✅ Fallback PUT Send MOM response [${fallbackResponse.statusCode}]', name: 'MOM');
        return true;
      } catch (_) {
        try {
          final postActivitiesMom = await _dio.post('/activities/mom', data: {
            'activityId': activityId,
            ...payload,
          });
          developer.log('✅ Fallback /activities/mom response [${postActivitiesMom.statusCode}]', name: 'MOM');
          return true;
        } catch (_) {
          rethrow;
        }
      }
    }
  }
}
