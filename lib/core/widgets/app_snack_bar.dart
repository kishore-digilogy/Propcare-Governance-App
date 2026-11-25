import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../errors/error_handler.dart';

enum SnackBarType { success, error, warning, info }

/// Modern, adaptive floating SnackBar / Toast system for PropCare Governance.
class AppSnackBar {
  AppSnackBar._();

  /// Show a success toast
  static void success(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Success',
      type: SnackBarType.success,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an error toast
  static void error(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final parsed = AppErrorHandler.parse(message, defaultTitle: title ?? 'Notice');
    show(
      context,
      message: parsed.message,
      title: title ?? parsed.title,
      type: SnackBarType.error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a warning toast
  static void warning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Warning',
      type: SnackBarType.warning,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an info toast
  static void info(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Information',
      type: SnackBarType.info,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Core show method
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final config = _typeConfig(type);

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: config.borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: config.shadowColor.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Left Accent indicator line
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: config.accentColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Icon badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: config.iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        config.icon,
                        color: config.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Message and Title
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null && title.isNotEmpty)
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                height: 1.2,
                              ),
                            ),
                          if (title != null && title.isNotEmpty)
                            const SizedBox(height: 2),
                          Text(
                            message,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                          if (actionLabel != null && onAction != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                messenger.hideCurrentSnackBar();
                                onAction();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: config.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  actionLabel,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: config.accentColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Dismiss button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      splashRadius: 16,
                      onPressed: () => messenger.hideCurrentSnackBar(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _SnackBarTypeConfig _typeConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const _SnackBarTypeConfig(
          icon: Icons.check_circle_rounded,
          accentColor: Color(0xFF10B981),
          borderColor: Color(0xFFA7F3D0),
          iconBgColor: Color(0xFFECFDF5),
          shadowColor: Color(0xFF10B981),
        );
      case SnackBarType.error:
        return const _SnackBarTypeConfig(
          icon: Icons.error_outline_rounded,
          accentColor: Color(0xFFEF4444),
          borderColor: Color(0xFFFECACA),
          iconBgColor: Color(0xFFFEF2F2),
          shadowColor: Color(0xFFEF4444),
        );
      case SnackBarType.warning:
        return const _SnackBarTypeConfig(
          icon: Icons.warning_amber_rounded,
          accentColor: Color(0xFFF59E0B),
          borderColor: Color(0xFFFDE68A),
          iconBgColor: Color(0xFFFFFBEB),
          shadowColor: Color(0xFFF59E0B),
        );
      case SnackBarType.info:
        return const _SnackBarTypeConfig(
          icon: Icons.info_outline_rounded,
          accentColor: Color(0xFF2563EB),
          borderColor: Color(0xFFBFDBFE),
          iconBgColor: Color(0xFFEFF6FF),
          shadowColor: Color(0xFF2563EB),
        );
    }
  }
}

class _SnackBarTypeConfig {
  final IconData icon;
  final Color accentColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color shadowColor;

  const _SnackBarTypeConfig({
    required this.icon,
    required this.accentColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.shadowColor,
  });
}
