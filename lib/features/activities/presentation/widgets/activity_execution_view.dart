import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/user_service.dart';
import '../../data/models/activity_detail_model.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';

// ── Blue & White Brand Color System ──────────────────────────────────────────
const Color _kHeaderDarkBlue = Color(0xFF0A1931); // deep navy
const Color _kHeaderMidBlue = Color(0xFF1B3A6B); // rich navy-blue
const Color _kPrimaryBlue = Color(0xFF1A73E8); // primary brand blue
const Color _kPrimaryDarkBlue = Color(0xFF1557B0); // pressed/hover blue
const Color _kLightBlue = Color(0xFFEFF6FF); // soft blue tint
const Color _kBorderBlue = Color(0xFFBFDBFE); // light blue border
const Color _kTextDarkBlue = Color(0xFF1E40AF); // dark blue text
const Color _kBg = Color(0xFFF8FAFC);
const Color _kCardBorder = Color(0xFFE2E8F0);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextSlate = Color(0xFF64748B);

class ActivityExecutionView extends StatefulWidget {
  final ActivityDetailModel activityDetail;
  final bool isSubmittingVisit;
  final bool isSendingMom;
  final VoidCallback onBack;
  final ActivitiesBloc bloc;

  const ActivityExecutionView({
    super.key,
    required this.activityDetail,
    required this.isSubmittingVisit,
    required this.isSendingMom,
    required this.onBack,
    required this.bloc,
  });

  @override
  State<ActivityExecutionView> createState() => _ActivityExecutionViewState();
}

class _ActivityExecutionViewState extends State<ActivityExecutionView> {
  int _currentStep = 0; // 0: Visit details, 1: MOM
  bool _isMasterExpanded = true;

  // Step 1: Visit details state
  late DateTime _visitDate;
  bool? _clientMet;
  late final TextEditingController _visitNoteController;

  // Step 2: MOM & Email state
  late final TextEditingController _subjectController;
  late final TextEditingController _closingController;
  late final TextEditingController _addToController;
  late final TextEditingController _addCcController;

  late List<String> _toList;
  late List<String> _ccList;
  late List<Map<String, String>> _points;

  // CC search filter
  String _ccSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final act = widget.activityDetail.activity;
    final site = widget.activityDetail.site;

    // Default to Step 1 unless already completed
    _currentStep = act.isCompleted ? 1 : 0;

    // Visit date parsing
    if (act.visitDate != null && act.visitDate!.isNotEmpty) {
      try {
        _visitDate = DateTime.parse(act.visitDate!);
      } catch (_) {
        _visitDate = DateTime.now();
      }
    } else {
      _visitDate = DateTime.now();
    }

    _clientMet = act.clientMet ?? false;
    _visitNoteController = TextEditingController(
      text: act.completionNote ?? '',
    );
    _visitNoteController.addListener(() {
      setState(() {});
    });

    // Step 2: MOM data
    final mom = act.mom;

    // TO recipients: default to site.contactEmails or site.clientEmail
    _toList = [];
    if (mom['to'] is List && (mom['to'] as List).isNotEmpty) {
      _toList = (mom['to'] as List).map((e) => e.toString()).toList();
    } else if (site.contactEmails.isNotEmpty) {
      _toList = [site.contactEmails.first.value];
    } else if (site.clientEmail != null && site.clientEmail!.isNotEmpty) {
      _toList = [site.clientEmail!];
    }

    // CC recipients: default to site.ccEmails
    _ccList = [];
    if (mom['cc'] is List && (mom['cc'] as List).isNotEmpty) {
      _ccList = (mom['cc'] as List).map((e) => e.toString()).toList();
    } else {
      _ccList = site.ccEmails.map((c) => c.value).take(4).toList();
    }

    // Subject
    final formattedDate = _formatDateShort(_visitDate);
    final defaultSubject = mom['subject']?.toString().isNotEmpty == true
        ? mom['subject'].toString()
        : 'Site walkaround MOM — ${site.name} — $formattedDate';
    _subjectController = TextEditingController(text: defaultSubject);

