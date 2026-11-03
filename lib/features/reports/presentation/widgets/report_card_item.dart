import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/report_catalog_model.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Title and Count Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasRecords ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasRecords ? const Color(0xFFDBEAFE) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  report.countDisplay,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasRecords ? _kBlue : _kSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Description (compact, no forced expansion)
          Text(
            report.description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: _kSlate,
              height: 1.35,
            ),
          ),

          // Bottom Action: View Report Button (Hidden if 0 records)
          if (hasRecords) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: isRunning ? null : onRun,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kBlue, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(60, 32),
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
                      : const Icon(Icons.visibility_outlined, size: 14, color: _kBlue),
                  label: Text(
                    'View Report',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

