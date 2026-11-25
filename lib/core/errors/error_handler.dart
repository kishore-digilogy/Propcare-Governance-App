import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Structured, user-facing error representation with human-friendly
/// text, appropriate icon, theme colors, and optional technical details.
class UserFriendlyError {
  final String title;
  final String message;
  final String? technicalDetails;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isConnectionError;

  const UserFriendlyError({
    required this.title,
    required this.message,
    this.technicalDetails,
    this.icon = Icons.error_outline_rounded,
    this.iconColor = const Color(0xFFEF4444),
    this.iconBgColor = const Color(0xFFFEE2E2),
    this.isConnectionError = false,
  });
}

/// Translates raw exceptions, DioExceptions, and error strings
/// into clear, actionable, user-friendly errors.
class AppErrorHandler {
  AppErrorHandler._();

  static UserFriendlyError parse(dynamic error, {String? defaultTitle}) {
    if (error == null) {
      return UserFriendlyError(
        title: defaultTitle ?? 'Something Went Wrong',
        message: 'An unexpected issue occurred. Please try again.',
      );
    }

    final rawString = error.toString();

    // 1. Handle DioException directly
    if (error is DioException) {
      return _parseDioException(error, defaultTitle: defaultTitle);
    }

    // 2. Handle string representations of network / socket errors
    final lower = rawString.toLowerCase();

    if (lower.contains('connection closed before full header') ||
        lower.contains('connection error') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception')) {
      return UserFriendlyError(
        title: defaultTitle ?? 'Unable to Connect',
        message:
            'Could not reach the server. Please check your internet connection or try again shortly.',
        technicalDetails: rawString,
        icon: Icons.wifi_off_rounded,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
        isConnectionError: true,
      );
    }

    if (lower.contains('timeoutexception') ||
        lower.contains('timed out') ||
        lower.contains('connection timeout') ||
        lower.contains('receive timeout')) {
      return UserFriendlyError(
        title: defaultTitle ?? 'Connection Timed Out',
        message:
            'The server is taking too long to respond. Please check your network and try again.',
        technicalDetails: rawString,
        icon: Icons.timer_outlined,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
        isConnectionError: true,
      );
    }

    if (lower.contains('401') ||
        lower.contains('unauthorized') ||
        lower.contains('unauthenticated') ||
        lower.contains('token expired')) {
      return UserFriendlyError(
        title: defaultTitle ?? 'Session Expired',
        message: 'Your session has expired. Please sign in again to continue.',
        technicalDetails: rawString,
        icon: Icons.lock_outline_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBgColor: const Color(0xFFEFF6FF),
      );
    }

    if (lower.contains('403') || lower.contains('forbidden')) {
      return UserFriendlyError(
        title: defaultTitle ?? 'Access Restricted',
        message:
            'You do not have permission to perform this action or view this data.',
        technicalDetails: rawString,
        icon: Icons.gpp_bad_outlined,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
      );
    }

    if (lower.contains('404') || lower.contains('not found')) {
      return UserFriendlyError(
        title: defaultTitle ?? 'Not Found',
        message: 'The requested data or endpoint could not be found.',
        technicalDetails: rawString,
        icon: Icons.search_off_rounded,
        iconColor: const Color(0xFF64748B),
        iconBgColor: const Color(0xFFF1F5F9),
      );
    }

    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('server error')) {
      return UserFriendlyError(
        title: defaultTitle ?? 'Server Temporarily Unavailable',
        message:
            'Our servers are experiencing temporary difficulties. Please try again in a few moments.',
        technicalDetails: rawString,
        icon: Icons.cloud_off_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
      );
    }

    // Clean up Exception: prefixes for generic messages
    String cleanMsg = rawString
        .replaceAll('Exception: ', '')
        .replaceAll('Error: ', '')
        .trim();

    if (cleanMsg.length > 120 || cleanMsg.contains('{') || cleanMsg.contains('http')) {
      cleanMsg =
          'We encountered an issue while processing your request. Please try again.';
    }