    // Points
    _points = [];
    if (mom['points'] is List && (mom['points'] as List).isNotEmpty) {
      for (final p in mom['points'] as List) {
        if (p is Map) {
          _points.add({
            'point': p['point']?.toString() ?? '',
            'targetDate': p['targetDate']?.toString() ?? '',
          });
        }
      }
    }

    // Closing Email Text
    final defaultClosing = mom['closing']?.toString().isNotEmpty == true
        ? mom['closing'].toString()
        : 'Next governance visit will follow the scheduled frequency. Action points are tracked in PropCare with owners and TAT.';
    _closingController = TextEditingController(text: defaultClosing);

    _addToController = TextEditingController();
    _addCcController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant ActivityExecutionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityDetail.activity.status !=
            widget.activityDetail.activity.status ||
        oldWidget.activityDetail.activity.isCompleted !=
            widget.activityDetail.activity.isCompleted) {
      if (widget.activityDetail.activity.isCompleted &&
          !oldWidget.activityDetail.activity.isCompleted) {
        setState(() {
          _currentStep = 1; // Auto advance to MOM step upon completion
        });
      }
    }
  }

  @override
  void dispose() {
    _visitNoteController.dispose();
    _subjectController.dispose();
    _closingController.dispose();
    _addToController.dispose();
    _addCcController.dispose();
    super.dispose();
  }

  String _formatDateShort(DateTime d) {
    const months = [
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatDateWithWeekday(DateTime d) {
    const months = [
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${days[d.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activityDetail.activity;
    final site = widget.activityDetail.site;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth >= 768;
        final isDesktop = screenWidth >= 992;

        return Stack(
          children: [
            // Bottom-right organic subtle blue decorative accent
            Positioned(
              right: 0,
              bottom: 0,
              width: isTablet ? 280 : 180,
              height: isTablet ? 70 : 45,
              child: IgnorePointer(
                child: CustomPaint(painter: _BottomCornerWavePainter()),
              ),
            ),

            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top Header with App Logo & Blue-White Wave ───────────
                  _buildHeader(act, site, isTablet),

                  // ── Body Content Container ────────────────────────────────
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop
                            ? 1160
                            : (isTablet ? 780 : double.infinity),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 14,
                          vertical: isTablet ? 18 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Two-Step Horizontal Stepper Bar ──────────────
                            _buildStepper(act, isTablet),
                            const SizedBox(height: 16),

                            // ── Main Content: 2-column on desktop, 1-column on mobile/tablet ──
                            if (isDesktop) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 62,
                                    child: _buildActiveStepForm(
                                      act,
                                      site,
                                      isTablet,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 38,
                                    child: _buildSidebarCards(
                                      act,
                                      site,
                                      isTablet,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              _buildActiveStepForm(act, site, isTablet),
                              const SizedBox(height: 18),
                              _buildCollapsibleActivityMasterCard(
                                act,
                                site,
                                isTablet,
                              ),
                              const SizedBox(height: 14),
                              _buildExecutionFlowCard(isTablet),
                            ],
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Top Header with App Logo, Back Breadcrumb, Title & Blue Curves ──────────
  Widget _buildHeader(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    final isAllCompleted = act.isMomSent || act.status == 'CLOSED';

    String primaryBtnText = '';
    VoidCallback? onPrimaryPressed;
    bool isPrimaryLoading = false;

    if (!act.isCompleted) {
      primaryBtnText = 'Submit visit';
      isPrimaryLoading = widget.isSubmittingVisit;
      onPrimaryPressed = widget.isSubmittingVisit ? null : _submitVisit;
    } else if (!act.isMomSent) {
      if (_currentStep == 0) {
        primaryBtnText = 'Proceed to MOM →';
        onPrimaryPressed = () => setState(() => _currentStep = 1);
      } else {
        primaryBtnText = 'Send MOM';
        isPrimaryLoading = widget.isSendingMom;
        onPrimaryPressed = widget.isSendingMom ? null : _sendMom;
      }
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kHeaderDarkBlue, _kHeaderMidBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Curved blue-white translucent wave overlay on right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: isTablet ? 360 : 220,
            child: IgnorePointer(
              child: CustomPaint(painter: _TopHeaderWavePainter()),
            ),
          ),

          // Header Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 32 : 16,
                12,
                isTablet ? 32 : 16,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Back button + Breadcrumb (Left) & App Logo (Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back Pill & Breadcrumb
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: widget.onBack,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Back',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Activities > ${act.code}',
                            style: GoogleFonts.outfit(
                              fontSize: isTablet ? 13.5 : 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),

                      // App Logo in top right
                      Image.asset(
                        'assets/icons/gov_icon_white.png',
                        height: isTablet ? 36 : 28,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title: e.g. "Field Executive Visit"
                  Text(
                    act.title,
                    style: GoogleFonts.outfit(
                      fontSize: isTablet ? 26 : 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Subtitle: "Mobile Testing · ACT-1016C · Weekly · SPOC Ramajayam"
                  Text(
                    '${site.name} · ${act.code} · ${act.frequencyLabel} · SPOC ${act.assignedToName ?? "Unassigned"}',
                    style: GoogleFonts.outfit(
                      fontSize: isTablet ? 13.5 : 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons Row: [📋 Save Draft] [✈ Submit Visit / Send MOM]
                  if (!isAllCompleted)
                    Row(
                      children: [
                        // Save Draft Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Draft saved locally'),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Save draft',
                              style: GoogleFonts.outfit(
                                fontSize: isTablet ? 13.5 : 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 13 : 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Primary Action Button (Solid White Button with Blue Text)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onPrimaryPressed,
                            icon: isPrimaryLoading
                                ? const SizedBox.shrink()
                                : const Icon(
                                    Icons.near_me_rounded,
                                    size: 16,
                                    color: _kHeaderDarkBlue,
                                  ),
                            label: isPrimaryLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _kHeaderDarkBlue,
                                    ),
                                  )
                                : Text(
                                    primaryBtnText,
                                    style: GoogleFonts.outfit(
                                      fontSize: isTablet ? 13.5 : 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: _kHeaderDarkBlue,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 13 : 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Two-Step Horizontal Stepper Bar (Blue & White) ──────────────────────────
  Widget _buildStepper(ActivityItemDetailModel act, bool isTablet) {
    final step1Completed = act.isCompleted;
    final step2Completed = act.isMomSent;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 22 : 16,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Step 1: Visit details
          InkWell(
            onTap: () => setState(() => _currentStep = 0),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: step1Completed
                        ? _kPrimaryBlue
                        : (_currentStep == 0
                              ? _kPrimaryBlue
                              : const Color(0xFFE2E8F0)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: step1Completed
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : Text(
                            '1',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _currentStep == 0
                                  ? Colors.white
                                  : _kTextSlate,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Visit details',
                  style: GoogleFonts.outfit(
                    fontSize: isTablet ? 13.5 : 12.5,
                    fontWeight: (_currentStep == 0 || step1Completed)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: (_currentStep == 0 || step1Completed)
                        ? _kPrimaryBlue
                        : _kTextSlate,
                    decoration: _currentStep == 0
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: _kPrimaryBlue,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
          ),

          // Connecting Line
          Expanded(
            child: Container(
              height: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: step1Completed ? _kPrimaryBlue : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Step 2: MOM
          InkWell(
            onTap: () {
              if (!step1Completed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please submit visit details first before proceeding to MOM.',
                    ),
                    backgroundColor: Color(0xFFD97706),
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              setState(() => _currentStep = 1);
            },
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: step2Completed
                        ? _kPrimaryBlue
                        : (!step1Completed
                              ? const Color(0xFFE2E8F0)
                              : (_currentStep == 1
                                    ? _kPrimaryBlue
                                    : const Color(0xFFF1F5F9))),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: step2Completed
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : Text(
                            '2',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !step1Completed
                                  ? const Color(0xFF94A3B8)
                                  : (_currentStep == 1
                                        ? Colors.white
                                        : _kTextSlate),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _currentStep == 1 ? 'MOM & Email' : 'MOM',
                  style: GoogleFonts.outfit(
                    fontSize: isTablet ? 13.5 : 12.5,
                    fontWeight: _currentStep == 1
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: step2Completed
                        ? _kPrimaryBlue
                        : (!step1Completed
                              ? const Color(0xFF94A3B8)
                              : (_currentStep == 1
                                    ? _kPrimaryBlue
                                    : _kTextSlate)),
                    decoration: _currentStep == 1
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: _kPrimaryBlue,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Switch between Step 1 and Step 2 Forms ────────────────────────────────
  Widget _buildActiveStepForm(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    if (_currentStep == 0) {
      return _buildStep1VisitDetails(act, isTablet);
    } else {
      return _buildStep2MomForm(act, site, isTablet);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // STEP 1: VISIT DETAILS (Blue & White)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStep1VisitDetails(ActivityItemDetailModel act, bool isTablet) {
    final isCompleted = act.isCompleted;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Blue Square Icon + Title + Status Badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kLightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: _kPrimaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '1. Visit details',
                  style: GoogleFonts.outfit(
                    fontSize: isTablet ? 17 : 15.5,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kLightBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorderBlue),
                ),
                child: Text(
                  isCompleted
                      ? 'Visit completed'
                      : 'Visit date required · Note optional',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kTextDarkBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Field 1: Visit date *
          Text(
            'Visit date *',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: isCompleted
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _visitDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _visitDate = picked);
                    }
                  },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: isCompleted
                        ? const Color(0xFF94A3B8)
                        : _kPrimaryBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatDateWithWeekday(_visitDate),
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? _kTextSlate : _kTextDark,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: isCompleted ? const Color(0xFF94A3B8) : _kTextSlate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Field 2: Client met *
          Text(
            'Client met *',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceButton(
                label: 'Yes',
                isSelected: _clientMet == true,
                isDisabled: isCompleted,
                onTap: () {
                  if (!isCompleted) setState(() => _clientMet = true);
                },
              ),
              const SizedBox(width: 12),
              _buildChoiceButton(
                label: 'No',
                isSelected: _clientMet == false,
                isDisabled: isCompleted,
                onTap: () {
                  if (!isCompleted) setState(() => _clientMet = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Field 3: Note (optional)
          Text(
            'Note (optional)',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _visitNoteController,
                        enabled: !isCompleted,
                        maxLines: 3,
                        maxLength: 500,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => const SizedBox.shrink(),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: _kTextDark,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Optional — visit notes, discussion points, client feedback...',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${_visitNoteController.text.length} / 500',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary Pill: 📍 Visit 20 Nov 2026 · Client met: No (Blue Tint)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kLightBlue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorderBlue),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: _kPrimaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCompleted
                        ? (act.isMomSent
                              ? 'Visit completed on ${_formatDateShort(_visitDate)} · Client met ${_clientMet == true ? "Yes" : "No"} · MOM completed'
                              : 'Visit completed on ${_formatDateShort(_visitDate)} · Client met ${_clientMet == true ? "Yes" : "No"}')
                        : 'Visit ${_formatDateShort(_visitDate)} · Client met: ${_clientMet == null ? "—" : (_clientMet! ? "Yes" : "No")}',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _kTextDarkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Full-width Bottom Action Button: ✈ Submit Visit (Primary Blue)
          SizedBox(
            width: double.infinity,
            child: isCompleted
                ? (!act.isMomSent
                      ? ElevatedButton.icon(
                          onPressed: () => setState(() => _currentStep = 1),
                          //icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                          label: Text(
                            'Proceed to MOM  →',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        )
                      : const SizedBox.shrink())
                : ElevatedButton.icon(
                    onPressed: widget.isSubmittingVisit ? null : _submitVisit,
                    icon: widget.isSubmittingVisit
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.near_me_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                    label: widget.isSubmittingVisit
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit visit',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Choice toggle button (Yes / No in Blue)
  Widget _buildChoiceButton({
    required String label,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _kPrimaryBlue : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // STEP 2: MOM & EMAIL FORM (Blue & White)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStep2MomForm(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Title + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2. MOM & Email',
                style: GoogleFonts.outfit(
                  fontSize: isTablet ? 17 : 15.5,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: act.isMomSent ? _kLightBlue : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: act.isMomSent
                        ? _kBorderBlue
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  act.isMomSent ? 'Sent' : 'Draft',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: act.isMomSent
                        ? _kPrimaryBlue
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Informational callout banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kLightBlue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorderBlue),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: _kPrimaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Minutes of meeting — ${site.name} · Client ${site.clientName}, ${_formatDateShort(_visitDate)}. Prepared after the visit is submitted.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: _kTextDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Field: To *
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 15,
                color: _kTextSlate,
              ),
              const SizedBox(width: 5),
              Text(
                'To *',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildRecipientSelector(
            isReadonly: act.isMomSent,
            currentList: _toList,
            options: site.contactEmails.isNotEmpty
                ? site.contactEmails
                : [
                    EmailRecipientModel(
                      value: site.clientEmail ?? 'client@example.com',
                      label:
                          '${site.contactPersonName ?? site.clientName} · ${site.clientEmail}',
                      name: site.contactPersonName ?? '',
                      role: 'CLIENT',
                    ),
                  ],
            onAdd: (val) {
              if (!_toList.contains(val)) setState(() => _toList.add(val));
            },
            onRemove: (val) => setState(() => _toList.remove(val)),
            customController: _addToController,
            hint:
                'Defaults to site contact person. Use Add email for additional To recipients.',
          ),
          const SizedBox(height: 18),

          // Field: Cc
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 15,
                color: _kTextSlate,
              ),
              const SizedBox(width: 5),
              Text(
                'Cc',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildCcRecipientSelector(site, isReadonly: act.isMomSent),
          const SizedBox(height: 18),

          // Field: Subject *
          Row(
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 15,
                color: _kTextSlate,
              ),
              const SizedBox(width: 5),
              Text(
                'Subject *',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectController,
            readOnly: act.isMomSent,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: act.isMomSent ? const Color(0xFF334155) : _kTextDark,
            ),
            decoration: InputDecoration(
              filled: act.isMomSent,
              fillColor: act.isMomSent ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: act.isMomSent
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: act.isMomSent
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Field: Major Points Header & Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 15,
                    color: _kTextSlate,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'MAJOR POINTS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (!act.isMomSent)
                InkWell(
                  onTap: () {
                    setState(() {
                      _points.add({
                        'point': '',
                        'targetDate': DateTime.now()
                            .add(const Duration(days: 7))
                            .toIso8601String()
                            .split('T')
                            .first,
                      });
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kLightBlue,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorderBlue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 13, color: _kPrimaryBlue),
                        const SizedBox(width: 3),
                        Text(
                          'Add point',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPointsTable(isReadonly: act.isMomSent),
          const SizedBox(height: 18),

          // Field: Email Closing Text
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: _kTextSlate,
              ),
              const SizedBox(width: 5),
              Text(
                'Email',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _closingController,
            readOnly: act.isMomSent,
            maxLines: 4,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: act.isMomSent ? const Color(0xFF334155) : _kTextDark,
            ),
            decoration: InputDecoration(
              filled: act.isMomSent,
              fillColor: act.isMomSent ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: act.isMomSent
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: act.isMomSent
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action: Send MOM (Primary Blue)
          SizedBox(
            width: double.infinity,
            child: act.isMomSent
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _kLightBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorderBlue),
                    ),
                    child: Center(
                      child: Text(
                        'MOM saved',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kPrimaryBlue,
                        ),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: widget.isSendingMom ? null : _sendMom,
                    icon: widget.isSendingMom
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.near_me_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                    label: widget.isSendingMom
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send MOM',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Recipient Selector for TO List (Blue) ───────────────────────────────────
  Widget _buildRecipientSelector({
    required bool isReadonly,
    required List<String> currentList,
    required List<EmailRecipientModel> options,
    required Function(String) onAdd,
    required Function(String) onRemove,
    required TextEditingController customController,
    required String hint,
  }) {
    final unaddedOptions = options
        .where((opt) => !currentList.contains(opt.value))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReadonly ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected chips
          if (currentList.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: currentList.map((email) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: _kLightBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kBorderBlue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _kTextDarkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isReadonly) ...[
                        const SizedBox(width: 5),
                        InkWell(
                          onTap: () => onRemove(email),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: _kTextDarkBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),

          if (!isReadonly) ...[
            if (currentList.isNotEmpty) const SizedBox(height: 10),

            // Inline input row for adding new email
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: customController,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: _kTextDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter email address...',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _kPrimaryBlue),
                        ),
                      ),
                      onSubmitted: (txt) {
                        final val = txt.trim();
                        if (val.isNotEmpty && !currentList.contains(val)) {
                          onAdd(val);
                          customController.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final txt = customController.text.trim();
                    if (txt.isNotEmpty && !currentList.contains(txt)) {
                      onAdd(txt);
                      customController.clear();
                    }
                  },
                  icon: const Icon(
                    Icons.person_add_alt_outlined,
                    size: 14,
                    color: _kPrimaryBlue,
                  ),
                  label: Text(
                    'Add email',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryBlue,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            // Quick suggestion chips for unadded site contacts (if any)
            if (unaddedOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Site contact: ',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: unaddedOptions.map((opt) {
                        return InkWell(
                          onTap: () => onAdd(opt.value),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 12,
                                  color: _kPrimaryBlue,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  opt.value,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: _kPrimaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Recipient Selector for CC List ──────────────────────────────────────────
  Widget _buildCcRecipientSelector(
    ActivitySiteDetailModel site, {
    required bool isReadonly,
  }) {
    final ccOptions = <EmailRecipientModel>[...site.ccEmails];

    final users = site.zoneId != null && site.zoneId!.isNotEmpty
        ? UserService.instance.getUsersByZone(site.zoneId!)
        : UserService.instance.users;

    for (final u in users) {
      if (u.email.isNotEmpty &&
          !ccOptions.any(
            (c) => c.value.toLowerCase() == u.email.toLowerCase(),
          )) {
        ccOptions.add(
          EmailRecipientModel(
            value: u.email,
            label: '${u.name} · ${u.roleLabel} · ${u.email}',
            name: u.name,
            role: u.role,
          ),
        );
      }
    }

    final filteredOptions = _ccSearchQuery.isEmpty
        ? ccOptions
        : ccOptions
              .where(
                (c) =>
                    c.label.toLowerCase().contains(
                      _ccSearchQuery.toLowerCase(),
                    ) ||
                    c.value.toLowerCase().contains(
                      _ccSearchQuery.toLowerCase(),
                    ),
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isReadonly ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected chips
              if (_ccList.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _ccList.map((email) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: _kLightBlue,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBorderBlue),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: _kTextDarkBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!isReadonly) ...[
                            const SizedBox(width: 5),
                            InkWell(
                              onTap: () =>
                                  setState(() => _ccList.remove(email)),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: _kTextDarkBlue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),

              if (!isReadonly) ...[
                const SizedBox(height: 10),

                // Search field for CC list
                SizedBox(
                  height: 36,
                  child: TextField(
                    style: GoogleFonts.outfit(fontSize: 12),
                    onChanged: (val) => setState(() => _ccSearchQuery = val),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      hintText: 'Search name or role in zone...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Checkbox items list
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredOptions.length,
                    itemBuilder: (ctx, i) {
                      final opt = filteredOptions[i];
                      final isSelected = _ccList.contains(opt.value);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _ccList.remove(opt.value);
                            } else {
                              _ccList.add(opt.value);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 18,
                                color: isSelected
                                    ? _kPrimaryBlue
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  opt.label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isReadonly) ...[
          const SizedBox(height: 8),

          // Custom CC Add row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _addCcController,
                    style: GoogleFonts.outfit(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Add new Cc email',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  final txt = _addCcController.text.trim();
                  if (txt.isNotEmpty && !_ccList.contains(txt)) {
                    setState(() {
                      _ccList.add(txt);
                      _addCcController.clear();
                    });
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: Text(
                  'Add',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Filtered for current zone (${site.zoneId ?? "all"}). Defaults to site allocation + HR / EHS / Machine.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }

  // ── Major Points Table ──────────────────────────────────────────────────────
  Widget _buildPointsTable({required bool isReadonly}) {
    if (_points.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              'No major points yet — click Add point.',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text(
                    'Point',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Target date',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isReadonly) const SizedBox(width: 32),
              ],
            ),
          ),
          ...List.generate(_points.length, (idx) {
            final p = _points[idx];
            final targetDateParsed = DateTime.tryParse(p['targetDate'] ?? '');
            final targetDateDisplay = targetDateParsed != null
                ? _formatDateShort(targetDateParsed)
                : (p['targetDate'] ?? '');

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: isReadonly
                        ? Text(
                            p['point'] ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: _kTextDark,
                            ),
                          )
                        : TextField(
                            controller: TextEditingController(text: p['point'])
                              ..selection = TextSelection.collapsed(
                                offset: (p['point'] ?? '').length,
                              ),
                            onChanged: (val) => p['point'] = val,
                            style: GoogleFonts.outfit(fontSize: 12.5),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              border: InputBorder.none,
                              hintText: 'Enter observation / action point...',
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: isReadonly
                        ? Text(
                            targetDateDisplay,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _kTextDark,
                            ),
                          )
                        : InkWell(
                            onTap: () async {
                              final cur =
                                  DateTime.tryParse(p['targetDate'] ?? '') ??
                                  DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: cur,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  p['targetDate'] = picked
                                      .toIso8601String()
                                      .split('T')
                                      .first;
                                });
                              }
                            },
                            child: Text(
                              p['targetDate']?.isNotEmpty == true
                                  ? p['targetDate']!
                                  : 'Pick date',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: _kPrimaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  if (!isReadonly)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: () => setState(() => _points.removeAt(idx)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // ACTIVITY MASTER & EXECUTION FLOW (Mobile & Tablet)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildCollapsibleActivityMasterCard(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible Header
          InkWell(
            onTap: () => setState(() => _isMasterExpanded = !_isMasterExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.layers_outlined,
                    size: 20,
                    color: _kPrimaryBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Activity master',
                      style: GoogleFonts.outfit(
                        fontSize: isTablet ? 16 : 14.5,
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryBlue,
                      ),
                    ),
                  ),
                  Icon(
                    _isMasterExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: _kTextSlate,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Body
          if (_isMasterExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildMasterRow('Activity ID', act.code),
                  _buildMasterRow('Site', site.name),
                  _buildMasterRow('Category / function', act.functionLabel),
                  _buildMasterRow('Role', act.roleLabel),
                  _buildMasterRow('SPOC', act.assignedToName ?? 'Unassigned'),
                  _buildMasterRow('Client type', act.clientType),
                  _buildMasterRow('Frequency', act.frequencyLabel),
                  _buildMasterRow('Scheduled', act.scheduledDate ?? '—'),
                  _buildMasterRow('Due', act.dueDate ?? '—'),
                  _buildMasterRow(
                    'Attendance',
                    'See Attendance',
                    isLink: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Attendance is under progress',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _buildMasterRow(
                    'Current step',
                    _currentStep == 0 ? 'Visit details' : 'MOM',
                  ),
                  _buildMasterRow(
                    'Status',
                    act.isMomSent ? 'Completed' : act.statusLabel,
                    statusColor: (act.isCompleted || act.isMomSent)
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExecutionFlowCard(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Execution flow',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kLightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '1. Visit details and 2. MOM can be opened independently. Attendance is marked under Attendance.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: _kTextDarkBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar cards on wide desktop screens
  Widget _buildSidebarCards(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    return Column(
      children: [
        _buildCollapsibleActivityMasterCard(act, site, isTablet),
        const SizedBox(height: 16),
        _buildExecutionFlowCard(isTablet),
      ],
    );
  }

  Widget _buildMasterRow(
    String label,
    String value, {
    bool isLink = false,
    Color? statusColor,
    VoidCallback? onTap,
  }) {
    final textStyle = GoogleFonts.outfit(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: statusColor ?? (isLink ? _kPrimaryBlue : _kTextDark),
      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
      decorationColor: _kPrimaryBlue,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: _kTextSlate,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onTap != null)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(value, style: textStyle),
              ),
            )
          else
            Text(value, style: textStyle),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // DIALOGS & ACTIONS
  // ═════════════════════════════════════════════════════════════════════════════
  void _submitVisit() {
    _showSubmitVisitDialog();
  }

  void _showSubmitVisitDialog() {
    final visitDateStr = _visitDate.toIso8601String().split('T').first;
    final formattedDateText = _formatDateShort(_visitDate);
    final noteText = _visitNoteController.text.trim();
    final clientMetVal = _clientMet ?? false;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Submit Visit',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visit Date',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          formattedDateText,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Client Met',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        clientMetVal ? 'Yes' : 'No',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: clientMetVal
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          noteText.isNotEmpty ? noteText : '—',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _kLightBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorderBlue),
                    ),
                    child: Text(
                      'After Submit You Will Move To MOM & Email To Send The Client Communication.',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _kTextDarkBlue,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'Back',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _dispatchSubmitVisit(
                              visitDateStr,
                              clientMetVal,
                              noteText,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Complete → Send MOM',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _dispatchSubmitVisit(
    String visitDateStr,
    bool clientMetVal,
    String noteText,
  ) {
    widget.bloc.add(
      SubmitActivityVisit(
        activityId: widget.activityDetail.activity.id,
        visitDate: visitDateStr,
        clientMet: clientMetVal,
        note: noteText,
        answers: const [],
        findings: const [],
      ),
    );
  }

  void _sendMom() {
    if (!widget.activityDetail.activity.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please submit visit details first before sending MOM.',
          ),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      setState(() => _currentStep = 0);
      return;
    }

    final payload = {
      'to': _toList,
      'cc': _ccList,
      'subject': _subjectController.text.trim(),
      'points': _points,
      'closing': _closingController.text.trim(),
    };
    widget.bloc.add(
      SendActivityMomEmail(
        activityId: widget.activityDetail.activity.id,
        payload: payload,
      ),
    );
  }
}

// ── Top Header Custom Painter: Blue & White translucent curves ───────────────
class _TopHeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(size.width * 0.25, 0);
    path1.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.35,
      size.width,
      size.height * 0.58,
    );
    path1.lineTo(size.width, 0);
    path1.close();

    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.45, 0);
    path2.quadraticBezierTo(
      size.width * 0.72,
      size.height * 0.22,
      size.width,
      size.height * 0.38,
    );
    path2.lineTo(size.width, 0);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bottom Corner Custom Painter: Subtle Blue curve ──────────────────────────
class _BottomCornerWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDBEAFE).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.95,
      size.width,
      size.height * 0.45,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
