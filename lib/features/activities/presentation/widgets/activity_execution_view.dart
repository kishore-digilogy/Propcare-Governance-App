import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/activity_detail_model.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';

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
    _visitNoteController = TextEditingController(text: act.completionNote ?? '');

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
    if (oldWidget.activityDetail.activity.status != widget.activityDetail.activity.status ||
        oldWidget.activityDetail.activity.isCompleted != widget.activityDetail.activity.isCompleted) {
      if (widget.activityDetail.activity.isCompleted && !oldWidget.activityDetail.activity.isCompleted) {
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatDateWithWeekday(DateTime d) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${_formatDateShort(d)}  ${days[d.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activityDetail.activity;
    final site = widget.activityDetail.site;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 14 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Breadcrumb & Header Bar
              _buildTopBar(act, site),
              const SizedBox(height: 16),

              // Two-Step Horizontal Stepper (1. Visit details, 2. MOM)
              _buildStepper(act),
              const SizedBox(height: 20),

              // Main Content: 2-column on desktop, single-column on mobile
              if (isMobile) ...[
                _buildActiveStepForm(act, site),
                const SizedBox(height: 20),
                _buildSidebarCards(act, site),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 65,
                      child: _buildActiveStepForm(act, site),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 35,
                      child: _buildSidebarCards(act, site),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(ActivityItemDetailModel act, ActivitySiteDetailModel site) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        final backAndBreadcrumb = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.onBack,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Activities > ${act.code}',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        );

        final isAllCompleted = act.isMomSent || act.status == 'COMPLETED' || act.status == 'CLOSED';

        String primaryBtnText = '';
        VoidCallback? onPrimaryPressed;
        bool isPrimaryLoading = false;

        if (!act.isCompleted) {
          // Visit details pending
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

        final actionButtons = isAllCompleted
            ? const SizedBox.shrink()
            : Row(
                mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (isNarrow)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Draft saved locally')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Save draft',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft saved locally')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Save draft',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (isNarrow)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onPrimaryPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isPrimaryLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                primaryBtnText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: onPrimaryPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isPrimaryLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              primaryBtnText,
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNarrow) ...[
              backAndBreadcrumb,
              if (!isAllCompleted) ...[
                const SizedBox(height: 10),
                actionButtons,
              ],
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  backAndBreadcrumb,
                  if (!isAllCompleted) actionButtons,
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Activity Title & Subtitle
            Text(
              act.title,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${site.name} · ${act.code} · ${act.frequencyLabel} · SPOC ${act.assignedToName ?? "Unassigned"}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepper(ActivityItemDetailModel act) {
    final step1Completed = act.isCompleted;
    final step2Completed = act.isMomSent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step1Completed
                        ? const Color(0xFF16A34A) // GREEN for completed step as requested!
                        : (_currentStep == 0 ? AppColors.primary : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: step1Completed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '1',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _currentStep == 0 ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Visit details',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: _currentStep == 0 ? FontWeight.w700 : FontWeight.w500,
                    color: step1Completed
                        ? const Color(0xFF16A34A)
                        : (_currentStep == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          // Connecting line
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: step1Completed ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
            ),
          ),

          // Step 2: MOM
          InkWell(
            onTap: () {
              if (!step1Completed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please submit visit details first before proceeding to MOM.'),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step2Completed
                        ? const Color(0xFF16A34A)
                        : (!step1Completed
                            ? const Color(0xFFE2E8F0)
                            : (_currentStep == 1 ? AppColors.primary : const Color(0xFFF1F5F9))),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: step2Completed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '2',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !step1Completed
                                  ? const Color(0xFF94A3B8)
                                  : (_currentStep == 1 ? Colors.white : const Color(0xFF64748B)),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MOM',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: _currentStep == 1 ? FontWeight.w700 : FontWeight.w500,
                    color: step2Completed
                        ? const Color(0xFF16A34A)
                        : (!step1Completed
                            ? const Color(0xFF94A3B8)
                            : (_currentStep == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStepForm(ActivityItemDetailModel act, ActivitySiteDetailModel site) {
    if (_currentStep == 0) {
      return _buildStep1VisitDetails(act);
    } else {
      return _buildStep2MomForm(act, site);
    }
  }

  // STEP 1: Visit Details
  Widget _buildStep1VisitDetails(ActivityItemDetailModel act) {
    final isCompleted = act.isCompleted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                '1. Visit details',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  isCompleted ? 'Visit completed' : 'Visit date required · Note optional',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visit date *
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
                ? null // Disabled if completed!
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: isCompleted ? const Color(0xFF94A3B8) : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDateWithWeekday(_visitDate),
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Client met *
          Text(
            'Client met *',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildToggleChip(
                label: 'Yes',
                isSelected: _clientMet == true,
                isDisabled: isCompleted,
                onTap: () {
                  if (!isCompleted) setState(() => _clientMet = true);
                },
              ),
              const SizedBox(width: 10),
              _buildToggleChip(
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

          // Note (optional)
          Text(
            'Note (optional)',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _visitNoteController,
            enabled: !isCompleted, // Disabled if completed!
            maxLines: 4,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Optional — visit notes, discussion points, client feedback...',
              hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
              filled: isCompleted,
              fillColor: isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 460;
                final textWidget = Text(
                  isCompleted
                      ? (act.isMomSent
                          ? 'Visit completed on ${_formatDateShort(_visitDate)} · Client met ${_clientMet == true ? "Yes" : "No"} · MOM completed'
                          : 'Visit completed on ${_formatDateShort(_visitDate)} · Client met ${_clientMet == true ? "Yes" : "No"}')
                      : 'Visit ${_formatDateShort(_visitDate)} · Client met ${_clientMet == null ? "—" : (_clientMet! ? "Yes" : "No")}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF475569),
                  ),
                );

                final buttonWidget = isCompleted
                    ? (!act.isMomSent
                        ? ElevatedButton(
                            onPressed: () => setState(() => _currentStep = 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Proceed to MOM →',
                              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          )
                        : const SizedBox.shrink())
                    : ElevatedButton(
                        onPressed: widget.isSubmittingVisit ? null : _submitVisit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: widget.isSubmittingVisit
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Submit visit',
                                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      textWidget,
                      const SizedBox(height: 10),
                      buttonWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: textWidget),
                    const SizedBox(width: 12),
                    buttonWidget,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDisabled ? const Color(0xFF16A34A) : AppColors.primary)
              : (isDisabled ? const Color(0xFFF1F5F9) : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (isDisabled ? const Color(0xFF16A34A) : AppColors.primary)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // STEP 2: MOM & Email Form
  Widget _buildStep2MomForm(ActivityItemDetailModel act, ActivitySiteDetailModel site) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                '2. MOM & Email',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: act.isMomSent ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: act.isMomSent ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  act.isMomSent ? 'Sent' : 'Draft',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: act.isMomSent ? const Color(0xFF16A34A) : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Minutes of meeting — ${site.name} · Client ${site.clientName}, ${_formatDateShort(_visitDate)}. Prepared after the visit is submitted.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // TO Recipients
          Text(
            'To *',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
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
                      label: '${site.contactPersonName ?? site.clientName} · ${site.clientEmail}',
                      name: site.contactPersonName ?? '',
                      role: 'CLIENT',
                    ),
                  ],
            onAdd: (val) {
              if (!_toList.contains(val)) setState(() => _toList.add(val));
            },
            onRemove: (val) => setState(() => _toList.remove(val)),
            customController: _addToController,
            hint: 'Defaults to site contact person. Use Add email for additional To recipients.',
          ),
          const SizedBox(height: 16),

          // CC Recipients (filtered by current zone as requested!)
          Text(
            'Cc',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          _buildCcRecipientSelector(site, isReadonly: act.isMomSent),
          const SizedBox(height: 16),

          // Subject *
          Text(
            'Subject *',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectController,
            readOnly: act.isMomSent,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: act.isMomSent ? const Color(0xFF334155) : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              filled: act.isMomSent,
              fillColor: act.isMomSent ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: act.isMomSent ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: act.isMomSent ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 18),

          // Major Points Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MAJOR POINTS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              if (!act.isMomSent)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _points.add({
                        'point': '',
                        'targetDate': DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T').first,
                      });
                    });
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: Text('+ Add point', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPointsTable(isReadonly: act.isMomSent),
          const SizedBox(height: 18),

          // Email Closing Text
          Text(
            'Email',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _closingController,
            readOnly: act.isMomSent,
            maxLines: 4,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: act.isMomSent ? const Color(0xFF334155) : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              filled: act.isMomSent,
              fillColor: act.isMomSent ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: act.isMomSent ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: act.isMomSent ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action
          Align(
            alignment: Alignment.centerRight,
            child: act.isMomSent
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      'MOM saved',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: widget.isSendingMom ? null : _sendMom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: widget.isSendingMom
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Send MOM',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientSelector({
    required bool isReadonly,
    required List<String> currentList,
    required List<EmailRecipientModel> options,
    required Function(String) onAdd,
    required Function(String) onRemove,
    required TextEditingController customController,
    required String hint,
  }) {
    final unaddedOptions = options.where((opt) => !currentList.contains(opt.value)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isReadonly ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        email,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF1E40AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isReadonly) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => onRemove(email),
                          child: const Icon(Icons.close, size: 13, color: Color(0xFF1E40AF)),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),

          if (!isReadonly) ...[
            if (currentList.isNotEmpty) const SizedBox(height: 8),

            // Inline input row for adding new email
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: customController,
                      style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Enter email address...',
                        hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppColors.primary),
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
                ElevatedButton(
                  onPressed: () {
                    final txt = customController.text.trim();
                    if (txt.isNotEmpty && !currentList.contains(txt)) {
                      onAdd(txt);
                      customController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'Add email',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
                    style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
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
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 12, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  opt.value,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: AppColors.primary,
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

  Widget _buildCcRecipientSelector(ActivitySiteDetailModel site, {required bool isReadonly}) {
    // Combine site.ccEmails with users from UserService filtered by site.zoneId
    final ccOptions = <EmailRecipientModel>[...site.ccEmails];

    // Filter by zone if site.zoneId exists as user requested:
    // "in user pai..if user is current zone,, i mean user is mumbai zone only show that users only"
    final users = site.zoneId != null && site.zoneId!.isNotEmpty
        ? UserService.instance.getUsersByZone(site.zoneId!)
        : UserService.instance.users;

    for (final u in users) {
      if (u.email.isNotEmpty && !ccOptions.any((c) => c.value.toLowerCase() == u.email.toLowerCase())) {
        ccOptions.add(EmailRecipientModel(
          value: u.email,
          label: '${u.name} · ${u.roleLabel} · ${u.email}',
          name: u.name,
          role: u.role,
        ));
      }
    }

    final filteredOptions = _ccSearchQuery.isEmpty
        ? ccOptions
        : ccOptions
            .where((c) =>
                c.label.toLowerCase().contains(_ccSearchQuery.toLowerCase()) ||
                c.value.toLowerCase().contains(_ccSearchQuery.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isReadonly ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isReadonly ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            email,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!isReadonly) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => setState(() => _ccList.remove(email)),
                              child: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),

              if (!isReadonly) ...[
                const SizedBox(height: 8),

                // Search field for CC list
                SizedBox(
                  height: 34,
                  child: TextField(
                    style: GoogleFonts.outfit(fontSize: 12),
                    onChanged: (val) => setState(() => _ccSearchQuery = val),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF94A3B8)),
                      hintText: 'Search name or role in zone...',
                      hintStyle: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Dropdown items list (max height 160)
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
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                size: 16,
                                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  opt.label,
                                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B)),
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
          const SizedBox(height: 6),

          // Custom CC Add row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _addCcController,
                    style: GoogleFonts.outfit(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Add new Cc email',
                      hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text('Add', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Filtered for current zone (${site.zoneId ?? "all"}). Defaults to site allocation + HR / EHS / Machine.',
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
        ],
      ],
    );
  }

  Widget _buildPointsTable({required bool isReadonly}) {
    if (_points.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            'No major points yet — click Add point.',
            style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text('Point', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Target date', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
                if (!isReadonly) const SizedBox(width: 32),
              ],
            ),
          ),
          ...List.generate(_points.length, (idx) {
            final p = _points[idx];
            final targetDateParsed = DateTime.tryParse(p['targetDate'] ?? '');
            final targetDateDisplay = targetDateParsed != null ? _formatDateShort(targetDateParsed) : (p['targetDate'] ?? '');

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
                            style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF0F172A)),
                          )
                        : TextField(
                            controller: TextEditingController(text: p['point'])
                              ..selection = TextSelection.collapsed(offset: (p['point'] ?? '').length),
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
                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF0F172A)),
                          )
                        : InkWell(
                            onTap: () async {
                              final cur = DateTime.tryParse(p['targetDate'] ?? '') ?? DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: cur,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  p['targetDate'] = picked.toIso8601String().split('T').first;
                                });
                              }
                            },
                            child: Text(
                              p['targetDate']?.isNotEmpty == true ? p['targetDate']! : 'Pick date',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ),
                  ),
                  if (!isReadonly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
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

  // SIDEBAR CARDS (Activity Master & Execution Flow)
  Widget _buildSidebarCards(ActivityItemDetailModel act, ActivitySiteDetailModel site) {
    return Column(
      children: [
        // Activity Master Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity master',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildMasterRow('Activity ID', act.code),
              _buildMasterRow('Site', site.name),
              _buildMasterRow('Category / function', act.functionLabel),
              _buildMasterRow('Role', act.roleLabel),
              _buildMasterRow('SPOC', act.assignedToName ?? 'Unassigned'),
              _buildMasterRow('Client type', act.clientType),
              _buildMasterRow('Frequency', act.frequencyLabel),
              _buildMasterRow('Scheduled', act.scheduledDate ?? '—'),
              _buildMasterRow('Due', act.dueDate ?? '—'),
              _buildMasterRow('Attendance', 'See Attendance', isLink: true),
              _buildMasterRow('Current step', _currentStep == 0 ? 'Visit details' : 'MOM'),
              _buildMasterRow(
                'Status',
                act.isMomSent ? 'Completed' : act.statusLabel,
                statusColor: (act.isCompleted || act.isMomSent) ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Execution Flow Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Execution flow',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '1. Visit details and 2. MOM can be opened independently. Attendance is marked under Attendance.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF1E40AF),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMasterRow(
    String label,
    String value, {
    bool isLink = false,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: statusColor ?? (isLink ? AppColors.primary : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  void _submitVisit() {
    final visitDateStr = _visitDate.toIso8601String().split('T').first;
    widget.bloc.add(SubmitActivityVisit(
      activityId: widget.activityDetail.activity.id,
      visitDate: visitDateStr,
      clientMet: _clientMet ?? false,
      note: _visitNoteController.text.trim(),
    ));
  }

  void _sendMom() {
    if (!widget.activityDetail.activity.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please submit visit details first before sending MOM.'),
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
    widget.bloc.add(SendActivityMomEmail(
      activityId: widget.activityDetail.activity.id,
      payload: payload,
    ));
  }
}
