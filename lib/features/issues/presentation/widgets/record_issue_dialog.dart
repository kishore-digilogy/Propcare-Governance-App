import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

const _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _kWeekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// Dialog / Modal for "Record A Site Issue" (Matches Images 3 & 4)
class RecordIssueDialog extends StatefulWidget {
  final Function(Map<String, dynamic> payload) onSave;

  const RecordIssueDialog({
    super.key,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(Map<String, dynamic> payload) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RecordIssueDialog(onSave: onSave),
    );
  }

  @override
  State<RecordIssueDialog> createState() => _RecordIssueDialogState();
}

class _RecordIssueDialogState extends State<RecordIssueDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();

  String? _selectedSiteId;
  String? _selectedOwnerId;
  String _selectedPriority = 'MEDIUM';
  DateTime? _selectedDueDate;

  late MetaDataModel _meta;
  bool _isMetaLoaded = false;

  final List<String> _priorities = const ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  @override
  void initState() {
    super.initState();
    _meta = MetaService.instance.meta;
    _isMetaLoaded = MetaService.instance.isLoaded;

    // Default due date: tomorrow
    _selectedDueDate = DateTime.now().add(const Duration(days: 1));

    if (!_isMetaLoaded) {
      MetaService.instance.fetchMetadata().then((fresh) {
        if (mounted) {
          setState(() {
            _meta = fresh;
            _isMetaLoaded = true;
            _setDefaults();
          });
        }
      });
    } else {
      _setDefaults();
    }
  }

  void _setDefaults() {
    final live = _meta.liveSites;
    if (live.isNotEmpty && (_selectedSiteId == null || !live.any((s) => s.id == _selectedSiteId))) {
      _selectedSiteId = live.first.id;
    }
    if (_meta.users.isNotEmpty && _selectedOwnerId == null) {
      // Find admin or first user
      final adminUser = _meta.users
          .where((u) =>
              u.name.toLowerCase().contains('admin') ||
              u.role.toUpperCase() == 'CRRM' ||
              u.role.toUpperCase().contains('ADMIN'))
          .firstOrNull;
      _selectedOwnerId = adminUser?.id ?? _meta.users.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  String _formatDueDate(DateTime? dt) {
    if (dt == null) return 'Select date';
    final monthName = _kMonths[dt.month - 1];
    final weekday = _kWeekdays[dt.weekday - 1];
    return '${dt.day} $monthName ${dt.year} $weekday';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kBlue,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a site.')),
      );
      return;
    }
    if (_selectedOwnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an owner.')),
      );
      return;
    }

    final dueDateStr = _selectedDueDate != null
        ? _selectedDueDate!.toIso8601String().split('T').first
        : DateTime.now().toIso8601String().split('T').first;

    final payload = {
      'siteId': _selectedSiteId,
      'ownerId': _selectedOwnerId,
      'priority': _selectedPriority,
      'dueDate': dueDateStr,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      if (_actionController.text.trim().isNotEmpty)
        'initialAction': _actionController.text.trim(),
    };

    widget.onSave(payload);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sites = _meta.liveSites;
    final users = _meta.users;

    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom - 48;
    final dialogHeight = availableHeight.clamp(320.0, 720.0);
    final dialogWidth = (media.size.width - 32).clamp(280.0, 620.0);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Matches Image 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Record A Site Issue',
                      style: GoogleFonts.outfit(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _kSlate, size: 22),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: _kBorder),
                const SizedBox(height: 16),

                // Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Site Dropdown & Issue Title
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Site Dropdown (Searchable Image 4)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Site'),
                                  const SizedBox(height: 6),
                                  _buildSiteSelector(sites),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Issue Title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Issue Title'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _titleController,
                                    style: GoogleFonts.outfit(fontSize: 13),
                                    decoration: _inputDecoration(hint: 'Issue Title'),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Title is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 2: Description (Multiline)
                        _buildLabel('Description'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          style: GoogleFonts.outfit(fontSize: 13, height: 1.4),
                          decoration: _inputDecoration(hint: 'Description of the issue...'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Row 3: Priority & Owner Dropdown (Users from /meta)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Priority
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Priority'),
                                  const SizedBox(height: 6),
                                  CustomDropdownButton2<String>(
                                    selectedValue: _selectedPriority,
                                    buttonHeight: 44,
                                    maxHeight: 220,
                                    options: _priorities
                                        .map((p) => DropdownItemOption<String>(
                                              value: p,
                                              label: '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
                                            ))
                                        .toList(),
                                    onSelect: (val) {
                                      if (val != null) {
                                        setState(() => _selectedPriority = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Owner Dropdown (Shows Users in Owner Dropdown!)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Owner'),
                                  const SizedBox(height: 6),
                                  CustomDropdownButton2<String>(
                                    selectedValue: _selectedOwnerId,
                                    placeholder: 'Select Owner',
                                    buttonHeight: 44,
                                    maxHeight: 260,
                                    enableSearch: true,
                                    searchHint: 'Search user...',
                                    options: users
                                        .map((u) => DropdownItemOption<String>(
                                              value: u.id,
                                              label: u.displayWithRole,
                                            ))
                                        .toList(),
                                    onSelect: (val) {
                                      if (val != null) {
                                        setState(() => _selectedOwnerId = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 4: TAT Due Date & Initial Action Point
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TAT Due Date DatePicker
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('TAT Due Date'),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _kBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 15, color: _kBlue),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _formatDueDate(_selectedDueDate),
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0F172A),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_selectedDueDate != null)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() => _selectedDueDate = null);
                                              },
                                              child: const Icon(Icons.close_rounded, size: 16, color: _kSlate),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Initial Action Point (Optional)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Initial Action Point (Optional)'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _actionController,
                                    style: GoogleFonts.outfit(fontSize: 13),
                                    decoration: _inputDecoration(hint: 'e.g. Clean & inspect'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons (Cancel / Save changes)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: const Size(0, 42),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        minimumSize: const Size(0, 42),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save changes',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildSiteSelector(List<MetaSiteModel> sites) {
    final selectedSite = sites.where((s) => s.id == _selectedSiteId).firstOrNull;

    return InkWell(
      onTap: () => _openSearchableSitePicker(sites),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF818CF8)), // Indigo border matching Image 4
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedSite?.name ?? 'Select site...',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _kBlue),
          ],
        ),
      ),
    );
  }

  void _openSearchableSitePicker(List<MetaSiteModel> sites) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = query.trim().isEmpty
                ? sites
                : sites
                    .where((s) =>
                        s.name.toLowerCase().contains(query.toLowerCase()) ||
                        (s.code?.toLowerCase().contains(query.toLowerCase()) ?? false))
                    .toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: 380,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search Input matching Image 4 ("Search name or role...")
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder),
                        ),
                        child: TextField(
                          autofocus: true,
                          style: GoogleFonts.outfit(fontSize: 13),
                          onChanged: (val) {
                            setSheetState(() => query = val);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search name or role...',
                            hintStyle: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kSlate),
                            prefixIconConstraints: const BoxConstraints(minWidth: 28),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final site = filtered[idx];
                            final isChosen = site.id == _selectedSiteId;
                            return ListTile(
                              dense: true,
                              title: Text(
                                site.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                                  color: isChosen ? _kBlue : const Color(0xFF1E293B),
                                ),
                              ),
                              trailing: isChosen
                                  ? const Icon(Icons.check_rounded, color: _kBlue, size: 18)
                                  : null,
                              onTap: () {
                                setState(() => _selectedSiteId = site.id);
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(fontSize: 13, color: _kSlate.withValues(alpha: 0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
    );
  }
}

