import 'package:dio/dio.dart';

import '../../router/app_router.dart';
import '../../storage/hive_storage.dart';
import '../../utils/app_logger.dart';

/// Common interceptor that manages:
/// 1. Attaching `Cookie: pc_session=...` to all outgoing requests.
/// 2. Attaching `X-CSRF-Token` for mutating requests (POST, PUT, PATCH, DELETE).
/// 3. Attaching `X-PropCare-Request: 1` header.
/// 4. Capturing `set-cookie` from responses and storing `pc_session` in Hive.
/// 5. Capturing `csrfToken` and user details from responses.
class AuthInterceptor extends Interceptor {
  final String? Function()? tokenProvider;

  AuthInterceptor({this.tokenProvider});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. Mandatory application header for Digilogy PropCare API
    options.headers['X-PropCare-Request'] = '1';

    // 2. Attach session cookie if present
    final sessionCookie = HiveStorage.sessionCookie;
    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      final cookieHeader = sessionCookie.startsWith('pc_session=')
          ? sessionCookie
          : 'pc_session=$sessionCookie';
      options.headers['Cookie'] = cookieHeader;
    }

    // 3. Attach CSRF token for mutating requests (POST, PUT, DELETE, PATCH)
    final method = options.method.toUpperCase();
    if (!['GET', 'HEAD', 'OPTIONS'].contains(method)) {
      final csrfToken = HiveStorage.csrfToken;
      if (csrfToken != null && csrfToken.isNotEmpty) {
        options.headers['X-CSRF-Token'] = csrfToken;
      }
    }

    // 4. Attach Bearer token fallback if present
    final bearerToken = tokenProvider?.call() ?? HiveStorage.authToken;
    if (bearerToken != null && bearerToken.isNotEmpty && options.headers['Authorization'] == null) {
      options.headers['Authorization'] = 'Bearer $bearerToken';
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Automatically capture Set-Cookie (pc_session) from response headers
    final setCookies = response.headers['set-cookie'];
    if (setCookies != null && setCookies.isNotEmpty) {
      for (final cookieStr in setCookies) {
        final match = RegExp(r'pc_session=([^;]+)').firstMatch(cookieStr);
        if (match != null && match.group(1) != null) {
          final cookieValue = match.group(1)!;
          HiveStorage.saveSessionCookie(cookieValue);
          AppLogger.info('AuthInterceptor: Updated pc_session cookie.');
        }
      }
    }

    // Automatically capture csrfToken and user object from response body if present
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['csrfToken'] != null) {
        final csrf = data['csrfToken'].toString();
        HiveStorage.saveCsrfToken(csrf);
        AppLogger.info('AuthInterceptor: Updated csrfToken.');
      }
      if (data['user'] is Map<String, dynamic>) {
        HiveStorage.saveUserProfile(data['user'] as Map<String, dynamic>);
      }
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;

    if (statusCode == 401 && !path.contains('/auth/login')) {
      AppLogger.warning(
        'AuthInterceptor: 401 Unauthorized for $path — session expired, navigating to login.',
      );
      HiveStorage.clearAuth();
      appRouter.go(AppRoutes.login);
    }

    super.onError(err, handler);
  }
}
