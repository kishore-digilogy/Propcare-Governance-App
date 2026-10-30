import 'package:dio/dio.dart';

import '../../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Remote data source for authentication.
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      // Extract pc_session from Set-Cookie headers
      String? sessionCookie;
      final setCookies = response.headers['set-cookie'];
      if (setCookies != null && setCookies.isNotEmpty) {
        for (final cookie in setCookies) {
          final match = RegExp(r'pc_session=([^;]+)').firstMatch(cookie);
          if (match != null && match.group(1) != null) {
            sessionCookie = match.group(1);
            break;
          }
        }
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UserModel.fromJson(data, sessionCookie: sessionCookie);
      }
      throw const ServerException(message: 'Invalid response from server');
    } on DioException catch (e) {
      String errorMessage = 'Login failed. Please check your credentials.';

      if (e.response?.data is Map<String, dynamic>) {
        final resp = e.response!.data as Map<String, dynamic>;
        errorMessage =
            (resp['error'] ?? resp['message'] ?? errorMessage).toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to reach the server. Please check your internet connection.';
      }

      throw ServerException(message: errorMessage);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } on DioException {
      // Ignore logout errors — always clear local session
    }
  }
}
