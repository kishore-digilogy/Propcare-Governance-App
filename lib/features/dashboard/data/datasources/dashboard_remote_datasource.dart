import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboard();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;
  DashboardRemoteDataSourceImpl() : _dio = DioClient.instance;

  @override
  Future<DashboardModel> getDashboard() async {
    const path = '/dashboard';
    final fullUrl = '${_dio.options.baseUrl}$path';

    developer.log('🌐 Dashboard API call → $fullUrl', name: 'Dashboard');

    final response = await _dio.get(path);

    developer.log(
      '✅ Dashboard response [${response.statusCode}]\n${response.data}',
      name: 'Dashboard',
    );

    return DashboardModel.fromJson(response.data as Map<String, dynamic>);
  }
}

