import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../utils/app_logger.dart';

/// Logs every HTTP request and response in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sep = '─' * 60;
    final log = StringBuffer()
      ..writeln(sep)
      ..writeln('📤  REQUEST')
      ..writeln('  Method  : ${options.method}')
      ..writeln('  URL     : ${options.uri}')
      ..writeln('  Headers :');
    options.headers.forEach((k, v) {
      // Mask cookie value for security in logs
      if (k.toLowerCase() == 'cookie') {
        log.writeln('    $k: [masked]');
      } else {
        log.writeln('    $k: $v');
      }
    });
    if (options.data != null) {
      log.writeln('  Body    : ${options.data}');
    } else {
      log.writeln('  Body    : (none)');
    }
    log.writeln(sep);

    AppLogger.info(log.toString());
    developer.log(log.toString(), name: 'HTTP');

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sep = '─' * 60;
    final log = StringBuffer()
      ..writeln(sep)
      ..writeln('📥  RESPONSE')
      ..writeln('  Status  : ${response.statusCode}')
      ..writeln('  URL     : ${response.requestOptions.uri}')
      ..writeln('  Body    : ${response.data}')
      ..writeln(sep);

    AppLogger.info(log.toString());
    developer.log(log.toString(), name: 'HTTP');

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sep = '─' * 60;
    final log = StringBuffer()
      ..writeln(sep)
      ..writeln('❌  ERROR')
      ..writeln('  Status  : ${err.response?.statusCode}')
      ..writeln('  URL     : ${err.requestOptions.uri}')
      ..writeln('  Message : ${err.message}')
      ..writeln('  Body    : ${err.response?.data}')
      ..writeln(sep);

    AppLogger.error(log.toString(), err, err.stackTrace);
    developer.log(log.toString(), name: 'HTTP', error: err);

    super.onError(err, handler);
  }
}
