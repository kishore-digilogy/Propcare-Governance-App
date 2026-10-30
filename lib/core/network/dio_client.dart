import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/hive_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Singleton Dio HTTP client configured for PropCare environments.
class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _build();
    return _instance!;
  }

  /// Rebuilds or updates baseUrl when switching environments at runtime.
  static void updateEnvironment(AppEnvironment env) {
    AppConfig.setEnvironment(env);
    if (_instance != null) {
      _instance!.options.baseUrl = AppConfig.baseUrl;
    }
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-PropCare-Request': '1', // Required by backend API
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: () => HiveStorage.authToken),
      LoggingInterceptor(),
    ]);

    return dio;
  }
}
