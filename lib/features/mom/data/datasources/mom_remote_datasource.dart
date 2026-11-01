import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/mom_by_site_model.dart';

abstract class MomRemoteDataSource {
  Future<MomBySiteModel> getMomBySite();
}

class MomRemoteDataSourceImpl implements MomRemoteDataSource {
  final Dio _dio;

  MomRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  @override
  Future<MomBySiteModel> getMomBySite() async {
    const path = '/activities/mom-by-site';
    final fullUrl = '${_dio.options.baseUrl}$path';

    developer.log('🌐 MOM API call → $fullUrl', name: 'MOM');

    try {
      final response = await _dio.get(path);

      developer.log(
        '✅ MOM response [${response.statusCode}]\n${response.data}',
        name: 'MOM',
      );

      if (response.data is Map<String, dynamic>) {
        return MomBySiteModel.fromJson(response.data as Map<String, dynamic>);
      }

      return MomBySiteModel.empty;
    } on DioException catch (e) {
      developer.log('❌ MOM API error: ${e.message}', name: 'MOM');
      rethrow;
    } catch (e) {
      developer.log('❌ MOM unexpected error: $e', name: 'MOM');
      rethrow;
    }
  }
}

