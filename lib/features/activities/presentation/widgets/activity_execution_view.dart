import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/activity_detail_model.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';
import '../../../../core/widgets/app_snack_bar.dart';

// ── Blue & White Brand Color System ──────────────────────────────────────────
const Color _kLightBlue = Color(0xFFEDF4FF); // soft blue tint
const Color _kBorderBlue = Color(0xFFDCE3EC); // light blue border
const Color _kTextDarkBlue = Color(0xFF1769E8); // dark blue text
const Color _kBg = Color(0xFFF5F7FA); // Modern minimal light grey bg
const Color _kTextDark = Color(0xFF17243A);

// Modern Minimal – Professional Blue Palette
const Color _kPrimary = Color(0xFF1769E8);
const Color _kTextPrimary = Color(0xFF17243A);
const Color _kTextSecondary = Color(0xFF718096);
const Color _kBorderColor = Color(0xFFDCE3EC);
const Color _kLightBlueBg = Color(0xFFEDF4FF);

const List<String> _kDepartments = [
  'Operations',
  'HR',
  'EHS',
  'L&D',
  'Technical',
  'Sales',
];

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
  int _currentStep = 0; // 0: Walk Around Checklist & Visit details, 1: MOM
  int _momSubTab = 0; // 0: MOM, 1: Action Points
  bool _hasAttemptedSubmit = false;

  // Step 1: Visit details & Checklist state
  late DateTime _visitDate;
  bool? _clientMet;
  late final TextEditingController _visitNoteController;
  final Map<String, String> _checklistStatus = {}; // key -> 'OK' | 'ISSUE' | 'NA'
  final Map<String, TextEditingController> _remarksControllers = {}; // key -> TextEditingController

  // Step 2: MOM & Email state
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  late final TextEditingController _meetingAttendeesController;
  late final TextEditingController _clientAttendeesController;
  late final TextEditingController _closingController;
  late final TextEditingController _addToController;
  late final TextEditingController _addCcController;

  late List<String> _toList;
  late List<String> _ccList;
  late List<Map<String, String>> _points;

  // CC search filter
  String _ccSearchQuery = '';
  bool _showAddToInput = false;

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
    _momSubTab = act.isMomSent ? 1 : 0;

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

    // Populate checklist status & remarks
    _checklistStatus.clear();
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    _remarksControllers.clear();

    final answersMap = {for (final a in act.answers) a.key: a};
    for (final item in act.template) {
      final existingAns = answersMap[item.key];
      if (existingAns != null && existingAns.status.isNotEmpty) {
        _checklistStatus[item.key] = existingAns.status;
        final ctrl = TextEditingController(text: existingAns.remarks);
        ctrl.addListener(() {
          if (mounted) setState(() {});
        });
        _remarksControllers[item.key] = ctrl;
      } else {
        _checklistStatus[item.key] = 'OK'; // default to OK ('Yes')
        final ctrl = TextEditingController(text: '');
        ctrl.addListener(() {
          if (mounted) setState(() {});
        });
        _remarksControllers[item.key] = ctrl;
      }
    }

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
        : 'Site walkaround MOM - ${site.name} - $formattedDate';
    _subjectController = TextEditingController(text: defaultSubject);

    // Body & Attendees
    _bodyController = TextEditingController(text: mom['body']?.toString() ?? '');
    _meetingAttendeesController = TextEditingController(
      text: mom['meetingAttendees']?.toString() ?? '',
    );
    _clientAttendeesController = TextEditingController(
      text: mom['clientAttendees']?.toString() ?? '',
    );

    // Points
    _points = [];
    if (mom['points'] is List && (mom['points'] as List).isNotEmpty) {
      for (final p in mom['points'] as List) {
        if (p is Map) {
          _points.add({
            'point': p['point']?.toString() ?? '',
            'department': p['department']?.toString() ?? 'Operations',
            'targetDate': p['targetDate']?.toString() ?? '',
          });
        }
      }
    }
    if (_points.isEmpty && act.momPoints.isNotEmpty) {
      for (final mp in act.momPoints) {
        _points.add({
          'point': mp.point,
          'department': mp.department.isNotEmpty ? mp.department : 'Operations',
          'targetDate': mp.targetDate,
        });
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
    final oldAct = oldWidget.activityDetail.activity;
    final newAct = widget.activityDetail.activity;

    if (oldAct.status != newAct.status ||
        oldAct.isCompleted != newAct.isCompleted ||
        oldAct.isMomSent != newAct.isMomSent ||
        oldAct.momPoints != newAct.momPoints) {
      if (newAct.isCompleted && !oldAct.isCompleted) {
        setState(() {
          _currentStep = 1;
        });
      }
      if (newAct.isMomSent && !oldAct.isMomSent) {
        setState(() {
          _momSubTab = 1;
        });
      }
      if (newAct.momPoints.isNotEmpty && _points.isEmpty) {
        for (final mp in newAct.momPoints) {
          _points.add({
            'point': mp.point,
            'department': mp.department.isNotEmpty ? mp.department : 'Operations',
            'targetDate': mp.targetDate,
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _visitNoteController.dispose();
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    _subjectController.dispose();
    _bodyController.dispose();
    _meetingAttendeesController.dispose();
    _clientAttendeesController.dispose();
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
    return '${d.day} ${months[d.month - 1]} ${d.year} ${days[d.weekday - 1].toUpperCase()}';
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

        return Container(
          color: _kBg,
          child: Stack(
            children: [
              // Bottom-right subtle accent
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
                    // Top Header
                    _buildHeader(act, site, isTablet),

                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop
                              ? 1180
                              : (isTablet ? 820 : double.infinity),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 14,
                            vertical: isTablet ? 18 : 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stepper (Walk Around Checklist ────── MOM)
                              _buildStepper(act, isTablet),
                              const SizedBox(height: 18),

                              // Main Form Area
                              if (isDesktop) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 64,
                                      child: _buildActiveStepForm(
                                        act,
                                        site,
                                        isTablet,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 36,
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
          ),
        );
      },
    );
  }

  // ── Header: Modern, Adaptive & Touch-Optimized ────────────────────────────
  Widget _buildHeader(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    final isAllCompleted = act.isMomSent || act.status == 'CLOSED';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 32 : 16,
        14,
        isTablet ? 32 : 16,
        16,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Bar: Back button on Left, Status Badge on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back & Breadcrumb
                Expanded(
                  child: Row(
                    children: [
                      InkWell(
                        onTap: widget.onBack,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_rounded,
                                size: 15,
                                color: _kPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Back',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Activities > ${act.code}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _kTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Top Right: Actions on Desktop/Tablet, Status Pill on Mobile
                if (isTablet)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isAllCompleted) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Draft saved locally'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_border_rounded, size: 15),
                          label: Text(
                            'Save Draft',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (_currentStep == 0 && !act.isCompleted)
                        ElevatedButton.icon(
                          onPressed: widget.isSubmittingVisit ? null : _submitVisit,
                          icon: widget.isSubmittingVisit
                              ? const SizedBox.shrink()
                              : const Icon(Icons.arrow_forward_rounded, size: 15),
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
                                  'Complete → Send MOM',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      else if (_currentStep == 1 && !act.isMomSent)
                        ElevatedButton.icon(
                          onPressed: widget.isSendingMom ? null : _sendMom,
                          icon: widget.isSendingMom
                              ? const SizedBox.shrink()
                              : const Icon(Icons.send_rounded, size: 15),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  // Mobile Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAllCompleted
                          ? const Color(0xFFDCFCE7)
                          : (act.isCompleted ? _kLightBlueBg : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAllCompleted
                          ? 'Completed'
                          : (act.isCompleted ? 'MOM Pending' : 'Assigned'),
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isAllCompleted
                            ? const Color(0xFF16A34A)
                            : (act.isCompleted ? _kPrimary : const Color(0xFFD97706)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Title & Role Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    act.title,
                    style: GoogleFonts.outfit(
                      fontSize: isTablet ? 23 : 19,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Text(
                    act.roleLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Metadata Chips Wrap
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildHeaderMetaChip(Icons.business_outlined, site.name),
                _buildHeaderMetaChip(Icons.confirmation_number_outlined, act.code),
                _buildHeaderMetaChip(Icons.repeat_rounded, act.frequencyLabel),
                _buildHeaderMetaChip(
                  Icons.person_outline_rounded,
                  'SPOC ${act.assignedToName ?? "Unassigned"}',
                ),
              ],
            ),

            // Mobile-Optimized Action Buttons Row (Placed cleanly below metadata on mobile)
            if (!isTablet && !isAllCompleted) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Draft saved locally'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save Draft',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: _currentStep == 0 && !act.isCompleted
                        ? ElevatedButton(
                            onPressed: widget.isSubmittingVisit ? null : _submitVisit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: widget.isSubmittingVisit
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Complete → Send MOM',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          )
                        : ElevatedButton(
                            onPressed: widget.isSendingMom ? null : _sendMom,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: widget.isSendingMom
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
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: _kTextSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: _kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
  // ── Stepper matching Image 1 & 2 ──────────────────────────────────────────
  Widget _buildStepper(ActivityItemDetailModel act, bool isTablet) {
    final step1Done = act.isCompleted;
    final step2Done = act.isMomSent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorderColor),
      ),
      child: Row(
        children: [
          // Step 1: Walk Around Checklist
          InkWell(
            onTap: () {
              setState(() => _currentStep = 0);
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step1Done
                        ? const Color(0xFF16A34A)
                        : (_currentStep == 0 ? _kPrimary : const Color(0xFFE2E8F0)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: step1Done
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '1',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _currentStep == 0 ? Colors.white : _kTextSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isTablet ? 'Walk Around Checklist' : 'Checklist',
                  style: GoogleFonts.outfit(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: _currentStep == 0 ? FontWeight.w700 : FontWeight.w500,
                    color: _currentStep == 0 ? _kTextPrimary : _kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Connector line
          Expanded(
            child: Container(
              height: 2,
              color: step1Done ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(width: 16),
          // Step 2: MOM
          InkWell(
            onTap: () {
              if (!act.isCompleted) {
                AppSnackBar.warning(
                  context,
                  message: 'Please submit visit details first before proceeding to MOM.',
                );
                return;
              }
              setState(() => _currentStep = 1);
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step2Done
                        ? const Color(0xFF16A34A)
                        : (_currentStep == 1 ? _kPrimary : const Color(0xFFE2E8F0)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: step2Done
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '2',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _currentStep == 1 ? Colors.white : _kTextSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isTablet ? 'MOM & Email' : 'MOM',
                  style: GoogleFonts.outfit(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: _currentStep == 1 ? FontWeight.w700 : FontWeight.w500,
                    color: _currentStep == 1 ? _kTextPrimary : _kTextSecondary,
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
  // STEP 1: WALK AROUND CHECKLIST & VISIT DETAILS (Matching Image 1)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStep1VisitDetails(ActivityItemDetailModel act, bool isTablet) {
    final isCompleted = act.isCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: 1. Walk Around Checklist · [Role] ──
        Container(
          padding: EdgeInsets.all(isTablet ? 22 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '1. Walk Around Checklist · ${act.role}',
                          style: GoogleFonts.outfit(
                            fontSize: isTablet ? 16 : 15,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${act.template.length} Items',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _kTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Loaded From Master Data · Yes / No / NA · Remarks On No',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Checklist Table
              if (act.template.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Text(
                    'No checklist items configured for this activity.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: _kTextSecondary,
                    ),
                  ),
                )
              else
                _buildChecklistTable(act, isCompleted, isTablet),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Card 2: 2. Visit Details ──
        Container(
          padding: EdgeInsets.all(isTablet ? 22 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '2. Visit Details',
                    style: GoogleFonts.outfit(
                      fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _kLightBlueBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Visit Date Required · Note Optional',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visit Date *
              Text(
                'Visit Date *',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: isCompleted ? null : () => _pickVisitDate(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: _kPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatDateWithWeekday(_visitDate),
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary,
                          ),
                        ),
                      ),
                      if (!isCompleted)
                        const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: _kTextSecondary,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Client Met *
              Text(
                'Client Met *',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildOptionChip(
                    label: 'Yes',
                    isSelected: _clientMet == true,
                    onTap: isCompleted
                        ? null
                        : () => setState(() => _clientMet = true),
                  ),
                  const SizedBox(width: 10),
                  _buildOptionChip(
                    label: 'No',
                    isSelected: _clientMet == false,
                    onTap: isCompleted
                        ? null
                        : () => setState(() => _clientMet = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note (Optional)
              Text(
                'Note (Optional)',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _visitNoteController,
                readOnly: isCompleted,
                maxLines: 3,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: _kTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Optional - Visit Notes, Discussion Points, Client Feedback...',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: _kTextSecondary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Checklist Table Widget (Area, Status: Yes/No/NA, Remarks) ─────────────
  Widget _buildChecklistTable(
    ActivityItemDetailModel act,
    bool isCompleted,
    bool isTablet,
  ) {
    // ── MOBILE: Card/Stack Layout (Zero Horizontal Overflow, 100% Responsive) ──
    if (!isTablet) {
      return Column(
        children: List.generate(act.template.length, (idx) {
          final item = act.template[idx];
          final status = _checklistStatus[item.key] ?? 'OK';
          final remarksCtrl = _remarksControllers[item.key]!;
          final isNo = status == 'ISSUE';
          final isMissingRemarks = _hasAttemptedSubmit && isNo && remarksCtrl.text.trim().isEmpty;

          return Container(
            margin: EdgeInsets.only(bottom: idx == act.template.length - 1 ? 0 : 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMissingRemarks
                  ? const Color(0xFFFEF2F2)
                  : (isNo ? const Color(0xFFFFF7F7) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMissingRemarks
                    ? const Color(0xFFEF4444)
                    : (isNo ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
                width: isMissingRemarks ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Area Title Row with index badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMissingRemarks
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${idx + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isMissingRemarks ? const Color(0xFFDC2626) : _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom Row: Status choices on left, Remarks input on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Segmented Choices: Yes / No / NA
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMissingRemarks
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCompactSegmentChip(
                            label: 'Yes',
                            isSelected: status == 'OK',
                            activeColor: const Color(0xFF16A34A),
                            onTap: isCompleted
                                ? null
                                : () => setState(() => _checklistStatus[item.key] = 'OK'),
                          ),
                          _buildCompactSegmentChip(
                            label: 'No',
                            isSelected: status == 'ISSUE',
                            activeColor: const Color(0xFFDC2626),
                            onTap: isCompleted
                                ? null
                                : () => setState(() => _checklistStatus[item.key] = 'ISSUE'),
                          ),
                          _buildCompactSegmentChip(
                            label: 'NA',
                            isSelected: status == 'NA',
                            activeColor: const Color(0xFF64748B),
                            onTap: isCompleted
                                ? null
                                : () => setState(() => _checklistStatus[item.key] = 'NA'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Remarks field
                    Expanded(
                      child: TextField(
                        controller: remarksCtrl,
                        readOnly: isCompleted,
                        style: GoogleFonts.outfit(fontSize: 12),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: isMissingRemarks
                              ? 'Remarks mandatory *'
                              : (isNo ? 'Remarks required *' : 'Optional remarks'),
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: isMissingRemarks ? FontWeight.w600 : FontWeight.w400,
                            color: isMissingRemarks
                                ? const Color(0xFFDC2626)
                                : _kTextSecondary.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isMissingRemarks
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFCBD5E1),
                              width: isMissingRemarks ? 1.5 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isMissingRemarks
                                  ? const Color(0xFFEF4444)
                                  : (isNo ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1)),
                              width: isMissingRemarks ? 1.5 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isMissingRemarks ? const Color(0xFFDC2626) : _kPrimary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Inline Error Message if missing remarks
                if (isMissingRemarks)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 13,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Remarks are mandatory when marked as "No"',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
      );
    }

    // ── TABLET / DESKTOP: 3-Column Table ─────────────────────────────────────
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorderColor),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'AREA',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(
                    'STATUS',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(
                    'REMARKS',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Rows
          ...List.generate(act.template.length, (idx) {
            final item = act.template[idx];
            final status = _checklistStatus[item.key] ?? 'OK';
            final remarksCtrl = _remarksControllers[item.key]!;
            final isNo = status == 'ISSUE';
            final isMissingRemarks = _hasAttemptedSubmit && isNo && remarksCtrl.text.trim().isEmpty;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMissingRemarks ? const Color(0xFFFEF2F2) : Colors.transparent,
                border: Border(
                  top: idx > 0
                      ? BorderSide(
                          color: isMissingRemarks
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFF1F5F9),
                        )
                      : BorderSide.none,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusSegmentChip(
                          label: 'Yes',
                          isSelected: status == 'OK',
                          activeColor: const Color(0xFF16A34A),
                          onTap: isCompleted
                              ? null
                              : () => setState(() => _checklistStatus[item.key] = 'OK'),
                        ),
                        const SizedBox(width: 4),
                        _buildStatusSegmentChip(
                          label: 'No',
                          isSelected: status == 'ISSUE',
                          activeColor: const Color(0xFFDC2626),
                          onTap: isCompleted
                              ? null
                              : () => setState(() => _checklistStatus[item.key] = 'ISSUE'),
                        ),
                        const SizedBox(width: 4),
                        _buildStatusSegmentChip(
                          label: 'NA',
                          isSelected: status == 'NA',
                          activeColor: const Color(0xFF64748B),
                          onTap: isCompleted
                              ? null
                              : () => setState(() => _checklistStatus[item.key] = 'NA'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: remarksCtrl,
                          readOnly: isCompleted,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: _kTextPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: isMissingRemarks
                                ? 'Remarks mandatory *'
                                : (isNo ? 'Remarks required *' : 'Optional'),
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: isMissingRemarks ? FontWeight.w600 : FontWeight.w400,
                              color: isMissingRemarks
                                  ? const Color(0xFFDC2626)
                                  : _kTextSecondary.withValues(alpha: 0.6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isMissingRemarks
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFE2E8F0),
                                width: isMissingRemarks ? 1.5 : 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isMissingRemarks
                                    ? const Color(0xFFEF4444)
                                    : (isNo ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
                                width: isMissingRemarks ? 1.5 : 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isMissingRemarks ? const Color(0xFFDC2626) : _kPrimary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        if (isMissingRemarks)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              'Remarks required for "No"',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactSegmentChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : _kTextSecondary,
          ),
        ),
      ),
    );
  }
  Widget _buildStatusSegmentChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeColor : _kTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _kLightBlueBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _kPrimary : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? _kPrimary : _kTextPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _pickVisitDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _visitDate = picked;
      });
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // STEP 2: MOM & EMAIL & ACTION POINTS (Matching Images 2, 3, 4, 5)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStep2MomForm(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "2. MOM & Email" + "Draft" or "Sent" badge
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '2. MOM & Email',
                style: GoogleFonts.outfit(
                  fontSize: isTablet ? 17 : 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: act.isMomSent
                      ? const Color(0xFFDCFCE7)
                      : _kLightBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  act.isMomSent ? 'Sent' : 'Draft',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: act.isMomSent ? const Color(0xFF16A34A) : _kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Minutes Of Meeting - ${site.name} · Client ${site.clientName}, ${_formatDateShort(_visitDate)}. Prepared After The Visit Is Submitted.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: _kTextSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Sub-tabs: [ MOM ] and [ Action Points 1/2 ]
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _momSubTab = 0),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _momSubTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _momSubTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        isTablet ? 'MOM & Email' : 'MOM',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _momSubTab == 0 ? _kPrimary : _kTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => setState(() => _momSubTab = 1),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _momSubTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _momSubTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Action Points ${act.completedPoints}/${act.totalPoints}',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _momSubTab == 1 ? _kPrimary : _kTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Content based on sub-tab
          if (_momSubTab == 0)
            _buildMomTabContent(act, site, isTablet)
          else
            _buildActionPointsTabContent(act, isTablet),
        ],
      ),
    );
  }

  // ── MOM Sub-tab Content (To, Cc, Subject, Body, Attendees, Points, Closing) ──
  Widget _buildMomTabContent(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field: To *
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
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 16),

        // Field: Cc
        _buildCcRecipientSelector(site, isReadonly: act.isMomSent),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 16),

        // Field: Subject *
        Text(
          'Subject *',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _subjectController,
          readOnly: act.isMomSent,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: _kTextPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Field: Body
        Text(
          'Body',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _bodyController,
          readOnly: act.isMomSent,
          maxLines: 3,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: _kTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'E.G. Dear HR / L&D,',
            hintStyle: GoogleFonts.outfit(
              fontSize: 12.5,
              color: _kTextSecondary.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Meeting Attendees
        Text(
          'Meeting Attendees',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _meetingAttendeesController,
          readOnly: act.isMomSent,
          style: GoogleFonts.outfit(fontSize: 13, color: _kTextPrimary),
          decoration: InputDecoration(
            hintText: 'Names Of People Who Attended This Meeting',
            hintStyle: GoogleFonts.outfit(
              fontSize: 12.5,
              color: _kTextSecondary.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Client Attendees
        Text(
          'Client Attendees',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _clientAttendeesController,
          readOnly: act.isMomSent,
          style: GoogleFonts.outfit(fontSize: 13, color: _kTextPrimary),
          decoration: InputDecoration(
            hintText: 'Client Attendees...',
            hintStyle: GoogleFonts.outfit(
              fontSize: 12.5,
              color: _kTextSecondary.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Points Discussed Header & Table (Images 4 & 5)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'POINTS DISCUSSED',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!act.isMomSent)
              InkWell(
                onTap: () {
                  setState(() {
                    _points.add({
                      'point': '',
                      'department': 'Operations',
                      'targetDate': DateTime.now()
                          .add(const Duration(days: 7))
                          .toIso8601String()
                          .split('T')
                          .first,
                    });
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _kLightBlueBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD0E1FD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14, color: _kPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Add Point',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _buildPointsTable(isReadonly: act.isMomSent, isTablet: isTablet),
        const SizedBox(height: 20),

        // Closing Remarks
        Text(
          'Closing Remarks',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _closingController,
          readOnly: act.isMomSent,
          maxLines: 3,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: _kTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Closing text for MOM email...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Bottom Action Row: [ Save Draft ]  [ Send MOM ]
        if (act.isMomSent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                Text(
                  'MOM Email Sent to Recipients',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Draft saved locally')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Save Draft',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isSendingMom ? null : _sendMom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: widget.isSendingMom
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Send MOM',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Action Points Sub-tab (Image 3: Metric Cards + Status Toggle Table) ────
  Widget _buildActionPointsTabContent(
    ActivityItemDetailModel act,
    bool isTablet,
  ) {
    final points = act.momPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 Metric Cards Row (All, Pending, Completed)
        Row(
          children: [
            // All
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All',
                      style: GoogleFonts.outfit(
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.w500,
                        color: _kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${act.totalPoints}',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: isTablet ? 10 : 8),

            // Pending (Amber)
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Pending',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFFD97706),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${act.pendingPoints}',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: isTablet ? 10 : 8),

            // Completed (Green)
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Completed',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: Color(0xFF16A34A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${act.completedPoints}',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Action Points Table
        if (points.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorderColor),
            ),
            child: Text(
              'No Action Points recorded yet.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _kTextSecondary,
              ),
            ),
          )
        else if (!isTablet)
          // MOBILE: Modern Card Layout (Zero crash, Zero overflow, Clean UX)
          Column(
            children: List.generate(points.length, (idx) {
              final p = points[idx];
              final isDone = p.isDone;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                    width: isDone ? 1.5 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: #Index + Department badge + Target Date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${idx + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (p.department.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.department,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        if (p.targetDate.isNotEmpty) ...[
                          const Icon(
                            Icons.event_outlined,
                            size: 13,
                            color: _kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.targetDate,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _kTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Action Point Text
                    Text(
                      p.point,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    // Status Actions: Pending / Completed toggle
                    Row(
                      children: [
                        Text(
                          'Status:',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kTextSecondary,
                          ),
                        ),
                        const Spacer(),
                        // Pending Button
                        InkWell(
                          onTap: isDone
                              ? () {
                                  widget.bloc.add(
                                    UpdateMomPointStatus(
                                      activityId: act.id,
                                      pointId: p.id,
                                      status: 'OPEN',
                                    ),
                                  );
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: !isDone
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !isDone
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFFE2E8F0),
                                width: !isDone ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: !isDone
                                      ? const Color(0xFFD97706)
                                      : _kTextSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Pending',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: !isDone
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: !isDone
                                        ? const Color(0xFFD97706)
                                        : _kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Completed Button
                        InkWell(
                          onTap: !isDone
                              ? () {
                                  widget.bloc.add(
                                    UpdateMomPointStatus(
                                      activityId: act.id,
                                      pointId: p.id,
                                      status: 'DONE',
                                    ),
                                  );
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDone
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFE2E8F0),
                                width: isDone ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: isDone
                                      ? const Color(0xFF16A34A)
                                      : _kTextSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Completed',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: isDone
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isDone
                                        ? const Color(0xFF16A34A)
                                        : _kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          )
        else
          // TABLET / DESKTOP: Clean Bounded Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorderColor),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          'S.No',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          'Action Point',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Department',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Target',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 190,
                        child: Text(
                          'Status',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                // Rows
                ...List.generate(points.length, (idx) {
                  final p = points[idx];
                  final isDone = p.isDone;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: idx > 0
                            ? const BorderSide(color: Color(0xFFF1F5F9))
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // S.No
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: _kTextSecondary,
                            ),
                          ),
                        ),

                        // Action Point
                        Expanded(
                          flex: 6,
                          child: Text(
                            p.point,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Department Pill
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.department.isNotEmpty ? p.department : '—',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Target Date
                        Expanded(
                          flex: 3,
                          child: Text(
                            p.targetDate.isNotEmpty ? p.targetDate : '—',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: _kTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Status Toggle Buttons: [ Pending ]  [ Completed ]
                        SizedBox(
                          width: 190,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pending Button
                              InkWell(
                                onTap: isDone
                                    ? () {
                                        widget.bloc.add(
                                          UpdateMomPointStatus(
                                            activityId: act.id,
                                            pointId: p.id,
                                            status: 'OPEN',
                                          ),
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isDone
                                        ? const Color(0xFFFEF3C7)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: !isDone
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFFE2E8F0),
                                      width: !isDone ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: !isDone
                                            ? const Color(0xFFD97706)
                                            : _kTextSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pending',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: !isDone
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: !isDone
                                              ? const Color(0xFFD97706)
                                              : _kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Completed Button
                              InkWell(
                                onTap: !isDone
                                    ? () {
                                        widget.bloc.add(
                                          UpdateMomPointStatus(
                                            activityId: act.id,
                                            pointId: p.id,
                                            status: 'DONE',
                                          ),
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? const Color(0xFFDCFCE7)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDone
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFE2E8F0),
                                      width: isDone ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 12,
                                        color: isDone
                                            ? const Color(0xFF16A34A)
                                            : _kTextSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Completed',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: isDone
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isDone
                                              ? const Color(0xFF16A34A)
                                              : _kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  // ── Points Discussed Table (Image 4 & 5: Point, Department, Target Date, Delete) ──
  Widget _buildPointsTable({required bool isReadonly, bool isTablet = true}) {
    if (_points.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 16,
              color: _kTextSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'No points yet — click Add Point.',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: _kTextSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // ── MOBILE: Card/Stack layout for Points (Zero Horizontal Overflow) ──
    if (!isTablet) {
      return Column(
        children: List.generate(_points.length, (idx) {
          final p = _points[idx];
          final targetDateParsed = DateTime.tryParse(p['targetDate'] ?? '');
          final targetDateDisplay = targetDateParsed != null
              ? _formatDateShort(targetDateParsed)
              : (p['targetDate'] ?? '');
          final dept = p['department'] ?? 'Operations';

          return Container(
            margin: EdgeInsets.only(bottom: idx == _points.length - 1 ? 0 : 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Point TextField + Delete button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${idx + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: isReadonly
                          ? Text(
                              p['point'] ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _kTextPrimary,
                              ),
                            )
                          : TextFormField(
                              initialValue: p['point'],
                              onChanged: (val) => p['point'] = val,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                                hintText: 'Observation / action point...',
                              ),
                            ),
                    ),
                    if (!isReadonly)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        onPressed: () {
                          setState(() {
                            _points.removeAt(idx);
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Department selector + Target date picker
                Row(
                  children: [
                    // Department
                    Expanded(
                      child: isReadonly
                          ? Text(dept, style: GoogleFonts.outfit(fontSize: 12))
                          : InkWell(
                              onTap: () => _showDepartmentSelector(idx),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dept,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: _kTextSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),

                    // Target Date
                    Expanded(
                      child: isReadonly
                          ? Text(targetDateDisplay, style: GoogleFonts.outfit(fontSize: 12))
                          : InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: targetDateParsed ??
                                      DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
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
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      targetDateDisplay.isNotEmpty
                                          ? targetDateDisplay
                                          : 'Select Date',
                                      style: GoogleFonts.outfit(fontSize: 11.5),
                                    ),
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: _kTextSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      );
    }

    // ── TABLET / DESKTOP: 4-Column Table ─────────────────────────────────────
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorderColor),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text(
                    'POINT',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(
                    'DEPARTMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(
                    'TARGET DATE',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (!isReadonly) const SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Rows
          ...List.generate(_points.length, (idx) {
            final p = _points[idx];
            final targetDateParsed = DateTime.tryParse(p['targetDate'] ?? '');
            final targetDateDisplay = targetDateParsed != null
                ? _formatDateShort(targetDateParsed)
                : (p['targetDate'] ?? '');
            final dept = p['department'] ?? 'Operations';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: idx > 0
                      ? const BorderSide(color: Color(0xFFF1F5F9))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  // Point TextField
                  Expanded(
                    flex: 6,
                    child: isReadonly
                        ? Text(
                            p['point'] ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: _kTextPrimary,
                            ),
                          )
                        : TextFormField(
                            initialValue: p['point'],
                            onChanged: (val) => p['point'] = val,
                            style: GoogleFonts.outfit(fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              hintText: 'Enter observation / action point...',
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),

                  // Department Dropdown (Image 5 Modal)
                  Expanded(
                    flex: 4,
                    child: isReadonly
                        ? Text(
                            dept,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: _kTextPrimary,
                            ),
                          )
                        : InkWell(
                            onTap: () => _showDepartmentSelector(idx),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dept,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _kTextPrimary,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: _kTextSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),

                  // Target Date Picker
                  Expanded(
                    flex: 4,
                    child: isReadonly
                        ? Text(
                            targetDateDisplay,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: _kTextPrimary,
                            ),
                          )
                        : InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: targetDateParsed ??
                                    DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
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
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    targetDateDisplay.isNotEmpty
                                        ? targetDateDisplay
                                        : 'Select Date',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: _kTextPrimary,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: _kTextSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  // Delete Point Button
                  if (!isReadonly)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: () {
                        setState(() {
                          _points.removeAt(idx);
                        });
                      },
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Department Selector Dialog (Matching Image 5) ─────────────────────────
  void _showDepartmentSelector(int pointIndex) {
    String searchQuery = '';
    final currentDept = _points[pointIndex]['department'] ?? 'Operations';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredDepts = _kDepartments
                .where((d) => d.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Department',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(dialogCtx).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: _kTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Search Input
                      TextField(
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: _kTextSecondary,
                          ),
                          hintText: 'Search name or role...',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: _kTextSecondary.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // List
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredDepts.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, i) {
                            final dept = filteredDepts[i];
                            final isSelected = dept == currentDept;

                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              title: Text(
                                dept,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? _kPrimary : _kTextPrimary,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: _kPrimary,
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _points[pointIndex]['department'] = dept;
                                });
                                Navigator.of(dialogCtx).pop();
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

  // ── Recipient Selector for TO ─────────────────────────────────────────────
  Widget _buildRecipientSelector({
    required bool isReadonly,
    required List<String> currentList,
    required List<EmailRecipientModel> options,
    required ValueChanged<String> onAdd,
    required ValueChanged<String> onRemove,
    required TextEditingController customController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'To *',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
            if (!isReadonly)
              InkWell(
                onTap: () => setState(() => _showAddToInput = !_showAddToInput),
                child: Text(
                  _showAddToInput ? 'Cancel' : '+ Add custom email',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Defaults To Site Contact Person. Use Add Email For Additional To Recipients.',
          style: GoogleFonts.outfit(fontSize: 11.5, color: _kTextSecondary),
        ),
        const SizedBox(height: 8),

        // Display current chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: currentList.map((email) {
            return Chip(
              backgroundColor: _kLightBlueBg,
              side: const BorderSide(color: Color(0xFFD0E1FD)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              label: Text(
                email,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary,
                ),
              ),
              deleteIcon: isReadonly
                  ? null
                  : const Icon(Icons.close_rounded, size: 14, color: _kPrimary),
              onDeleted: isReadonly ? null : () => onRemove(email),
            );
          }).toList(),
        ),

        // Add custom email input field
        if (_showAddToInput && !isReadonly) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customController,
                  style: GoogleFonts.outfit(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add New To Email',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = customController.text.trim();
                  if (text.isNotEmpty) {
                    onAdd(text);
                    customController.clear();
                    setState(() => _showAddToInput = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text('Add Email', style: GoogleFonts.outfit(fontSize: 12)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── CC Recipient Selector ─────────────────────────────────────────────────
  Widget _buildCcRecipientSelector(
    ActivitySiteDetailModel site, {
    required bool isReadonly,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cc',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
            if (!isReadonly)
              InkWell(
                onTap: () => _showCcSelectionModal(site),
                child: Text(
                  'Select CC',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Defaults To Site Allocation + HR / EHS / Machine. Use Add For Extra Cc Emails.',
          style: GoogleFonts.outfit(fontSize: 11.5, color: _kTextSecondary),
        ),
        const SizedBox(height: 8),

        // CC Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _ccList.map((email) {
            return Chip(
              backgroundColor: const Color(0xFFF1F5F9),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              label: Text(
                email,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kTextPrimary,
                ),
              ),
              deleteIcon: isReadonly
                  ? null
                  : const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: _kTextSecondary,
                    ),
              onDeleted: isReadonly
                  ? null
                  : () {
                      setState(() {
                        _ccList.remove(email);
                      });
                    },
            );
          }).toList(),
        ),

        if (!isReadonly) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addCcController,
                  style: GoogleFonts.outfit(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add New Cc Email',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _addCcController.text.trim();
                  if (text.isNotEmpty) {
                    if (!_ccList.contains(text)) {
                      setState(() => _ccList.add(text));
                    }
                    _addCcController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text('Add', style: GoogleFonts.outfit(fontSize: 12)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showCcSelectionModal(ActivitySiteDetailModel site) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = site.ccEmails.where((c) {
              final q = _ccSearchQuery.toLowerCase();
              return c.label.toLowerCase().contains(q) ||
                  c.value.toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.85,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select CC Recipients',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (val) {
                          setModalState(() => _ccSearchQuery = val);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search people or email...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];
                            final isChecked = _ccList.contains(item.value);

                            return CheckboxListTile(
                              value: isChecked,
                              title: Text(item.name.isNotEmpty ? item.name : item.label),
                              subtitle: Text(item.value),
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    _ccList.add(item.value);
                                  } else {
                                    _ccList.remove(item.value);
                                  }
                                });
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Sidebar Cards: Activity Master & Execution Flow ───────────────────────
  Widget _buildSidebarCards(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCollapsibleActivityMasterCard(act, site, isTablet),
        const SizedBox(height: 16),
        _buildExecutionFlowCard(isTablet),
      ],
    );
  }

  Widget _buildCollapsibleActivityMasterCard(
    ActivityItemDetailModel act,
    ActivitySiteDetailModel site,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Master',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            _buildMasterRow('Activity ID', act.code),
            _buildMasterRow('Site', site.name),
            _buildMasterRow('Category / Function', act.functionLabel),
            _buildMasterRow('Role', act.roleLabel),
            _buildMasterRow('SPOC', act.assignedToName ?? '—'),
            _buildMasterRow('Client Type', act.clientType.isNotEmpty ? act.clientType : '—'),
            _buildMasterRow('Frequency', act.frequencyLabel),
            _buildMasterRow('Scheduled', act.scheduledDate ?? '—'),
            _buildMasterRow('Due', act.dueDate ?? '—'),
            _buildMasterRow('Attendance', 'See Attendance'),
            _buildMasterRow(
              'Current Step',
              _currentStep == 0
                  ? (isTablet ? 'Walk Around Checklist' : 'Checklist')
                  : (isTablet ? 'MOM & Email' : 'MOM'),
            ),
            _buildMasterRow('Status', act.statusLabel, isStatus: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterRow(
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _kTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: value == 'See Attendance'
                ? InkWell(
                    onTap: () {
                      AppSnackBar.info(
                        context,
                        message: 'Attendance is under progress',
                      );
                    },
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isStatus ? FontWeight.w700 : FontWeight.w600,
                      color: isStatus ? _kPrimary : _kTextPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionFlowCard(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kLightBlueBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0E1FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Execution Flow',
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1. Walk Around Checklist → 2. Visit Details → 3. MOM. Attendance Is Marked Under Attendance.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _kTextDarkBlue,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // ACTIONS & DISPATCH
  // ═════════════════════════════════════════════════════════════════════════════
  void _submitVisit() {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    final act = widget.activityDetail.activity;

    // Check checklist items: if status == 'ISSUE' (i.e. 'No'), remarks are mandatory!
    final missingRemarks = <String>[];
    for (final item in act.template) {
      final status = _checklistStatus[item.key] ?? 'OK';
      final remarks = _remarksControllers[item.key]?.text.trim() ?? '';
      if (status == 'ISSUE' && remarks.isEmpty) {
        missingRemarks.add(item.title);
      }
    }

    if (missingRemarks.isNotEmpty) {
      final firstName = missingRemarks.first;
      final extra = missingRemarks.length - 1;
      final errorMsg = extra > 0
          ? 'Remarks are mandatory for "$firstName" and $extra other item(s) marked as "No".'
          : 'Remarks are mandatory for "$firstName" because it is marked as "No".';

      AppSnackBar.error(
        context,
        title: 'Remarks Required',
        message: errorMsg,
      );
      return;
    }

    if (_clientMet == null) {
      AppSnackBar.warning(
        context,
        title: 'Client Met Required',
        message: 'Please specify whether you met with the client (Yes/No).',
      );
      return;
    }

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
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                          fontSize: 17,
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
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visit Date',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        formattedDateText,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Client Met',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        clientMetVal ? 'Yes' : 'No',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: clientMetVal
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kLightBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorderBlue),
                    ),
                    child: Text(
                      'After Submit You Will Move To MOM & Email To Send The Client Communication.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kTextDarkBlue,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 7,
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
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Complete → Send MOM',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
    final act = widget.activityDetail.activity;
    final answersPayload = act.template.map((t) {
      final status = _checklistStatus[t.key] ?? 'OK';
      final remarks = _remarksControllers[t.key]?.text.trim() ?? '';
      return {
        'key': t.key,
        'status': status,
        'remarks': remarks,
      };
    }).toList();

    widget.bloc.add(
      SubmitActivityVisit(
        activityId: act.id,
        visitDate: visitDateStr,
        clientMet: clientMetVal,
        note: noteText,
        answers: answersPayload,
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

    final pointsPayload = _points.map((p) {
      final rawDept = p['department'] ?? 'Operations';
      final deptVal = (rawDept == 'L&D') ? 'LD' : rawDept;
      return {
        'point': p['point'] ?? '',
        'targetDate': p['targetDate'] ?? '',
        'department': deptVal,
      };
    }).toList();

    final payload = {
      'to': _toList,
      'cc': _ccList,
      'subject': _subjectController.text.trim(),
      'body': _bodyController.text.trim(),
      'meetingAttendees': _meetingAttendeesController.text.trim(),
      'clientAttendees': _clientAttendeesController.text.trim(),
      'points': pointsPayload,
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

// ── Translucent Wave Painter for Decorative Accents ──────────────────────────
class _BottomCornerWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1769E8).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.8,
      size.width,
      0,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
