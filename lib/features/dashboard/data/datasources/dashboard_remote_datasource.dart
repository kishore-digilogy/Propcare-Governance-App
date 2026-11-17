import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboard({
    String? zoneId,
    String? clusterId,
    String? role,
  });
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;
  DashboardRemoteDataSourceImpl() : _dio = DioClient.instance;

  @override
  Future<DashboardModel> getDashboard({
    String? zoneId,
    String? clusterId,
    String? role,
  }) async {
    const path = '/dashboard';
    final queryParameters = <String, dynamic>{};
    if (zoneId != null && zoneId.isNotEmpty) {
      queryParameters['zoneId'] = zoneId;
    }
    if (clusterId != null && clusterId.isNotEmpty) {
      queryParameters['clusterId'] = clusterId;
    }
    if (role != null && role.isNotEmpty) {
      queryParameters['role'] = role;
    }

    final fullUrl = '${_dio.options.baseUrl}$path';

    developer.log(
      '🌐 Dashboard API call → $fullUrl with params: $queryParameters',
      name: 'Dashboard',
    );

    final response = await _dio.get(
      path,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    developer.log(
      '✅ Dashboard response [${response.statusCode}]\n${response.data}',
      name: 'Dashboard',
    );

    return DashboardModel.fromJson(response.data as Map<String, dynamic>);
  }
}

