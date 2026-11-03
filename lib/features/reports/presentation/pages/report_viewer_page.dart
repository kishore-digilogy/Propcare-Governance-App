import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

/// Full in-app interactive Report Viewer screen.
/// Renders report data from CSV directly inside the app with search,
/// toggle between Table view and Card view, status styling, and copy tools.
class ReportViewerPage extends StatefulWidget {
  final String title;
  final String csvContent;
  final String exportKind;

  const ReportViewerPage({
    super.key,
    required this.title,
    required this.csvContent,
    this.exportKind = '',
  });

  @override
  State<ReportViewerPage> createState() => _ReportViewerPageState();
}

class _ReportViewerPageState extends State<ReportViewerPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _headers = [];
  List<List<String>> _allRows = [];
  List<List<String>> _filteredRows = [];
  bool _isCardView = false;

  @override
  void initState() {
    super.initState();
    _parseCsv();
    _filteredRows = _allRows;
    _searchController.addListener(_filterRows);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _parseCsv() {
    final lines = widget.csvContent
        .trim()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      _headers = [];
      _allRows = [];
      return;
    }

    _headers = _parseCsvLine(lines.first);
    _allRows = lines.skip(1).map(_parseCsvLine).toList();
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(_cleanCell(current.toString()));
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(_cleanCell(current.toString()));
    return result;
  }

  String _cleanCell(String val) {
    var v = val.trim();
    if (v.startsWith('"') && v.endsWith('"') && v.length >= 2) {
      v = v.substring(1, v.length - 1).trim();
    }
    return v;
  }

  void _filterRows() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredRows = _allRows);
      return;
    }

    setState(() {
      _filteredRows = _allRows.where((row) {
        return row.any((cell) => cell.toLowerCase().contains(query));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.secondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          // View Mode Toggle Button
          IconButton(
            tooltip: _isCardView ? 'Switch to Table view' : 'Switch to Card view',
            icon: Icon(
              _isCardView ? Icons.table_chart_outlined : Icons.view_agenda_outlined,
              color: _kBlue,
              size: 20,
            ),
            onPressed: () {
              setState(() => _isCardView = !_isCardView);
            },
          ),
          IconButton(
            tooltip: 'Copy data as CSV',
            icon: const Icon(Icons.copy_rounded, color: _kBlue, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.csvContent));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Report data copied to clipboard!',
                    style: GoogleFonts.outfit(),
                  ),
                  backgroundColor: _kBlue,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _kBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search & Metrics Bar ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(fontSize: 13, color: AppColors.secondary),
                      decoration: InputDecoration(
                        hintText: 'Search records...',
                        hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: _kSlate),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Record Count & Status Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'Showing ${_filteredRows.length} of ${_allRows.length} records'
                            : '${_allRows.length} records in scope',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kSlate,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Text(
                              '${_headers.length} columns',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // View Switcher (Table / Card)
                          _buildViewToggle(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),

            // ── View Area (Card View or Table View) ──
            Expanded(
              child: _headers.isEmpty
                  ? Center(
                      child: Text(
                        'No data returned for this report.',
                        style: GoogleFonts.outfit(fontSize: 14, color: _kSlate),
                      ),
                    )
                  : _filteredRows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 40, color: _kSlate),
                              const SizedBox(height: 8),
                              Text(
                                'No matching rows found',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing or changing your search term',
                                style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                              ),
                            ],
                          ),
                        )
                      : _isCardView
                          ? _buildCardView()
                          : _buildTableView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table Button
          InkWell(
            onTap: () {
              if (_isCardView) {
                setState(() => _isCardView = false);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: !_isCardView ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: !_isCardView
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    size: 13,
                    color: !_isCardView ? _kBlue : _kSlate,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Table',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: !_isCardView ? FontWeight.w700 : FontWeight.w500,
                      color: !_isCardView ? _kBlue : _kSlate,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),

          // Card Button
          InkWell(
            onTap: () {
              if (!_isCardView) {
                setState(() => _isCardView = true);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isCardView ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: _isCardView
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_agenda_outlined,
                    size: 13,
                    color: _isCardView ? _kBlue : _kSlate,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Card',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: _isCardView ? FontWeight.w700 : FontWeight.w500,
                      color: _isCardView ? _kBlue : _kSlate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 52,
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF8FAFC),
              ),
              headingTextStyle: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
              dataTextStyle: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF0F172A),
              ),
              columns: _headers.map((h) {
                return DataColumn(
                  label: Text(h),
                );
              }).toList(),
              rows: _filteredRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final isEven = index % 2 == 0;

                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return const Color(0xFFEFF6FF);
                    }
                    return isEven ? Colors.white : const Color(0xFFFAFAFA);
                  }),
                  cells: List.generate(_headers.length, (colIdx) {
                    final cellValue = colIdx < row.length ? row[colIdx] : '';
                    return DataCell(
                      _buildCellWidget(cellValue),
                    );
                  }),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardView() {
    // Detect primary title column (e.g. 'Site name', 'Name', 'Title')
    int titleIdx = _headers.indexWhere((h) {
      final l = h.toLowerCase().trim();
      return l == 'site name' || l == 'name' || l == 'title';
    });
    if (titleIdx == -1) {
      titleIdx = _headers.length > 1 ? 1 : 0;
    }

    // Detect code/id column (e.g. 'Site code', 'Code', 'ID')
    int codeIdx = _headers.indexWhere((h) {
      final l = h.toLowerCase().trim();
      return l == 'site code' || l == 'code' || l == 'id';
    });

    // Detect status column
    int statusIdx = _headers.indexWhere((h) {
      final l = h.toLowerCase().trim();
      return l == 'status' || l == 'state';
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: _filteredRows.length,
      itemBuilder: (context, index) {
        final row = _filteredRows[index];

        final titleText = titleIdx < row.length && row[titleIdx].trim().isNotEmpty
            ? row[titleIdx].trim()
            : 'Record #${index + 1}';

        final codeText = (codeIdx != -1 && codeIdx < row.length)
            ? row[codeIdx].trim()
            : '';

        final statusText = (statusIdx != -1 && statusIdx < row.length)
            ? row[statusIdx].trim()
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Title, Code & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (codeText.isNotEmpty && codeText != titleText) ...[
                            const SizedBox(height: 2),
                            Text(
                              codeText,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _kSlate,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (statusText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildCellWidget(statusText),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Attributes List
                Column(
                  children: List.generate(_headers.length, (colIdx) {
                    // Skip title and status since already displayed in top header
                    if (colIdx == titleIdx || colIdx == statusIdx || colIdx == codeIdx) {
                      return const SizedBox.shrink();
                    }

                    final header = _headers[colIdx];
                    final cellValue = colIdx < row.length ? row[colIdx].trim() : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              header,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCellWidget(cellValue),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCellWidget(String value) {
    final upper = value.toUpperCase();

    // Render Status Badges for common statuses
    if (upper == 'OPEN' || upper == 'PENDING' || upper == 'ACTIVE' || upper == 'LIVE') {
      final isGreen = upper == 'LIVE' || upper == 'ACTIVE';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isGreen ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGreen ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
          ),
        ),
        child: Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isGreen ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          ),
        ),
      );
    }

    if (upper == 'RESOLVED' || upper == 'CLOSED' || upper == 'COMPLETED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF16A34A),
          ),
        ),
      );
    }

    if (upper == 'HIGH' || upper == 'CRITICAL' || upper == 'OVERDUE') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFDC2626),
          ),
        ),
      );
    }

    return Text(
      value.isEmpty ? '—' : value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.outfit(
        fontSize: 12,
        color: const Color(0xFF1E293B),
      ),
    );
  }
}
