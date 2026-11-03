import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/report_catalog_model.dart';

abstract class ReportsRemoteDataSource {
  Future<ReportCatalogResponseModel> getReportCatalog({
    String dateRange = 'last_30',
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? function,
    String? status,
  });

  Future<String> downloadReportCsv({
    required String exportKind,
    String dateRange = 'last_30',
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? function,
    String? status,
  });
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final Dio _dio;

  ReportsRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  @override
  Future<ReportCatalogResponseModel> getReportCatalog({
    String dateRange = 'last_30',
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? function,
    String? status,
  }) async {
    const path = '/reports/catalog';
    final queryParams = <String, dynamic>{
      'dateRange': dateRange,
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
    if (function != null && function.isNotEmpty && function != 'ALL') {
      queryParams['function'] = function;
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }

    final fullUrl = '${_dio.options.baseUrl}$path?$queryParams';
    developer.log('🌐 Reports Catalog API call → $fullUrl', name: 'Reports');

    try {
      final response = await _dio.get(path, queryParameters: queryParams);

      developer.log(
        '✅ Reports Catalog response [${response.statusCode}]\n${response.data}',
        name: 'Reports',
      );

      if (response.data is Map) {
        return ReportCatalogResponseModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } else if (response.data is String &&
          (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) {
          return ReportCatalogResponseModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      return ReportCatalogResponseModel.empty;
    } on DioException catch (e) {
      developer.log('❌ Reports Catalog API error: ${e.message}', name: 'Reports');
      rethrow;
    } catch (e) {
      developer.log('❌ Reports Catalog unexpected error: $e', name: 'Reports');
      rethrow;
    }
  }

  @override
  Future<String> downloadReportCsv({
    required String exportKind,
    String dateRange = 'last_30',
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? function,
    String? status,
  }) async {
    final path = '/reports/$exportKind.csv';
    final queryParams = <String, dynamic>{
      'dateRange': dateRange,
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
    if (function != null && function.isNotEmpty && function != 'ALL') {
      queryParams['function'] = function;
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }

    final fullUrl = '${_dio.options.baseUrl}$path?$queryParams';
    developer.log('🌐 Download CSV API call → $fullUrl', name: 'Reports');

    try {
      final response = await _dio.get<String>(
        path,
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.plain),
      );

      developer.log(
        '✅ Download CSV response [${response.statusCode}], length: ${response.data?.length}',
        name: 'Reports',
      );

      return response.data ?? '';
    } on DioException catch (e) {
      developer.log('❌ Download CSV API error: ${e.message}', name: 'Reports');
      rethrow;
    } catch (e) {
      developer.log('❌ Download CSV unexpected error: $e', name: 'Reports');
      rethrow;
    }
  }
}