    return UserFriendlyError(
      title: defaultTitle ?? 'Unable to Load Data',
      message: cleanMsg.isNotEmpty
          ? cleanMsg
          : 'Something went wrong. Please tap Retry to try again.',
      technicalDetails: rawString,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      iconBgColor: const Color(0xFFFEE2E2),
    );
  }

  static UserFriendlyError _parseDioException(
    DioException err, {
    String? defaultTitle,
  }) {
    final technicalDetails =
        'DioException [${err.type}]: ${err.message}\nURL: ${err.requestOptions.uri}\nResponse: ${err.response?.data}';

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return UserFriendlyError(
          title: defaultTitle ?? 'Connection Timed Out',
          message:
              'The server is taking too long to respond. Please check your internet connection and try again.',
          technicalDetails: technicalDetails,
          icon: Icons.timer_outlined,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFEF3C7),
          isConnectionError: true,
        );

      case DioExceptionType.connectionError:
        return UserFriendlyError(
          title: defaultTitle ?? 'Unable to Connect',
          message:
              'Could not reach the server. Please check your network connection and try again.',
          technicalDetails: technicalDetails,
          icon: Icons.wifi_off_rounded,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFEF3C7),
          isConnectionError: true,
        );

      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        final data = err.response?.data;

        // Extract backend error message if available
        String? backendMsg;
        if (data is Map) {
          if (data['message'] is String && data['message'].toString().trim().isNotEmpty) {
            backendMsg = data['message'].toString().trim();
          } else if (data['error'] is String && data['error'].toString().trim().isNotEmpty) {
            backendMsg = data['error'].toString().trim();
          }

          // If there are detailed field validation errors (Zod / 422)
          if (data['details'] is List && (data['details'] as List).isNotEmpty) {
            final detailsList = (data['details'] as List)
                .map((d) {
                  if (d is Map && d['message'] != null) {
                    final field = d['field'] != null ? '${d['field']}: ' : '';
                    return '$field${d['message']}';
                  }
                  return d.toString();
                })
                .take(3)
                .join(', ');
            if (detailsList.isNotEmpty) {
              backendMsg = (backendMsg != null)
                  ? '$backendMsg ($detailsList)'
                  : detailsList;
            }
          }
        }

        if (status == 401) {
          return UserFriendlyError(
            title: defaultTitle ?? 'Session Expired',
            message: backendMsg ??
                'Your session has expired. Please sign in again to continue.',
            technicalDetails: technicalDetails,
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBgColor: const Color(0xFFEFF6FF),
          );
        }

        if (status == 403) {
          return UserFriendlyError(
            title: defaultTitle ?? 'Access Restricted',
            message: backendMsg ??
                'You do not have permission to view this section or perform this action.',
            technicalDetails: technicalDetails,
            icon: Icons.gpp_bad_outlined,
            iconColor: const Color(0xFFDC2626),
            iconBgColor: const Color(0xFFFEE2E2),
          );
        }

        if (status == 404) {
          return UserFriendlyError(
            title: defaultTitle ?? 'Not Found',
            message: backendMsg ??
                'The requested data or endpoint could not be found.',
            technicalDetails: technicalDetails,
            icon: Icons.search_off_rounded,
            iconColor: const Color(0xFF64748B),
            iconBgColor: const Color(0xFFF1F5F9),
          );
        }

        if (status == 422) {
          return UserFriendlyError(
            title: defaultTitle ?? 'Validation Notice',
            message: backendMsg ??
                'Some of the input data is invalid or missing. Please check and try again.',
            technicalDetails: technicalDetails,
            icon: Icons.assignment_late_outlined,
            iconColor: const Color(0xFFEA580C),
            iconBgColor: const Color(0xFFFFEDD5),
          );
        }

        if (status != null && status >= 500) {
          return UserFriendlyError(
            title: defaultTitle ?? 'Server Temporarily Unavailable',
            message:
                'Our servers are experiencing a temporary issue. Please try again shortly.',
            technicalDetails: technicalDetails,
            icon: Icons.cloud_off_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBgColor: const Color(0xFFFEE2E2),
          );
        }

        return UserFriendlyError(
          title: defaultTitle ?? 'Request Failed',
          message: backendMsg ??
              'The server returned an error (HTTP $status). Please try again.',
          technicalDetails: technicalDetails,
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFFEE2E2),
        );

      case DioExceptionType.cancel:
        return UserFriendlyError(
          title: defaultTitle ?? 'Request Cancelled',
          message: 'The request was cancelled.',
          technicalDetails: technicalDetails,
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFF64748B),
          iconBgColor: const Color(0xFFF1F5F9),
        );

      case DioExceptionType.badCertificate:
        return UserFriendlyError(
          title: defaultTitle ?? 'Security Notice',
          message:
              'A secure connection could not be established. Please check your network security settings.',
          technicalDetails: technicalDetails,
          icon: Icons.security_outlined,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
        );

      case DioExceptionType.unknown:
      default:
        return parse(err.error ?? err.message, defaultTitle: defaultTitle);
    }
  }
}
