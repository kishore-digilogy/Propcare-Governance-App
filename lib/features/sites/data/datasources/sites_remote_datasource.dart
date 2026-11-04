import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/site_detail_model.dart';
import '../models/site_model.dart';
import '../models/transition_detail_model.dart';

abstract class SitesRemoteDataSource {
  Future<SitesResponseModel> getSites({
    int offset = 0,
    int limit = 20,
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? mode,
    String? status,
    String? search,
    String? tab,
  });

  Future<RenewalSitesResponseModel> getRenewalSites({
    String window = '30',
    int offset = 0,
    int limit = 20,
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? search,
  });

  Future<SiteDetailResponseModel> getSiteDetail(String siteId);

  Future<TransitionSiteDetailResponseModel> getTransitionDetail(String siteId);

  Future<TransitionSiteDetailResponseModel> saveTransitionAction(
    String siteId, {
    required String action,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> kickoff,
  });

  Future<void> raiseTransitionIssue(
    String siteId, {
    required String phase,
    required String key,
    required String issue,
    required String ownerId,
    required String remarks,
  });

  Future<void> updateSpecialAttention(
    String siteId, {
    required bool enabled,
    required String fromDate,
    required String toDate,
    required String reason,
  });

  Future<void> updateClassification(
    String siteId, {
    required String clientType,
    required String effectiveDate,
    required String reason,
  });

  Future<void> updateLifecycle(
    String siteId, {
    required String action,
    required String reason,
  });
}

class SitesRemoteDataSourceImpl implements SitesRemoteDataSource {
  final Dio _dio;

  SitesRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  @override
  Future<SitesResponseModel> getSites({
    int offset = 0,
    int limit = 20,
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? mode,
    String? status,
    String? search,
    String? tab,
  }) async {
    const path = '/sites';
    final queryParams = <String, dynamic>{
      'offset': offset,
      'limit': limit,
    };

    if (zoneId != null && zoneId.isNotEmpty && zoneId != 'ALL') {
      queryParams['zoneId'] = zoneId;
    }
    if (clusterId != null && clusterId.isNotEmpty && clusterId != 'ALL') {
      queryParams['clusterId'] = clusterId;
    }
    if (clientType != null && clientType.isNotEmpty && clientType != 'ALL') {
      queryParams['clientType'] = clientType;
    }
    if (mode != null && mode.isNotEmpty && mode != 'ALL') {
      queryParams['mode'] = mode;
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (tab != null && tab.isNotEmpty && tab != 'All') {
      queryParams['tab'] = tab;
    }

    final response = await _dio.get(
      path,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 || response.statusCode == 304) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return SitesResponseModel.fromJson(data);
      }
      return const SitesResponseModel(
        items: [],
        total: 0,
        tabCounts: SiteTabCountsModel(
          all: 0,
          draft: 0,
          live: 0,
          transition: 0,
          delayed: 0,
          special: 0,
        ),
      );
    } else {
      throw Exception('Failed to load sites (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<RenewalSitesResponseModel> getRenewalSites({
    String window = '30',
    int offset = 0,
    int limit = 20,
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? search,
  }) async {
    const path = '/sites/renewals';
    final queryParams = <String, dynamic>{
      'window': window,
      'offset': offset,
      'limit': limit,
    };

    if (zoneId != null && zoneId.isNotEmpty && zoneId != 'ALL') {
      queryParams['zoneId'] = zoneId;
    }
    if (clusterId != null && clusterId.isNotEmpty && clusterId != 'ALL') {
      queryParams['clusterId'] = clusterId;
    }
    if (clientType != null && clientType.isNotEmpty && clientType != 'ALL') {
      queryParams['clientType'] = clientType;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _dio.get(
      path,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 || response.statusCode == 304) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return RenewalSitesResponseModel.fromJson(data);
      }
      return const RenewalSitesResponseModel(
        items: [],
        total: 0,
        window: '30',
        windowCounts: RenewalWindowCountsModel(
          count30: 0,
          count60: 0,
          count90: 0,
          countPending: 0,
        ),
      );
    } else {
      throw Exception('Failed to load renewal sites (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<SiteDetailResponseModel> getSiteDetail(String siteId) async {
    final path = '/sites/$siteId';
    final response = await _dio.get(path);

    if (response.statusCode == 200 || response.statusCode == 304) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return SiteDetailResponseModel.fromJson(data);
      } else if (data is Map) {
        return SiteDetailResponseModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Malformed response for site $siteId');
    } else {
      throw Exception('Failed to load site details (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<TransitionSiteDetailResponseModel> getTransitionDetail(String siteId) async {
    // Try dedicated L&D transition endpoint first
    try {
      final response = await _dio.get('/ld-transition/sites/$siteId');
      if (response.statusCode == 200 || response.statusCode == 304) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return TransitionSiteDetailResponseModel.fromJson(data);
        } else if (data is Map) {
          return TransitionSiteDetailResponseModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (_) {
      // fallback below
    }

    final path = '/sites/$siteId?view=transition';
    final response = await _dio.get(path);

    if (response.statusCode == 200 || response.statusCode == 304) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TransitionSiteDetailResponseModel.fromJson(data);
      } else if (data is Map) {
        return TransitionSiteDetailResponseModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Malformed transition response for site $siteId');
    } else {
      throw Exception('Failed to load transition site details (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<TransitionSiteDetailResponseModel> saveTransitionAction(
    String siteId, {
    required String action,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> kickoff,
  }) async {
    final payload = {
      'action': action,
      'items': items,
      'kickoff': kickoff,
    };
    final response = await _dio.post('/ld-transition/sites/$siteId', data: payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TransitionSiteDetailResponseModel.fromJson(data);
      } else if (data is Map) {
        return TransitionSiteDetailResponseModel.fromJson(Map<String, dynamic>.from(data));
      }
      return getTransitionDetail(siteId);
    } else {
      throw Exception('Failed to save transition ($action) (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<void> raiseTransitionIssue(
    String siteId, {
    required String phase,
    required String key,
    required String issue,
    required String ownerId,
    required String remarks,
  }) async {
    final payload = {
      'phase': phase,
      'key': key,
      'issue': issue,
      'ownerId': ownerId,
      'remarks': remarks,
    };
    final response = await _dio.post(
      '/ld-transition/sites/$siteId/raise-issue',
      data: payload,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to raise issue (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<void> updateSpecialAttention(
    String siteId, {
    required bool enabled,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    final path = '/sites/$siteId/special-attention';
    final payload = {
      'enabled': enabled,
      'fromDate': fromDate,
      'toDate': toDate,
      'reason': reason,
    };
    final response = await _dio.post(path, data: payload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update special attention (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<void> updateClassification(
    String siteId, {
    required String clientType,
    required String effectiveDate,
    required String reason,
  }) async {
    final path = '/sites/$siteId/classification';
    final payload = {
      'clientType': clientType,
      'effectiveDate': effectiveDate,
      'reason': reason,
    };
    final response = await _dio.post(path, data: payload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update client classification (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<void> updateLifecycle(
    String siteId, {
    required String action,
    required String reason,
  }) async {
    final path = '/sites/$siteId/lifecycle';
    final payload = {
      'action': action,
      'reason': reason,
    };
    final response = await _dio.post(path, data: payload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update lifecycle (HTTP ${response.statusCode})');
    }
  }
}

