import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/governance_matrix_model.dart';

abstract class GovernanceMatrixRemoteDataSource {
  Future<GovernanceMatrixResponseModel> getGovernanceMatrix();
}

class GovernanceMatrixRemoteDataSourceImpl
    implements GovernanceMatrixRemoteDataSource {
  final Dio _dio;

  GovernanceMatrixRemoteDataSourceImpl({Dio? dio})
      : _dio = dio ?? DioClient.instance;

  @override
  Future<GovernanceMatrixResponseModel> getGovernanceMatrix() async {
    const path = '/admin/governance-matrix';
    final fullUrl = '${_dio.options.baseUrl}$path';

    developer.log(
      '🌐 Governance Matrix API call → $fullUrl',
      name: 'GovernanceMatrix',
    );

    try {
      final response = await _dio.get(path);

      developer.log(
        '✅ Governance Matrix response [${response.statusCode}]\n${response.data}',
        name: 'GovernanceMatrix',
      );

      if (response.data is Map) {
        return GovernanceMatrixResponseModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } else if (response.data is String &&
          (response.data as String).isNotEmpty) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map) {
          return GovernanceMatrixResponseModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      return GovernanceMatrixResponseModel.empty;
    } on DioException catch (e) {
      developer.log(
        '❌ Governance Matrix API error: ${e.message}',
        name: 'GovernanceMatrix',
      );
      rethrow;
    } catch (e) {
      developer.log(
        '❌ Governance Matrix unexpected error: $e',
        name: 'GovernanceMatrix',
      );
      rethrow;
    }
  }
}

