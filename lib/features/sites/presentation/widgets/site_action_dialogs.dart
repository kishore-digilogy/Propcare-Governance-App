import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/models/site_detail_model.dart';

const Color _kTeal = Color(0xFF0F766E);
const Color _kSlate = Color(0xFF64748B);
const Color _kDark = Color(0xFF0F172A);
const Color _kBorder = Color(0xFFE2E8F0);

/// Dialog matching Screenshot 3: Mark Special Attention
class SpecialAttentionDialog extends StatefulWidget {
  final SiteDetailModel site;
  final Function(DateTime fromDate, DateTime toDate, String reason) onConfirm;

  const SpecialAttentionDialog({
    super.key,
    required this.site,
    required this.onConfirm,
  });

  @override
  State<SpecialAttentionDialog> createState() => _SpecialAttentionDialogState();
}

class _SpecialAttentionDialogState extends State<SpecialAttentionDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    if (widget.site.specialReason != null && widget.site.specialReason!.isNotEmpty) {
      _reasonController.text = widget.site.specialReason!;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${weekdays[dt.weekday - 1]}';
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dialogWidth = (media.size.width - 32).clamp(280.0, 520.0);
    final maxDialogHeight = (media.size.height - media.viewInsets.bottom - 48).clamp(240.0, 680.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mark Special Attention',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: _kSlate),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Badge shows on this site only between the start and end dates. The Special filter on All Sites uses the same window.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _kSlate,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Start Date & End Date Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        _buildDateContainer(
                          text: _formatDate(_startDate),
                          onTap: () => _pickDate(true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End Date', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        _buildDateContainer(
                          text: _formatDate(_endDate),
                          onTap: () => _pickDate(false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reason
              Text('Reason', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Repeat client escalation on manpower and payroll for two consecutive cycles.',
                  hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kTeal, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final reason = _reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reason')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    widget.onConfirm(_startDate, _endDate, reason);
                  },
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDateContainer({required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500, color: _kDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog matching Screenshot 2: Client Type Update
class ClientTypeDialog extends StatefulWidget {
  final SiteDetailModel site;
  final Function(String clientType, String reason) onConfirm;

  const ClientTypeDialog({
    super.key,
    required this.site,
    required this.onConfirm,
  });

  @override
  State<ClientTypeDialog> createState() => _ClientTypeDialogState();
}

class _ClientTypeDialogState extends State<ClientTypeDialog> {
  late String _selectedType;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.site.clientType.toUpperCase();
    if (!['A+', 'A', 'B', 'C'].contains(_selectedType)) {
      _selectedType = 'A';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dialogWidth = (media.size.width - 32).clamp(280.0, 480.0);
    final maxDialogHeight = (media.size.height - media.viewInsets.bottom - 48).clamp(240.0, 680.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Client Type',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: _kSlate),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Current: ${widget.site.clientType} (Billing PM ${widget.site.formattedBillingPm})',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _kSlate,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Dropdown
              Text('Client Type', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              CustomDropdownButton2<String>(
                selectedValue: _selectedType,
                options: const [
                  DropdownItemOption(value: 'A+', label: 'A+'),
                  DropdownItemOption(value: 'A', label: 'A'),
                  DropdownItemOption(value: 'B', label: 'B'),
                  DropdownItemOption(value: 'C', label: 'C'),
                ],
                onSelect: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 16),

              // Reason
              Text('Reason', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kTeal, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mandatory — stored in audit trail',
                style: GoogleFonts.outfit(fontSize: 11.5, color: _kSlate),
              ),
              const SizedBox(height: 24),

              // Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final reason = _reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reason')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    widget.onConfirm(_selectedType, reason);
                  },
                  child: Text(
                    'Update client type',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

/// Dialog: Mark Inactive
class MarkInactiveDialog extends StatefulWidget {
  final SiteDetailModel site;
  final Function(String reason) onConfirm;

  const MarkInactiveDialog({
    super.key,
    required this.site,
    required this.onConfirm,
  });

  @override
  State<MarkInactiveDialog> createState() => _MarkInactiveDialogState();
}

class _MarkInactiveDialogState extends State<MarkInactiveDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dialogWidth = (media.size.width - 32).clamp(280.0, 480.0);
    final maxDialogHeight = (media.size.height - media.viewInsets.bottom - 48).clamp(240.0, 680.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mark Inactive',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: _kSlate),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to mark ${widget.site.name} (${widget.site.code}) as inactive?',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _kDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Reason
              Text('Reason', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mandatory — stored in audit trail',
                style: GoogleFonts.outfit(fontSize: 11.5, color: _kSlate),
              ),
              const SizedBox(height: 24),

              // Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final reason = _reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reason')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    widget.onConfirm(reason);
                  },
                  child: Text(
                    'Confirm Inactive',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

