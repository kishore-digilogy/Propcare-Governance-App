import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/mom_activity_model.dart';
import '../models/mom_by_site_model.dart';

abstract class MomRemoteDataSource {
  Future<MomBySiteModel> getMomBySite();
  Future<List<MomActivityModel>> getGovernanceActivities();
  Future<List<MomActivityModel>> getSiteMomActivities({required String siteId});
  Future<bool> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  });
  Future<MomActivityModel> updateMomPointStatus({
    required String activityId,
    required String pointId,
    required String status,
  });
}

class MomRemoteDataSourceImpl implements MomRemoteDataSource {
  final Dio _dio;

  MomRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  List<dynamic> _extractRawItems(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      if (data['items'] is List) return data['items'] as List;
      if (data['data'] is List) return data['data'] as List;
      if (data['data'] is Map && data['data']['items'] is List) {
        return data['data']['items'] as List;
      }
      if (data['activities'] is List) return data['activities'] as List;
      if (data['results'] is List) return data['results'] as List;
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        return _extractRawItems(decoded);
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<List<MomActivityModel>> getGovernanceActivities() async {
    const path = '/activities';
    final queryParams = {
      'kind': 'GOVERNANCE',
      'limit': 200,
      'offset': 0,
      '_t': DateTime.now().millisecondsSinceEpoch,
    };
    final options = Options(
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    );

    developer.log('🌐 Fetching governance activities → $path', name: 'MOM');

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: options,
      );

      final rawItems = _extractRawItems(response.data);
      if (rawItems.isNotEmpty) {
        final list = <MomActivityModel>[];
        for (final item in rawItems) {
          if (item is Map) {
            try {
              list.add(
                MomActivityModel.fromJson(Map<String, dynamic>.from(item)),
              );
            } catch (e, st) {
              developer.log(
                'Error parsing MomActivityModel: $e',
                error: e,
                stackTrace: st,
                name: 'MOM',
              );
            }
          }
        }
        if (list.isNotEmpty) return list;
      }

      // If kind=GOVERNANCE yielded 0, retry without kind filter to check if activities are under another kind
      try {
        final broadResponse = await _dio.get(
          path,
          queryParameters: {
            'limit': 200,
            'offset': 0,
            '_t': DateTime.now().millisecondsSinceEpoch,
          },
          options: options,
        );
        final broadItems = _extractRawItems(broadResponse.data);
        final broadList = <MomActivityModel>[];
        for (final item in broadItems) {
          if (item is Map) {
            try {
              broadList.add(
                MomActivityModel.fromJson(Map<String, dynamic>.from(item)),
              );
            } catch (_) {}
          }
        }
        if (broadList.isNotEmpty) return broadList;
      } catch (_) {}

      return [];
    } on DioException catch (e) {
      developer.log('❌ getGovernanceActivities error: ${e.message}', name: 'MOM');
      return [];
    } catch (e) {
      developer.log('❌ getGovernanceActivities error: $e', name: 'MOM');
      return [];
    }
  }

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
        final model = MomBySiteModel.fromJson(dataMap);
        if (model.items.isNotEmpty) {
          return model;
        }
      }

      // Fallback: aggregate from GET /activities?kind=GOVERNANCE&limit=200
      return await _aggregateFromGovernanceActivities();
    } on DioException catch (e) {
      developer.log('⚠️ MOM By Site primary failed: ${e.message}, trying fallback...', name: 'MOM');
      return await _aggregateFromGovernanceActivities();
    } catch (e) {
      developer.log('⚠️ MOM By Site error: $e, trying fallback...', name: 'MOM');
      return await _aggregateFromGovernanceActivities();
    }
  }

  Future<MomBySiteModel> _aggregateFromGovernanceActivities() async {
    try {
      final activities = await getGovernanceActivities();
      if (activities.isEmpty) return MomBySiteModel.empty;

      // Group activities by siteId
      final siteMap = <String, List<MomActivityModel>>{};
      for (final a in activities) {
        final sid = a.siteId.isNotEmpty ? a.siteId : 'default_site';
        siteMap.putIfAbsent(sid, () => []).add(a);
      }

      final siteItems = <MomSiteItemModel>[];
      int totalPending = 0;
      int totalCompleted = 0;

      for (final entry in siteMap.entries) {
        final acts = entry.value;
        final first = acts.first;
        final pending = acts.where((a) => a.isPending).length;
        final completed = acts.where((a) => a.isSent).length;
        totalPending += pending;
        totalCompleted += completed;

        siteItems.add(
          MomSiteItemModel(
            siteId: entry.key,
            siteName: first.siteName.isNotEmpty ? first.siteName : 'Site',
            siteCode: first.siteCode,
            siteCity: first.siteCity,
            siteClientType: first.clientType,
            zoneName: first.zoneName,
            clusterName: first.clusterName,
            siteStatus: 'LIVE',
            pending: pending,
            completed: completed,
            total: acts.length,
          ),
        );
      }

      return MomBySiteModel(
        items: siteItems,
        pending: totalPending,
        completed: totalCompleted,
      );
    } catch (e) {
      developer.log('Fallback aggregation failed: $e', name: 'MOM');
      return MomBySiteModel.empty;
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
      '_t': DateTime.now().millisecondsSinceEpoch,
    };
    final options = Options(
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    );
    final fullUrl = '${_dio.options.baseUrl}$path?$queryParams';

    developer.log('🌐 Site MOM Activities API call → $fullUrl', name: 'MOM');

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: options,
      );

      developer.log(
        '✅ Site MOM Activities response [${response.statusCode}]',
        name: 'MOM',
      );

      final rawItems = _extractRawItems(response.data);
      if (rawItems.isNotEmpty) {
        final list = <MomActivityModel>[];
        for (final item in rawItems) {
          if (item is Map) {
            try {
              list.add(
                MomActivityModel.fromJson(Map<String, dynamic>.from(item)),
              );
            } catch (e, st) {
              developer.log(
                'Error parsing MomActivityModel: $e',
                error: e,
                stackTrace: st,
                name: 'MOM',
              );
            }
          }
        }
        if (list.isNotEmpty) return list;
      }

      // Retry without kind filter if kind=GOVERNANCE yielded nothing
      try {
        final broadResponse = await _dio.get(
          path,
          queryParameters: {
            'siteId': siteId,
            'limit': 100,
            'offset': 0,
            '_t': DateTime.now().millisecondsSinceEpoch,
          },
          options: options,
        );
        final broadRaw = _extractRawItems(broadResponse.data);
        final broadList = <MomActivityModel>[];
        for (final item in broadRaw) {
          if (item is Map) {
            try {
              broadList.add(
                MomActivityModel.fromJson(Map<String, dynamic>.from(item)),
              );
            } catch (_) {}
          }
        }
        if (broadList.isNotEmpty) return broadList;
      } catch (_) {}

      return [];
    } on DioException catch (e) {
      developer.log('❌ Site MOM Activities error: ${e.message}', name: 'MOM');
      return [];
    } catch (e) {
      developer.log('❌ Site MOM Activities unexpected error: $e', name: 'MOM');
      return [];
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

  @override
  Future<MomActivityModel> updateMomPointStatus({
    required String activityId,
    required String pointId,
    required String status,
  }) async {
    final path = '/activities/$activityId/mom/points/$pointId';
    developer.log('🔄 Updating MOM point status: $path -> $status', name: 'MOM');

    final response = await _dio.patch(path, data: {'status': status});

    if (response.statusCode == 200 || response.statusCode == 204) {
      final data = response.data;
      if (data is Map && data['activity'] is Map) {
        return MomActivityModel.fromJson(Map<String, dynamic>.from(data['activity'] as Map));
      } else if (data is Map) {
        return MomActivityModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Invalid response format for updateMomPointStatus');
    } else {
      throw Exception('Failed to update action point (HTTP ${response.statusCode})');
    }
  }
}
