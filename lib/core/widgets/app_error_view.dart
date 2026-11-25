import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../errors/error_handler.dart';

/// A modern, enterprise-grade Error View component for PropCare Governance.
/// Transforms raw errors into elegant, understandable, and actionable screens.
class AppErrorView extends StatefulWidget {
  final dynamic error;
  final String? customTitle;
  final String? customMessage;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final bool isCompact;

  const AppErrorView({
    super.key,
    required this.error,
    this.customTitle,
    this.customMessage,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.isCompact = false,
  });

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  bool _showDetails = false;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final parsed = AppErrorHandler.parse(
      widget.error,
      defaultTitle: widget.customTitle,
    );

    final title = widget.customTitle ?? parsed.title;
    final message = widget.customMessage ?? parsed.message;
    final details = parsed.technicalDetails;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 16 : 24,
          vertical: widget.isCompact ? 20 : 36,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.isCompact ? 380 : 480,
          ),
          child: Container(
            padding: EdgeInsets.all(widget.isCompact ? 20 : 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Modern Floating Icon Container ─────────────────────────
                Container(
                  width: widget.isCompact ? 56 : 68,
                  height: widget.isCompact ? 56 : 68,
                  decoration: BoxDecoration(
                    color: parsed.iconBgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: parsed.iconColor.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      parsed.icon,
                      size: widget.isCompact ? 28 : 34,
                      color: parsed.iconColor,
                    ),
                  ),
                ),
                SizedBox(height: widget.isCompact ? 16 : 20),

                // ── Meaningful Title ───────────────────────────────────────
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: widget.isCompact ? 17 : 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Clear, Friendly Message ────────────────────────────────
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: widget.isCompact ? 12.5 : 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),

                // ── Collapsible Technical Details (Clean & Non-Intrusive) ───
                if (details != null && details.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showDetails
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showDetails
                                ? 'Hide Technical Details'
                                : 'View Technical Details',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showDetails) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Error Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: details),
                                  );
                                  setState(() => _copied = true);
                                  Future.delayed(
                                    const Duration(seconds: 2),
                                    () {
                                      if (mounted) {
                                        setState(() => _copied = false);
                                      }
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _copied
                                            ? Icons.check_rounded
                                            : Icons.copy_rounded,
                                        size: 12,
                                        color: _copied
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _copied ? 'Copied' : 'Copy',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: _copied
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            details,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                SizedBox(height: widget.isCompact ? 18 : 24),

                // ── Action Buttons ─────────────────────────────────────────
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (widget.onSecondaryAction != null &&
                        widget.secondaryActionLabel != null)
                      OutlinedButton(
                        onPressed: widget.onSecondaryAction,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.secondaryActionLabel!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    if (widget.onRetry != null)
                      ElevatedButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          widget.retryLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1769E8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
