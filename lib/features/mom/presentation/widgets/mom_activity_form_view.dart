import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/mom_activity_model.dart';
import '../../data/models/mom_by_site_model.dart';
import '../bloc/mom_bloc.dart';
import '../bloc/mom_event.dart';
import '../bloc/mom_state.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kAmber = Color(0xFFD97706);
const _kGreen = Color(0xFF16A34A);

/// View displaying the MOM Form (Pending mode like Image 1 or Sent mode like Image 3).
class MomActivityFormView extends StatefulWidget {
  final MomSiteItemModel site;
  final List<MomActivityModel> activities;
  final MomActivityModel activity;
  final bool isPendingMode;

  const MomActivityFormView({
    super.key,
    required this.site,
    required this.activities,
    required this.activity,
    required this.isPendingMode,
  });

  @override
  State<MomActivityFormView> createState() => _MomActivityFormViewState();
}

class _MomActivityFormViewState extends State<MomActivityFormView> {
  late final TextEditingController _subjectController;
  late final TextEditingController _closingController;
  late final TextEditingController _addToController;
  late final TextEditingController _addCcController;

  late List<String> _toList;
  late List<String> _ccList;
  late List<MomPointModel> _points;

  // Preset recipients suggestions for quick select
  final List<String> _suggestedRecipients = const [
    'prathap.p@digilogy.co',
    'admin@casagrand.co.in',
    'operations@casagrand.co.in',
  ];

  final List<String> _suggestedCc = const [
    'Site allocation',
    'HR & Compliance',
    'EHS Team',
    'Machine Maintenance',
    'm.karthikeyan@casagrand.co.in',
  ];

  @override
  void initState() {
    super.initState();
    _initFormData();
  }

