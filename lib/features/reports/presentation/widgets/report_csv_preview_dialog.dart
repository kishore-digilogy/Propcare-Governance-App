import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

class ReportCsvPreviewDialog extends StatelessWidget {
  final String title;
  final String csvContent;
  final VoidCallback onClose;

  const ReportCsvPreviewDialog({
    super.key,
    required this.title,
    required this.csvContent,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final lines = csvContent
        .trim()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final headerRow = lines.isNotEmpty ? lines.first.split(',') : <String>[];
    final dataRows = lines.length > 1
        ? lines.sublist(1).map((l) => l.split(',')).toList()
        : <List<String>>[];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 560),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dataRows.length} record(s) exported successfully',
                        style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: _kSlate),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 12),

            // Content preview table
            Expanded(
              child: lines.isEmpty
                  ? Center(
                      child: Text(
                        'Empty report (0 rows)',
                        style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 38,
                              dataRowMinHeight: 34,
                              dataRowMaxHeight: 44,
                              columnSpacing: 16,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFEFF6FF),
                              ),
                              headingTextStyle: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                              dataTextStyle: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF334155),
                              ),
                              columns: headerRow.map((h) {
                                return DataColumn(
                                  label: Text(
                                    h.replaceAll('"', '').trim(),
                                  ),
                                );
                              }).toList(),
                              rows: dataRows.take(50).map((row) {
                                return DataRow(
                                  cells: row.map((c) {
                                    return DataCell(
                                      Text(
                                        c.replaceAll('"', '').trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: csvContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'CSV copied to clipboard!',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: _kBlue,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: Text(
                    'Copy CSV',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: const Size(0, 36),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    minimumSize: const Size(0, 36),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

