import 'dart:developer' as developer;
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
        validateStatus: (status) => status != null && status >= 200 && status < 400,
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
      FallbackHostInterceptor(),
    ]);

    return dio;
  }
}

/// Automatically attempts the fallback API host if the primary host is unreachable due to network connection issues.
class FallbackHostInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isConnectionFailure = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout;

    if (isConnectionFailure && err.requestOptions.extra['retried_fallback'] != true) {
      final fallbackBase = AppConfig.fallbackBaseUrl;
      final currentBase = err.requestOptions.baseUrl.isNotEmpty
          ? err.requestOptions.baseUrl
          : AppConfig.baseUrl;

      if (fallbackBase != currentBase) {
        developer.log(
          '⚠️ Primary API host unreachable ($currentBase). Retrying with fallback host: $fallbackBase',
          name: 'FallbackHost',
        );

        try {
          final fallbackDio = Dio(
            BaseOptions(
              baseUrl: fallbackBase,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              validateStatus: (status) => status != null && status >= 200 && status < 400,
              headers: err.requestOptions.headers,
            ),
          );

          final retryOptions = Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
            extra: {
              ...err.requestOptions.extra,
              'retried_fallback': true,
            },
          );

          final response = await fallbackDio.request(
            err.requestOptions.path,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
            options: retryOptions,
          );

          developer.log(
            '✅ Fallback request succeeded [${response.statusCode}] on $fallbackBase',
            name: 'FallbackHost',
          );

          return handler.resolve(response);
        } catch (fallbackError) {
          developer.log(
            '❌ Fallback host also failed: $fallbackError',
            name: 'FallbackHost',
          );
        }
      }
    }

    super.onError(err, handler);
  }
}
