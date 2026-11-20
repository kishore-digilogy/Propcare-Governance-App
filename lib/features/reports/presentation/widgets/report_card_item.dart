import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/report_catalog_model.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

class _ReportTheme {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color badgeBg;
  final Color badgeText;
  final Color badgeBorder;

  const _ReportTheme({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.badgeBg,
    required this.badgeText,
    required this.badgeBorder,
  });

  static _ReportTheme forReport(ReportItemModel report) {
    final k = '${report.exportKind} ${report.id} ${report.title}'.toLowerCase();
    if (k.contains('site')) {
      return const _ReportTheme(
        icon: Icons.apartment_rounded,
        iconColor: Color(0xFF2563EB),
        iconBg: Color(0xFFEFF6FF),
        badgeBg: Color(0xFFEFF6FF),
        badgeText: Color(0xFF1D4ED8),
        badgeBorder: Color(0xFFDBEAFE),
      );
    }
    if (k.contains('governance') ||
        k.contains('visit') ||
        k.contains('activity')) {
      return const _ReportTheme(
        icon: Icons.verified_user_rounded,
        iconColor: Color(0xFF16A34A),
        iconBg: Color(0xFFF0FDF4),
        badgeBg: Color(0xFFF0FDF4),
        badgeText: Color(0xFF15803D),
        badgeBorder: Color(0xFFDCFCE7),
      );
    }
    if (k.contains('issue')) {
      return const _ReportTheme(
        icon: Icons.warning_amber_rounded,
        iconColor: Color(0xFFD97706),
        iconBg: Color(0xFFFEF3C7),
        badgeBg: Color(0xFFFFFBEB),
        badgeText: Color(0xFFB45309),
        badgeBorder: Color(0xFFFDE68A),
      );
    }
    if (k.contains('transition') ||
        k.contains('l&d') ||
        k.contains('training')) {
      return const _ReportTheme(
        icon: Icons.school_rounded,
        iconColor: Color(0xFF7C3AED),
        iconBg: Color(0xFFFAF5FF),
        badgeBg: Color(0xFFFAF5FF),
        badgeText: Color(0xFF6D28D9),
        badgeBorder: Color(0xFFEDE9FE),
      );
    }
    if (k.contains('ehs') || k.contains('safety') || k.contains('audit')) {
      return const _ReportTheme(
        icon: Icons.health_and_safety_rounded,
        iconColor: Color(0xFF0D9488),
        iconBg: Color(0xFFF0FDFA),
        badgeBg: Color(0xFFF0FDFA),
        badgeText: Color(0xFF0F766E),
        badgeBorder: Color(0xFFCCFBF1),
      );
    }
    return const _ReportTheme(
      icon: Icons.analytics_outlined,
      iconColor: Color(0xFF4F46E5),
      iconBg: Color(0xFFEEF2FF),
      badgeBg: Color(0xFFEEF2FF),
      badgeText: Color(0xFF4338CA),
      badgeBorder: Color(0xFFE0E7FF),
    );
  }
}

class ReportCardItem extends StatelessWidget {
  final ReportItemModel report;
  final bool isRunning;
  final VoidCallback onRun;

  const ReportCardItem({
    super.key,
    required this.report,
    required this.isRunning,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final hasRecords = report.count > 0;
    final theme = _ReportTheme.forReport(report);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Icon, Title and Count Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Distinct Category Icon Box
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.badgeBorder,
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  theme.icon,
                  size: 20,
                  color: theme.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  report.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Count Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: hasRecords ? theme.badgeBg : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasRecords
                        ? theme.badgeBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  report.countDisplay,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: hasRecords ? theme.badgeText : _kSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description (compact, max 2 lines with ellipsis)
          Text(
            report.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: _kSlate,
              height: 1.4,
            ),
          ),

          // Bottom Action: View Report Button (Hidden or subtle badge if 0 records)
          const SizedBox(height: 12),
          if (hasRecords) ...[
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: isRunning ? null : onRun,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: const Size(60, 34),
                  ),
                  icon: isRunning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kBlue,
                          ),
                        )
                      : const Icon(
                          Icons.visibility_outlined,
                          size: 15,
                          color: Color(0xFF1D4ED8),
                        ),
                  label: Text(
                    'View Report',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Text(
                'No records in scope',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
