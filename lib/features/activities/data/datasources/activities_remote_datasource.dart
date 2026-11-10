import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/activity_detail_model.dart';
import '../models/activity_site_summary_model.dart';
import '../models/checklist_report_model.dart';
import '../models/site_activity_item_model.dart';

abstract class ActivitiesRemoteDataSource {
  Future<SiteActivitiesResponseModel> getActivities({
    String? view, // 'mine' or 'below'
    String? siteId,
    int offset = 0,
    int limit = 10,
    String? status,
    String? statusBucket,
    String? role,
    String? zoneId,
    String? clusterId,
    String? kind,
  });

  Future<ActivitiesBySiteResponseModel> getActivitiesBySite({
    required String view, // 'mine' or 'below'
    String? zoneId,
    String? clusterId,
    String? status,
    String? role,
  });

  Future<SiteActivitiesResponseModel> getSiteActivities({
    required String view, // 'mine' or 'below'
    required String siteId,
    int offset = 0,
    int limit = 10,
    String? status,
    String? role,
  });

  Future<ActivityDetailModel> getActivityDetail(String activityId);

  Future<ActivityItemDetailModel> completeActivity({
    required String activityId,
    required String visitDate,
    required bool clientMet,
    String? note,
  });

  Future<ActivityItemDetailModel> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  });

  Future<ChecklistReportResponseModel> getChecklistBySite();

  Future<SiteChecklistDetailResponseModel> getChecklistDetailBySite(String siteId);

  Future<bool> saveChecklistAnswers({
    required String activityId,
    required List<Map<String, dynamic>> answers,
  });
}

class ActivitiesRemoteDataSourceImpl implements ActivitiesRemoteDataSource {
  final Dio _dio;

  ActivitiesRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  @override
  Future<ActivitiesBySiteResponseModel> getActivitiesBySite({
    required String view,
    String? zoneId,
    String? clusterId,
    String? status,
    String? role,
  }) async {
    const path = '/activities/by-site';
    final queryParams = <String, dynamic>{
      'view': view,
    };

    if (zoneId != null && zoneId.isNotEmpty && zoneId != 'ALL') {
      queryParams['zoneId'] = zoneId;
    }
    if (clusterId != null && clusterId.isNotEmpty && clusterId != 'ALL') {
      queryParams['clusterId'] = clusterId;
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (role != null && role.isNotEmpty && role != 'ALL') {
      queryParams['role'] = role;
    }

    final response = await _dio.get(
      path,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 || response.statusCode == 304) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ActivitiesBySiteResponseModel.fromJson(data);
      }
      return const ActivitiesBySiteResponseModel(
        items: [],
        pending: 0,
        completed: 0,
        total: 0,
        view: 'mine',
        myRoleLabel: 'CRRM / Super Admin',
      );
    } else {
      throw Exception('Failed to load activities by site (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<SiteActivitiesResponseModel> getActivities({
    String? view,
    String? siteId,
    int offset = 0,
    int limit = 10,
    String? status,
    String? statusBucket,
    String? role,
    String? zoneId,
    String? clusterId,
    String? kind,
  }) async {
    const path = '/activities';
    final queryParams = <String, dynamic>{
      'offset': offset,
      'limit': limit,
    };
    if (view != null && view.isNotEmpty) {
      queryParams['view'] = view;
    }
    if (kind != null && kind.isNotEmpty) {
      queryParams['kind'] = kind;
    }

    if (siteId != null && siteId.isNotEmpty && siteId != 'ALL') {
      queryParams['siteId'] = siteId;
    }
    if (statusBucket != null && statusBucket.isNotEmpty && statusBucket != 'ALL') {
      queryParams['statusBucket'] = statusBucket.toLowerCase();
    } else if (status != null && status.isNotEmpty && status != 'ALL') {
      if (kind != null && (kind.contains('MIS') || kind.contains('MMR') || kind.contains('RR'))) {
        queryParams['statusBucket'] = status.toLowerCase();
      } else {
        queryParams['status'] = status;
      }
    }
    if (role != null && role.isNotEmpty && role != 'ALL') {
      queryParams['role'] = role;
    }
    if (zoneId != null && zoneId.isNotEmpty && zoneId != 'ALL') {
      queryParams['zoneId'] = zoneId;
    }
    if (clusterId != null && clusterId.isNotEmpty && clusterId != 'ALL') {
      queryParams['clusterId'] = clusterId;
    }

    final response = await _dio.get(
      path,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 || response.statusCode == 304) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return SiteActivitiesResponseModel.fromJson(data);
      }
      return const SiteActivitiesResponseModel(
        items: [],
        total: 0,
        limit: 10,
        offset: 0,
        counts: SiteActivityCountsModel(
          today: 0,
          upcoming: 0,
          pending: 0,
          overdue: 0,
          all: 0,
          scheduled: 0,
          assigned: 0,
          completed: 0,
          summaryOverdue: 0,
          summaryPending: 0,
        ),
        view: 'mine',
        myRole: '',
        myRoleLabel: '',
      );
    } else {
      throw Exception('Failed to load activities (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<SiteActivitiesResponseModel> getSiteActivities({
    required String view,
    required String siteId,
    int offset = 0,
    int limit = 10,
    String? status,
    String? role,
  }) {
    return getActivities(
      view: view,
      siteId: siteId,
      offset: offset,
      limit: limit,
      status: status,
      role: role,
    );
  }

  @override
  Future<ActivityDetailModel> getActivityDetail(String activityId) async {
    final path = '/activities/$activityId';
    final response = await _dio.get(path);

    if (response.statusCode == 200 || response.statusCode == 304) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ActivityDetailModel.fromJson(data);
      } else if (data is Map) {
        return ActivityDetailModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Invalid response format for activity detail');
    } else {
      throw Exception('Failed to load activity detail (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<ActivityItemDetailModel> completeActivity({
    required String activityId,
    required String visitDate,
    required bool clientMet,
    String? note,
  }) async {
    final path = '/activities/$activityId/complete';
    final payload = {
      'visitDate': visitDate,
      'clientMet': clientMet,
      'note': note ?? '',
      'completionNote': 'Visit date: $visitDate\nClient met: ${clientMet ? "Yes" : "No"}\nNote: ${note ?? ""}\nMOM required',
    };

    final response = await _dio.post(path, data: payload);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map && data['activity'] is Map) {
        return ActivityItemDetailModel.fromJson(Map<String, dynamic>.from(data['activity'] as Map));
      } else if (data is Map) {
        return ActivityItemDetailModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Invalid response format for activity complete');
    } else {
      throw Exception('Failed to complete activity (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<ActivityItemDetailModel> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  }) async {
    final primaryPath = '/activities/$activityId/mom';
    Response response;
    try {
      response = await _dio.post(primaryPath, data: payload);
    } on DioException {
      response = await _dio.put(primaryPath, data: payload);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map && data['activity'] is Map) {
        return ActivityItemDetailModel.fromJson(Map<String, dynamic>.from(data['activity'] as Map));
      } else if (data is Map) {
        return ActivityItemDetailModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Invalid response format for sendMomEmail');
    } else {
      throw Exception('Failed to send MOM email (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<ChecklistReportResponseModel> getChecklistBySite() async {
    const path = '/activities/checklist-by-site';
    final response = await _dio.get(path);

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ChecklistReportResponseModel.fromJson(data);
      } else if (data is Map) {
        return ChecklistReportResponseModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Invalid response format for checklist-by-site');
    } else {
      throw Exception('Failed to load checklist-by-site (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<SiteChecklistDetailResponseModel> getChecklistDetailBySite(String siteId) async {
    final path = '/activities/checklist-by-site/$siteId';
    final response = await _dio.get(path);

    if (response.statusCode == 200 || response.statusCode == 304) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return SiteChecklistDetailResponseModel.fromJson(data);
      } else if (data is Map) {
        return SiteChecklistDetailResponseModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Invalid response format for site checklist detail');
    } else {
      throw Exception('Failed to load site checklist detail (HTTP ${response.statusCode})');
    }
  }

  @override
  Future<bool> saveChecklistAnswers({
    required String activityId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final path = '/activities/$activityId/checklist-answers';
    final response = await _dio.patch(
      path,
      data: {
        'answers': answers,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to save checklist answers (HTTP ${response.statusCode})');
    }
  }
}

