import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/issue_model.dart';

abstract class IssuesRemoteDataSource {
  Future<IssuesResponseModel> getIssues({
    int offset = 0,
    int limit = 50,
    String? status,
    String? siteId,
    String? zoneId,
    String? clusterId,
  });

  Future<IssueDetailModel> getIssueDetail(String issueId);

  Future<IssueModel> createIssue(Map<String, dynamic> payload);

  Future<bool> updateIssue(String issueId, Map<String, dynamic> payload);

  Future<IssueActionModel> addActionPoint(Map<String, dynamic> payload);
}

class IssuesRemoteDataSourceImpl implements IssuesRemoteDataSource {
  final Dio _dio;

  IssuesRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  @override
  Future<IssuesResponseModel> getIssues({
    int offset = 0,
    int limit = 50,
    String? status,
    String? siteId,
    String? zoneId,
    String? clusterId,
  }) async {
    const path = '/issues';
    final queryParams = <String, dynamic>{
      'offset': offset,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (siteId != null && siteId.isNotEmpty && siteId != 'ALL') {
      queryParams['siteId'] = siteId;
    }
    if (zoneId != null && zoneId.isNotEmpty && zoneId != 'ALL') {
      queryParams['zoneId'] = zoneId;
    }
    if (clusterId != null && clusterId.isNotEmpty && clusterId != 'ALL') {
      queryParams['clusterId'] = clusterId;
    }

    final fullUrl = '${_dio.options.baseUrl}$path?$queryParams';
    developer.log('🌐 Issues API call → $fullUrl', name: 'Issues');

    try {
      final response = await _dio.get(path, queryParameters: queryParams);

      developer.log(
        '✅ Issues response [${response.statusCode}]\n${response.data}',
        name: 'Issues',
      );

      if (response.data is Map) {
        return IssuesResponseModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) {
          return IssuesResponseModel.fromJson(Map<String, dynamic>.from(decoded));
        }
      }

      return IssuesResponseModel.empty;
    } on DioException catch (e) {
      developer.log('❌ Issues API error: ${e.message}', name: 'Issues');
      rethrow;
    } catch (e) {
      developer.log('❌ Issues unexpected error: $e', name: 'Issues');
      rethrow;
    }
  }

  @override
  Future<IssueDetailModel> getIssueDetail(String issueId) async {
    final path = '/issues/$issueId';
    final fullUrl = '${_dio.options.baseUrl}$path';
    developer.log('🌐 Issue Detail API call → $fullUrl', name: 'Issues');

    try {
      final response = await _dio.get(path);
      developer.log(
        '✅ Issue Detail response [${response.statusCode}]\n${response.data}',
        name: 'Issues',
      );

      if (response.data is Map) {
        return IssueDetailModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) {
          return IssueDetailModel.fromJson(Map<String, dynamic>.from(decoded));
        }
      }

      throw Exception('Empty response from $path');
    } on DioException catch (e) {
      developer.log('❌ Issue Detail API error: ${e.message}', name: 'Issues');
      rethrow;
    } catch (e) {
      developer.log('❌ Issue Detail unexpected error: $e', name: 'Issues');
      rethrow;
    }
  }

  @override
  Future<IssueModel> createIssue(Map<String, dynamic> payload) async {
    const path = '/issues';
    final fullUrl = '${_dio.options.baseUrl}$path';
    developer.log('🌐 Create Issue API call → $fullUrl\n$payload', name: 'Issues');

    try {
      final response = await _dio.post(path, data: payload);
      developer.log(
        '✅ Create Issue response [${response.statusCode}]: ${response.data}',
        name: 'Issues',
      );

      Map<String, dynamic>? dataMap;
      if (response.data is Map) {
        dataMap = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) dataMap = Map<String, dynamic>.from(decoded);
      }

      if (dataMap != null) {
        return IssueModel.fromJson(dataMap);
      }

      throw Exception('Failed to parse created issue');
    } on DioException catch (e) {
      developer.log('❌ Create Issue API error: ${e.message}', name: 'Issues');
      rethrow;
    } catch (e) {
      developer.log('❌ Create Issue unexpected error: $e', name: 'Issues');
      rethrow;
    }
  }

  @override
  Future<bool> updateIssue(String issueId, Map<String, dynamic> payload) async {
    final path = '/issues/$issueId';
    developer.log('🌐 Update Issue API call → $path\n$payload', name: 'Issues');

    try {
      final response = await _dio.patch(path, data: payload);
      developer.log('✅ Update Issue response [${response.statusCode}]', name: 'Issues');
      return true;
    } catch (_) {
      try {
        final putResp = await _dio.put(path, data: payload);
        developer.log('✅ Fallback PUT Update Issue response [${putResp.statusCode}]', name: 'Issues');
        return true;
      } catch (e) {
        developer.log('❌ Update Issue failed: $e', name: 'Issues');
        rethrow;
      }
    }
  }

  @override
  Future<IssueActionModel> addActionPoint(Map<String, dynamic> payload) async {
    const path = '/actions';
    final fullUrl = '${_dio.options.baseUrl}$path';
    developer.log('🌐 Add Action Point API call → $fullUrl\n$payload', name: 'Issues');

    try {
      final response = await _dio.post(path, data: payload);
      developer.log(
        '✅ Add Action Point response [${response.statusCode}]: ${response.data}',
        name: 'Issues',
      );

      Map<String, dynamic>? dataMap;
      if (response.data is Map) {
        dataMap = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) dataMap = Map<String, dynamic>.from(decoded);
      }

      if (dataMap != null) {
        return IssueActionModel.fromJson(dataMap);
      }

      throw Exception('Failed to parse created action point');
    } on DioException catch (e) {
      developer.log('❌ Add Action Point API error: ${e.message}', name: 'Issues');
      rethrow;
    } catch (e) {
      developer.log('❌ Add Action Point unexpected error: $e', name: 'Issues');
      rethrow;
    }
  }
}