  @override
  void didUpdateWidget(covariant MomActivityFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity.id != widget.activity.id ||
        oldWidget.isPendingMode != widget.isPendingMode) {
      _initFormData();
    }
  }

  void _initFormData() {
    final act = widget.activity;

    // Prefill To
    if (act.mom.to.isNotEmpty) {
      _toList = List.from(act.mom.to);
    } else {
      _toList = ['prathap.p@digilogy.co'];
    }

    // Prefill Cc
    if (act.mom.cc.isNotEmpty) {
      _ccList = List.from(act.mom.cc);
    } else {
      _ccList = ['m.karthikeyan@casagrand.co.in'];
    }

    // Prefill Subject
    final defaultSubject = act.mom.subject.isNotEmpty
        ? act.mom.subject
        : act.generateDefaultSubject(widget.site.siteName);
    _subjectController = TextEditingController(text: defaultSubject);

    // Prefill Points
    if (act.mom.points.isNotEmpty) {
      _points = act.mom.points.map((p) => p.copyWith()).toList();
    } else {
      // Default initial point row matching web
      _points = [
        MomPointModel(
          point: 'Ceiling Lights Free From Dust & Cobwebs — observation',
          targetDate: DateTime.now()
              .add(const Duration(days: 3))
              .toIso8601String()
              .split('T')
              .first,
        ),
      ];
    }

    // Prefill Closing Note
    final defaultClosing = act.mom.closing.isNotEmpty
        ? act.mom.closing
        : 'Next governance visit will follow the scheduled frequency. Action points are tracked in PropCare with owners and TAT.';
    _closingController = TextEditingController(text: defaultClosing);

    _addToController = TextEditingController();
    _addCcController = TextEditingController();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _closingController.dispose();
    _addToController.dispose();
    _addCcController.dispose();
    super.dispose();
  }

  void _addRecipient(String email) {
    final trimmed = email.trim();
    if (trimmed.isNotEmpty && !_toList.contains(trimmed)) {
      setState(() {
        _toList.add(trimmed);
        _addToController.clear();
      });
    }
  }

  void _addCc(String email) {
    final trimmed = email.trim();
    if (trimmed.isNotEmpty && !_ccList.contains(trimmed)) {
      setState(() {
        _ccList.add(trimmed);
        _addCcController.clear();
      });
    }
  }

  void _addNewPoint() {
    setState(() {
      final defaultTarget = DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String()
          .split('T')
          .first;
      _points.add(MomPointModel(point: '', targetDate: defaultTarget));
    });
  }

  void _removePoint(int index) {
    if (index >= 0 && index < _points.length) {
      setState(() {
        _points.removeAt(index);
      });
    }
  }

  Future<void> _pickTargetDate(int index) async {
    final currentStr = _points[index].targetDate;
    DateTime initial = DateTime.now().add(const Duration(days: 2));
    if (currentStr.isNotEmpty) {
      try {
        initial = DateTime.parse(currentStr);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
      final formatted = picked.toIso8601String().split('T').first;
      setState(() {
        _points[index] = _points[index].copyWith(targetDate: formatted);
      });
    }
  }

  void _sendMomEmail() {
    if (_toList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one recipient in "To".'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final payload = {
      'to': _toList,
      'cc': _ccList,
      'subject': _subjectController.text.trim(),
      'points': _points
          .where((p) => p.point.trim().isNotEmpty)
          .map((p) => p.toJson())
          .toList(),
      'closing': _closingController.text.trim(),
    };

    context.read<MomBloc>().add(
      SendMomEmailAction(activityId: widget.activity.id, payload: payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;
    final isPending = widget.isPendingMode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      children: [
        // ── Back Button: <- All sites ────────────────────────────────────────
        InkWell(
          onTap: () {
            context.read<MomBloc>().add(const BackToMomSitesList());
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16, color: _kBlue),
                const SizedBox(width: 6),
                Text(
                  'All sites',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Site Title & Subtitle ──────────────────────────────────────────
        Text(
          widget.site.siteName,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.site.formattedSubtitle,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: _kSlate,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),

        // ── Activity Selector Pills (if multiple activities exist) ───────────
        if (widget.activities.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.activities.map((a) {
                final isSelected = a.id == act.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '${a.title} (${a.code})',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: _kBlue,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? _kBlue : const Color(0xFFE2E8F0),
                    ),
                    onSelected: (val) {
                      if (val) {
                        context.read<MomBloc>().add(SelectMomActivity(a));
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── 1. Header Summary Table Row (Matching Web Top Strip) ─────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2EBF8)),
          ),
          child: Column(
            children: [
              // Header Row Labels
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Governance',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Role',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Visit date',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  Text(
                    'Status',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kSlate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Values Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      act.title,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      act.roleLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      act.formattedVisitDate,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isPending ? _kAmber : _kGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPending ? 'Pending' : 'Sent',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isPending ? _kAmber : _kGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── 2. Main Form Card (Matching Web Form Design) ─────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Title + Tag (Image 1 / Image 3)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      act.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPending ? 'Pending — Send Mail' : 'Sent',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPending ? _kBlue : _kGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── To Field ───────────────────────────────────────────────────
              _buildFieldLabel('To *'),
              const SizedBox(height: 6),
              if (isPending) ...[
                // Suggested Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        'Select recipients',
                        style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _kSlate,
                      ),
                      items: _suggestedRecipients.map((email) {
                        return DropdownMenuItem<String>(
                          value: email,
                          child: Text(
                            email,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _addRecipient(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Chips for added recipients
                if (_toList.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _toList.map((email) {
                      return Chip(
                        label: Text(
                          email,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        backgroundColor: const Color(0xFFEFF6FF),
                        side: const BorderSide(color: Color(0xFFDBEAFE)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        onDeleted: () {
                          setState(() {
                            _toList.remove(email);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                ],
                // Input to add custom recipient
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kBorder),
                        ),
                        child: TextField(
                          controller: _addToController,
                          style: GoogleFonts.outfit(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Add email...',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              color: _kSlate,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _addRecipient,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _addRecipient(_addToController.text),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Add',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Read-only To box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(
                    _toList.join(', '),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Cc Field ───────────────────────────────────────────────────
              _buildFieldLabel('Cc'),
              const SizedBox(height: 6),
              if (isPending) ...[
                // Suggested Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        'Site allocation · HR · EHS · Machine',
                        style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _kSlate,
                      ),
                      items: _suggestedCc.map((cc) {
                        return DropdownMenuItem<String>(
                          value: cc,
                          child: Text(
                            cc,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _addCc(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Chips for added CC
                if (_ccList.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _ccList.map((cc) {
                      return Chip(
                        label: Text(
                          cc,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        onDeleted: () {
                          setState(() {
                            _ccList.remove(cc);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                ],
                // Input to add custom CC
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kBorder),
                        ),
                        child: TextField(
                          controller: _addCcController,
                          style: GoogleFonts.outfit(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Add Cc email...',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              color: _kSlate,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _addCc,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _addCc(_addCcController.text),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Add',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Read-only CC box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(
                    _ccList.join(', '),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Subject Field ──────────────────────────────────────────────
              _buildFieldLabel('Subject *'),
              const SizedBox(height: 6),
              if (isPending)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: TextField(
                    controller: _subjectController,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(
                    _subjectController.text,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // ── MAJOR POINTS Table ─────────────────────────────────────────
              Text(
                'MAJOR POINTS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Point',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _kSlate,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Target',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _kSlate,
                              ),
                            ),
                          ),
                          if (isPending) const SizedBox(width: 32),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _kBorder),

                    // Table Rows
                    if (_points.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No major points added',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _kSlate,
                            ),
                          ),
                        ),
                      )
                    else
                      for (int i = 0; i < _points.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: _kBorder),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: isPending
                              ? Row(
                                  children: [
                                    // Point Input
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(color: _kBorder),
                                        ),
                                        child: TextFormField(
                                          initialValue: _points[i].point,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Observation / action',
                                            hintStyle: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: _kSlate,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (val) {
                                            _points[i] = _points[i].copyWith(
                                              point: val,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Target Date Picker Button
                                    Expanded(
                                      flex: 2,
                                      child: InkWell(
                                        onTap: () => _pickTargetDate(i),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(color: _kBorder),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                size: 14,
                                                color: _kBlue,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  _points[i]
                                                      .formattedTargetDate(),
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF1E293B,
                                                    ),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Trash Icon
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => _removePoint(i),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _points[i].point,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _points[i].formattedTargetDate(
                                          includeWeekday: false,
                                        ),
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Add Point Button (Only in Pending mode)
              if (isPending)
                OutlinedButton.icon(
                  onPressed: _addNewPoint,
                  icon: const Icon(Icons.add_rounded, size: 16, color: _kBlue),
                  label: Text(
                    'Add point',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Closing Note ───────────────────────────────────────────────
              _buildFieldLabel('Closing note'),
              const SizedBox(height: 6),
              if (isPending)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: TextField(
                    controller: _closingController,
                    maxLines: 4,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: const Color(0xFF0F172A),
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(
                    _closingController.text,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // ── Action Buttons Row ─────────────────────────────────────────
              BlocBuilder<MomBloc, MomState>(
                builder: (context, state) {
                  final isSending = state is MomLoaded && state.isSendingMom;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Open Activity Button
                      // OutlinedButton(
                      //   onPressed: () {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       SnackBar(
                      //         content: Text('Opening activity ${act.code}...'),
                      //         duration: const Duration(seconds: 1),
                      //       ),
                      //     );
                      //   },
                      //   style: OutlinedButton.styleFrom(
                      //     side: const BorderSide(color: Color(0xFFCBD5E1)),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 16,
                      //       vertical: 12,
                      //     ),
                      //   ),
                      //   child: Text(
                      //     'Open activity',
                      //     style: GoogleFonts.outfit(
                      //       fontSize: 13,
                      //       fontWeight: FontWeight.w600,
                      //       color: _kBlue,
                      //     ),
                      //   ),
                      // ),
                      if (isPending) ...[
                        const SizedBox(width: 12),
                        // Send MOM Email Button
                        ElevatedButton.icon(
                          onPressed: isSending ? null : _sendMomEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          icon: isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            isSending ? 'Sending...' : 'Send MOM email',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155),
      ),
    );
  }
}
