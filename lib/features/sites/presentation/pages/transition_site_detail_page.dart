import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/meta_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../data/datasources/sites_remote_datasource.dart';
import '../../data/models/transition_detail_model.dart';
import '../bloc/transition_detail_bloc.dart';
import '../bloc/transition_detail_event.dart';
import '../bloc/transition_detail_state.dart';

const Color _kBlue = Color(0xFF1A73E8);
const Color _kDark = Color(0xFF0F172A);
const Color _kSlate = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kBg = Color(0xFFF8FAFC);
const Color _kGreen = Color(0xFF16A34A);
const Color _kAmber = Color(0xFFB45309);
const Color _kAmberBg = Color(0xFFFEF3C7);

/// Transition Site Detail Page matching user designs.
class TransitionSiteDetailPage extends StatelessWidget {
  final String siteId;
  final TransitionDetailBloc? bloc;

  const TransitionSiteDetailPage({
    super.key,
    required this.siteId,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: _TransitionSiteDetailView(siteId: siteId),
      );
    }

    return BlocProvider(
      create: (_) => TransitionDetailBloc(
        dataSource: SitesRemoteDataSourceImpl(),
      )..add(LoadTransitionDetail(siteId: siteId)),
      child: _TransitionSiteDetailView(siteId: siteId),
    );
  }
}

class _TransitionSiteDetailView extends StatefulWidget {
  final String siteId;

  const _TransitionSiteDetailView({required this.siteId});

  @override
  State<_TransitionSiteDetailView> createState() => _TransitionSiteDetailViewState();
}

class _TransitionSiteDetailViewState extends State<_TransitionSiteDetailView> {
  final Map<String, bool> _openPendingForms = {};
  final Map<String, TextEditingController> _issueControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, String?> _selectedOwnerIds = {};

  @override
  void initState() {
    super.initState();
    // Pre-cache admin users so kickoff participants' name & department are always resolved
    UserService.instance.getAdminUsers().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in _issueControllers.values) {
      c.dispose();
    }
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatDateWithDay(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'Select date';
    try {
      final parsed = DateTime.parse(dateStr.trim());
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}  ${days[parsed.weekday - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: BlocConsumer<TransitionDetailBloc, TransitionDetailState>(
          listener: (context, state) {
            if (state is TransitionDetailLoaded) {
              if (state.actionMessage != null && state.actionMessage!.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.actionMessage!),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            if (state is TransitionDetailLoading || state is TransitionDetailInitial) {
              return const Center(
                child: CircularProgressIndicator(color: _kBlue),
              );
            }

            if (state is TransitionDetailError) {
              return _buildErrorView(context, state.message);
            }

            if (state is TransitionDetailLoaded) {
              return _buildLoadedContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Failed to load transition site details',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12.5, color: _kSlate),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context
                    .read<TransitionDetailBloc>()
                    .add(LoadTransitionDetail(siteId: widget.siteId, isRefresh: true));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, TransitionDetailLoaded state) {
    final site = state.response.site;

    return RefreshIndicator(
      color: _kBlue,
      onRefresh: () async {
        context
            .read<TransitionDetailBloc>()
            .add(LoadTransitionDetail(siteId: widget.siteId, isRefresh: true));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final hPadding = isDesktop ? 28.0 : 16.0;

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
            children: [
              // ── Top Navigation Bar: ← Sites List ───────────────────────────
              _buildTopBackNav(context),
              const SizedBox(height: 16),

              // ── Site Header Card with 3 Contract Date Boxes ─────────────────
              _buildSiteHeaderCard(context, site, isDesktop),
              const SizedBox(height: 16),

              // ── 3-Stage Stepper Bar ─────────────────────────────────────────
              _buildStepperCard(context, state, isDesktop),
              const SizedBox(height: 16),

              // ── Active Step Body ───────────────────────────────────────────
              if (state.isSaving) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: _kBlue),
                ),
              ],
              _buildStepContent(context, state, isDesktop),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ── Top Navigation: ← Sites List ───────────────────────────────────────────
  Widget _buildTopBackNav(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded, size: 16, color: _kBlue),
              const SizedBox(width: 6),
              Text(
                'All LIVE Sites',
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
    );
  }

  // ── Site Header Card ───────────────────────────────────────────────────────
  Widget _buildSiteHeaderCard(
    BuildContext context,
    TransitionSiteInfoModel site,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSiteTitleAndCode(site),
                Row(
                  children: [
                    _buildContractDateBox('Contract Award Date', site.formattedAwardDate),
                    const SizedBox(width: 12),
                    _buildContractDateBox('Contract Start Date', site.formattedStartDate),
                    const SizedBox(width: 12),
                    _buildContractDateBox('Contract End Date', site.formattedEndDate),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSiteTitleAndCode(site),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildContractDateBox('Contract Award Date', site.formattedAwardDate),
                      const SizedBox(width: 10),
                      _buildContractDateBox('Contract Start Date', site.formattedStartDate),
                      const SizedBox(width: 10),
                      _buildContractDateBox('Contract End Date', site.formattedEndDate),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSiteTitleAndCode(TransitionSiteInfoModel site) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              site.name,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'L&D Transition',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1967D2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${site.code} · ${site.status} · Open',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: _kSlate,
          ),
        ),
      ],
    );
  }

  Widget _buildContractDateBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: _kBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _kSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4-Stage Stepper Card (Matching Web Images 7, 8) ─────────────────────────
  Widget _buildStepperCard(
    BuildContext context,
    TransitionDetailLoaded state,
    bool isDesktop,
  ) {
    final preview = state.response.ldPreview;
    final selectedStep = state.selectedStep;

    final isInternalDone = preview.internal.isNotEmpty &&
        preview.internal.every((i) => i.done || i.status.toUpperCase() == 'COMPLETED');
    final isLdDone = preview.ldTransition.isNotEmpty &&
        preview.ldTransition.every((i) => i.done || i.status.toUpperCase() == 'COMPLETED');
    final isVerified = preview.review.status.toUpperCase() == 'VERIFIED';

    final steps = [
      _StepConfig(
        stepIndex: 1,
        title: 'Site Creation',
        subtitle: 'Completed',
        isCompleted: true,
        isSelected: selectedStep == 1,
      ),
      _StepConfig(
        stepIndex: 2,
        title: 'Internal Checklist',
        subtitle: 'L&D Team',
        isCompleted: isInternalDone,
        isSelected: selectedStep == 2,
      ),
      _StepConfig(
        stepIndex: 3,
        title: 'L&D Transition Checklist',
        subtitle: 'L&D Team',
        isCompleted: isLdDone,
        isSelected: selectedStep == 3,
      ),
      _StepConfig(
        stepIndex: 4,
        title: 'Stability Verify',
        subtitle: 'L&D Head',
        isCompleted: isVerified,
        isSelected: selectedStep == 4,
        isRestrictedToHead: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildStepItem(context, steps[0], true)),
                _buildStepArrow(),
                Expanded(child: _buildStepItem(context, steps[1], true)),
                _buildStepArrow(),
                Expanded(child: _buildStepItem(context, steps[2], true)),
                _buildStepArrow(),
                Expanded(child: _buildStepItem(context, steps[3], true)),
              ],
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStepItem(context, steps[0], false),
                  _buildStepArrow(),
                  _buildStepItem(context, steps[1], false),
                  _buildStepArrow(),
                  _buildStepItem(context, steps[2], false),
                  _buildStepArrow(),
                  _buildStepItem(context, steps[3], false),
                ],
              ),
            ),
    );
  }

  Widget _buildStepItem(BuildContext context, _StepConfig cfg, bool isDesktop) {
    Color pillBg;
    Color pillFg;
    String pillText = cfg.subtitle;

    if (cfg.isCompleted) {
      pillBg = const Color(0xFFE8F5E9);
      pillFg = const Color(0xFF16A34A);
      pillText = 'Completed';
    } else if (cfg.stepIndex == 2 || cfg.stepIndex == 3) {
      pillBg = const Color(0xFFEFF6FF);
      pillFg = const Color(0xFF2563EB);
    } else {
      pillBg = const Color(0xFFF5F3FF);
      pillFg = const Color(0xFF7C3AED);
    }

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          cfg.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: cfg.isSelected ? FontWeight.w700 : FontWeight.w600,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            pillText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: pillFg,
            ),
          ),
        ),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        context.read<TransitionDetailBloc>().add(SelectTransitionStep(cfg.stepIndex));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cfg.isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cfg.isSelected ? _kBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge / Number Circle
            if (cfg.isCompleted)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              )
            else
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: cfg.isSelected ? _kBlue : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: cfg.isSelected ? null : Border.all(color: const Color(0xFFCBD5E1)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${cfg.stepIndex}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cfg.isSelected ? Colors.white : _kSlate,
                  ),
                ),
              ),
            const SizedBox(width: 10),
            if (isDesktop) Expanded(child: titleColumn) else titleColumn,
          ],
        ),
      ),
    );
  }

  Widget _buildStepArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFFCBD5E1)),
    );
  }

  // ── Step Content Routing ───────────────────────────────────────────────────
  Widget _buildStepContent(
    BuildContext context,
    TransitionDetailLoaded state,
    bool isDesktop,
  ) {
    switch (state.selectedStep) {
      case 1:
        return _buildStep1SiteCreation(context, state);
      case 2:
        return _buildStep2InternalChecklist(context, state);
      case 3:
        return _buildStep3LdTransitionChecklist(context, state);
      case 4:
        return _buildStep4StabilityVerify(context, state);
      default:
        return _buildStep2InternalChecklist(context, state);
    }
  }

  // ── Step 1: Site Creation (Completed) ──────────────────────────────────────
  Widget _buildStep1SiteCreation(
    BuildContext context,
    TransitionDetailLoaded state,
  ) {
    final site = state.response.site;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Site Creation Overview',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: _kGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildInfoTile('Contract Award Date', site.formattedAwardDate),
                  _buildInfoTile('Contract Start Date', site.formattedStartDate),
                  _buildInfoTile('Contract End Date', site.formattedEndDate),
                  _buildInfoTile('Site Code', site.code),
                  _buildInfoTile('Client Name', site.clientName),
                  _buildInfoTile('Status', site.status),
                  _buildInfoTile('Mode', site.mode),
                  _buildInfoTile('Zone', site.zoneName),
                  _buildInfoTile('Cluster', site.clusterName),
                  _buildInfoTile('Manpower Required', '${site.manpowerRequired}'),
                  _buildInfoTile('Manpower Deployed', '${site.manpowerDeployed}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              context.read<TransitionDetailBloc>().add(const SelectTransitionStep(2));
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            iconAlignment: IconAlignment.end,
            label: Text(
              'Continue To Internal Checklist',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _kSlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Internal Checklist (Client Kick-Off + Internal Items) ───────────
  Widget _buildStep2InternalChecklist(
    BuildContext context,
    TransitionDetailLoaded state,
  ) {
    final preview = state.response.ldPreview;
    final kickoff = preview.kickoff;
    final zoneUsers = state.response.zoneUsers;
    final items = preview.internal;
    final openCount = items.where((i) => i.displayStatus != 'Completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Client Kick-Off (Matching Image 1 & 5) ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Client Kick-Off',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Sales + Ops + CRRM',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Row 1: Kick-Off With Client & Date Picker
              Wrap(
                spacing: 24,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  _buildInteractiveToggleField(
                    label: 'Kick-Off With Client',
                    isYes: kickoff.isWithClientYes,
                    onChanged: (yes) {
                      context.read<TransitionDetailBloc>().add(
                            UpdateKickoffField(withClient: yes ? 'YES' : 'NO'),
                          );
                    },
                  ),
                  _buildDatePickerButton(
                    context: context,
                    label: 'Kick-Off Date *',
                    currentDate: kickoff.date,
                    subtitle: 'Mandatory when kick-off = Yes',
                    onDateSelected: (newDate) {
                      context.read<TransitionDetailBloc>().add(
                            UpdateKickoffField(date: newDate),
                          );
                    },
                    onClear: () {
                      context.read<TransitionDetailBloc>().add(
                            const UpdateKickoffField(date: ''),
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Row 2: Kick-Off Participants (L&D Department Multi-Select - Image 5)
              _buildParticipantsSelector(context, kickoff, zoneUsers),
              const SizedBox(height: 18),

              // Row 3: Pre-Transition Meeting
              _buildInteractiveToggleField(
                label: 'Pre-Transition Meeting',
                isYes: kickoff.isPreTransitionMeetingYes,
                onChanged: (yes) {
                  context.read<TransitionDetailBloc>().add(
                        UpdateKickoffField(meeting: yes ? 'COMPLETED' : 'NO'),
                      );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Card 2: Internal Checklist Table (Matching Image 1 & 4) ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Internal Checklist',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kAmberBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length} items · $openCount open',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kAmber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...items.map((item) => _buildChecklistItemRow(context, item, zoneUsers)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Action Button: Continue To L&D Transition Checklist → (Matching Web Image 7) ──
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              onPressed: () {
                context.read<TransitionDetailBloc>().add(
                      SaveTransitionActionEvent(
                        siteId: widget.siteId,
                        action: 'save',
                      ),
                    );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              iconAlignment: IconAlignment.end,
              label: Text(
                'Continue To L&D Transition Checklist',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: L&D Transition Checklist (Matching Web Image 8) ────────────────
  Widget _buildStep3LdTransitionChecklist(
    BuildContext context,
    TransitionDetailLoaded state,
  ) {
    final preview = state.response.ldPreview;
    final items = preview.ldTransition;
    final openCount = items.where((i) => i.displayStatus != 'Completed').length;
    final zoneUsers = state.response.zoneUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'L&D Transition Checklist',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kAmberBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length} items · $openCount open',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kAmber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...items.map((item) => _buildChecklistItemRow(context, item, zoneUsers)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Action Buttons: [Work in Progress] & [Continue To Stability Verify →] ──
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kBlue,
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  context.read<TransitionDetailBloc>().add(
                        SaveTransitionActionEvent(
                          siteId: widget.siteId,
                          action: 'save',
                        ),
                      );
                },
                child: Text(
                  'Work in Progress',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  context.read<TransitionDetailBloc>().add(
                        SaveTransitionActionEvent(
                          siteId: widget.siteId,
                          action: 'save',
                        ),
                      );
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                iconAlignment: IconAlignment.end,
                label: Text(
                  'Continue To Stability Verify',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 4: Stability Verify (Matching Web Image 3 & Mobile Image 6) ────────
  Widget _buildStep4StabilityVerify(
    BuildContext context,
    TransitionDetailLoaded state,
  ) {
    final preview = state.response.ldPreview;
    final review = preview.review;
    final isVerified = review.status.toUpperCase() == 'VERIFIED';
    final isSuperAdmin = HiveStorage.isSuperAdmin;
    final isHead = HiveStorage.isLdHead && !isSuperAdmin;
    final canVerify = isHead && !isSuperAdmin;

    final allInternalDone = preview.internal.isNotEmpty &&
        preview.internal.every((i) => i.done || i.status.toUpperCase() == 'COMPLETED');
    final allLdDone = preview.ldTransition.isNotEmpty &&
        preview.ldTransition.every((i) => i.done || i.status.toUpperCase() == 'COMPLETED');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 20, color: _kBlue),
              const SizedBox(width: 8),
              Text(
                'Stability Check',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Finish Internal + L&D checklist, then use Stability Check to send this for L&D Head verify.',
            style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
          ),
          const SizedBox(height: 20),

          if (isVerified) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Stability Verified',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _kGreen,
                    ),
                  ),
                  if (review.verifiedAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '· ${TransitionDateHelper.formatDate(review.verifiedAt)}',
                      style: GoogleFonts.outfit(fontSize: 12.5, color: _kSlate),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canVerify ? _kBlue : const Color(0xFF93C5FD),
                  disabledBackgroundColor: const Color(0xFF93C5FD),
                  disabledForegroundColor: Colors.white,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSuperAdmin
                    ? null
                    : () {
                        if (!allInternalDone) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'All Internal Checklist items must be Completed before Stability Check.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        if (!allLdDone) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'All L&D Checklist items must be Completed before Stability Check.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        if (!canVerify) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Stability Verify is restricted to L&D Head role.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        context.read<TransitionDetailBloc>().add(
                              SaveTransitionActionEvent(
                                siteId: widget.siteId,
                                action: 'verify',
                              ),
                            );
                      },
                child: Text(
                  'Stability Check',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (isSuperAdmin) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Admin does not have access to Stability Check.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ] else if (!isHead) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Stability Verify is restricted to L&D Head role.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Checklist Item Row: Title, Dates, Status buttons, Issue Box ────────────
  Widget _buildChecklistItemRow(
    BuildContext context,
    TransitionChecklistItemModel item,
    List<ZoneUserModel> zoneUsers,
  ) {
    final isPendingFormOpen = _openPendingForms[item.key] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Status Toggle Buttons
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                item.title,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              _buildStatusButtons(context: context, item: item),
            ],
          ),
          const SizedBox(height: 10),

          // Date Row: Start Date & Target Date
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildChecklistDateField(
                context: context,
                label: 'Start Date',
                dateStr: item.startDate,
                onSelected: (date) {
                  context.read<TransitionDetailBloc>().add(
                        UpdateChecklistItemEvent(
                          phase: item.phase,
                          key: item.key,
                          status: item.status,
                          done: item.done,
                          startDate: date,
                          endDate: item.endDate,
                        ),
                      );
                },
              ),
              _buildChecklistDateField(
                context: context,
                label: 'Target Date',
                dateStr: item.targetDate ?? item.endDate,
                onSelected: (date) {
                  context.read<TransitionDetailBloc>().add(
                        UpdateChecklistItemEvent(
                          phase: item.phase,
                          key: item.key,
                          status: item.status,
                          done: item.done,
                          startDate: item.startDate,
                          endDate: date,
                        ),
                      );
                },
              ),
            ],
          ),

          // Pending Issue Form (Image 4)
          if (isPendingFormOpen && item.canRaiseTicket) ...[
            _buildPendingIssueBox(
              context: context,
              item: item,
              zoneUsers: zoneUsers,
            ),
          ],
        ],
      ),
    );
  }

  // ── Status Selection Buttons (Completed / Pending / In progress) ────────────
  Widget _buildStatusButtons({
    required BuildContext context,
    required TransitionChecklistItemModel item,
  }) {
    final current = item.displayStatus.toLowerCase();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildSingleStatusBtn(
          label: 'Completed',
          isActive: current == 'completed',
          activeColor: const Color(0xFF16A34A),
          activeBg: const Color(0xFFF0FDF4),
          activeBorder: const Color(0xFFBBF7D0),
          onTap: () {
            context.read<TransitionDetailBloc>().add(
                  UpdateChecklistItemEvent(
                    phase: item.phase,
                    key: item.key,
                    status: 'COMPLETED',
                    done: true,
                  ),
                );
            setState(() {
              _openPendingForms[item.key] = false;
            });
          },
        ),
        const SizedBox(width: 4),
        _buildSingleStatusBtn(
          label: 'Pending',
          isActive: current == 'pending',
          activeColor: const Color(0xFFD97706),
          activeBg: const Color(0xFFFFFBEB),
          activeBorder: const Color(0xFFFDE68A),
          onTap: () {
            context.read<TransitionDetailBloc>().add(
                  UpdateChecklistItemEvent(
                    phase: item.phase,
                    key: item.key,
                    status: 'PENDING',
                    done: false,
                  ),
                );
            if (item.canRaiseTicket) {
              setState(() {
                _openPendingForms[item.key] = true;
              });
            }
          },
        ),
        const SizedBox(width: 4),
        _buildSingleStatusBtn(
          label: 'In progress',
          isActive: current == 'in progress',
          activeColor: const Color(0xFF2563EB),
          activeBg: const Color(0xFFEFF6FF),
          activeBorder: const Color(0xFFBFDBFE),
          onTap: () {
            context.read<TransitionDetailBloc>().add(
                  UpdateChecklistItemEvent(
                    phase: item.phase,
                    key: item.key,
                    status: 'IN_PROGRESS',
                    done: false,
                  ),
                );
            setState(() {
              _openPendingForms[item.key] = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSingleStatusBtn({
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color activeBg,
    required Color activeBorder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeBorder : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? activeColor : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistDateField({
    required BuildContext context,
    required String label,
    required String? dateStr,
    required ValueChanged<String> onSelected,
  }) {
    final hasDate = dateStr != null && dateStr.trim().isNotEmpty;
    final display = hasDate ? TransitionDateHelper.formatDate(dateStr) : 'Select date';

    return InkWell(
      onTap: () async {
        final initial = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          final ymd =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onSelected(ymd);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: _kBlue),
            const SizedBox(width: 6),
            Text(
              display,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                color: hasDate ? _kDark : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pending Issue Box (Matching Image 4) ────────────────────────────────────
  Widget _buildPendingIssueBox({
    required BuildContext context,
    required TransitionChecklistItemModel item,
    required List<ZoneUserModel> zoneUsers,
  }) {
    final issueCtrl = _issueControllers.putIfAbsent(
      item.key,
      () => TextEditingController(text: item.issue ?? ''),
    );
    final remarksCtrl = _remarksControllers.putIfAbsent(
      item.key,
      () => TextEditingController(text: item.remarks ?? ''),
    );

    if (_selectedOwnerIds[item.key] == null && zoneUsers.isNotEmpty) {
      _selectedOwnerIds[item.key] = zoneUsers.first.id;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: issueCtrl,
                            style: GoogleFonts.outfit(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Pending issue *',
                              hintStyle: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedOwnerIds[item.key],
                            style: GoogleFonts.outfit(fontSize: 12, color: _kDark),
                            decoration: InputDecoration(
                              hintText: 'Select HR Owner *',
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            items: zoneUsers.map((u) {
                              return DropdownMenuItem(
                                value: u.id,
                                child: Text(
                                  '${u.name} · ${u.roleDisplay}',
                                  style: GoogleFonts.outfit(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedOwnerIds[item.key] = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: remarksCtrl,
                            style: GoogleFonts.outfit(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Remarks / details',
                              hintStyle: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: issueCtrl,
                          style: GoogleFonts.outfit(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'Pending issue *',
                            hintStyle: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedOwnerIds[item.key],
                          style: GoogleFonts.outfit(fontSize: 12, color: _kDark),
                          decoration: InputDecoration(
                            hintText: 'Select HR Owner *',
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          items: zoneUsers.map((u) {
                            return DropdownMenuItem(
                              value: u.id,
                              child: Text(
                                '${u.name} · ${u.roleDisplay}',
                                style: GoogleFonts.outfit(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedOwnerIds[item.key] = val;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: remarksCtrl,
                          style: GoogleFonts.outfit(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'Remarks / details',
                            hintStyle: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ticket raise is enabled for this line — submit to create an issue.',
                  style: GoogleFonts.outfit(fontSize: 11.5, color: _kSlate),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _openPendingForms[item.key] = false;
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      final issueText = issueCtrl.text.trim();
                      if (issueText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter pending issue description.')),
                        );
                        return;
                      }
                      context.read<TransitionDetailBloc>().add(
                            RaiseTransitionIssueEvent(
                              siteId: widget.siteId,
                              phase: item.phase,
                              key: item.key,
                              issue: issueText,
                              ownerId: _selectedOwnerIds[item.key] ?? '',
                              remarks: remarksCtrl.text.trim(),
                            ),
                          );
                      setState(() {
                        _openPendingForms[item.key] = false;
                      });
                    },
                    icon: const Icon(Icons.warning_amber_rounded,
                        size: 14, color: Color(0xFFF59E0B)),
                    label: Text(
                      'Submit',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Resolve Participant Info (Name, Department, Role) ──────────────────────
  ({String name, String department, String roleDisplay}) _resolveParticipant(
    String pId,
    List<ZoneUserModel> zoneUsers,
  ) {
    // 1. Try ZoneUsers from the site response
    final zUser = zoneUsers.where((u) => u.id == pId || u.name.toLowerCase() == pId.toLowerCase()).firstOrNull;
    if (zUser != null) {
      return (
        name: zUser.name,
        department: zUser.department,
        roleDisplay: zUser.roleDisplay,
      );
    }

    // 2. Try UserService (/api/admin/users)
    final adminUser = UserService.instance.getUserById(pId) ??
        UserService.instance.users.where((u) => u.name.toLowerCase() == pId.toLowerCase()).firstOrNull;
    if (adminUser != null) {
      return (
        name: adminUser.name,
        department: adminUser.department,
        roleDisplay: adminUser.roleLabel,
      );
    }

    // 3. Try MetaService (/api/meta)
    final metaUser = MetaService.instance.meta.users
        .where((u) => u.id == pId || u.name.toLowerCase() == pId.toLowerCase())
        .firstOrNull;
    if (metaUser != null) {
      return (
        name: metaUser.name,
        department: metaUser.department,
        roleDisplay: metaUser.displayWithRole.split(' · ').last,
      );
    }

    // Fallback if not matched anywhere
    return (
      name: pId,
      department: 'Participant',
      roleDisplay: '',
    );
  }

  // ── Participants Multi-Select (Matching Image 5) ───────────────────────────
  Widget _buildParticipantsSelector(
    BuildContext context,
    TransitionKickoffModel kickoff,
    List<ZoneUserModel> zoneUsers,
  ) {
    // Combine all available users from zoneUsers, UserService, and MetaService
    final allUsersMap =
        <String, ({String id, String name, String department, String roleDisplay, bool isLd})>{};

    for (final u in zoneUsers) {
      allUsersMap[u.id] = (
        id: u.id,
        name: u.name,
        department: u.department,
        roleDisplay: u.roleDisplay,
        isLd: u.isLdDepartment,
      );
    }

    for (final u in UserService.instance.users) {
      if (!allUsersMap.containsKey(u.id)) {
        allUsersMap[u.id] = (
          id: u.id,
          name: u.name,
          department: u.department,
          roleDisplay: u.roleLabel,
          isLd: u.department == 'L&D',
        );
      }
    }

    for (final u in MetaService.instance.meta.users) {
      if (!allUsersMap.containsKey(u.id)) {
        allUsersMap[u.id] = (
          id: u.id,
          name: u.name,
          department: u.department,
          roleDisplay: u.displayWithRole.split(' · ').last,
          isLd: u.department == 'L&D',
        );
      }
    }

    final availableUsers = allUsersMap.values.toList()
      ..sort((a, b) {
        if (a.isLd && !b.isLd) return -1;
        if (!a.isLd && b.isLd) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kick-Off Participants',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kSlate,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kickoff.participants.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: kickoff.participants.map((pId) {
                    final info = _resolveParticipant(pId, zoneUsers);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                text: info.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue,
                                ),
                                children: [
                                  TextSpan(
                                    text: '  ·  ${info.department}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              final updated = List<String>.from(kickoff.participants)
                                ..remove(pId);
                              context.read<TransitionDetailBloc>().add(
                                    UpdateKickoffField(participants: updated),
                                  );
                            },
                            child: const Icon(Icons.close, size: 14, color: _kBlue),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
              ],
              PopupMenuButton<String>(
                tooltip: 'Select participant',
                onSelected: (selectedId) {
                  if (!kickoff.participants.contains(selectedId)) {
                    final updated = List<String>.from(kickoff.participants)..add(selectedId);
                    context.read<TransitionDetailBloc>().add(
                          UpdateKickoffField(participants: updated),
                        );
                  }
                },
                itemBuilder: (context) {
                  return availableUsers.map((u) {
                    final isAlreadySelected = kickoff.participants.contains(u.id);
                    return PopupMenuItem<String>(
                      value: u.id,
                      child: Row(
                        children: [
                          Icon(
                            isAlreadySelected ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 18,
                            color: isAlreadySelected ? _kBlue : _kSlate,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${u.name} · ${u.department} (${u.roleDisplay})',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight:
                                    isAlreadySelected ? FontWeight.w600 : FontWeight.w400,
                                color: _kDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        kickoff.participants.isEmpty
                            ? 'Select participants...'
                            : 'Add participant...',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: kickoff.participants.isEmpty
                              ? const Color(0xFF94A3B8)
                              : _kBlue,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Everyone allocated to this site\'s zone. Select more than one.',
          style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
        ),
      ],
    );
  }

  // ── Date Picker Button with Day of Week (Image 5) ───────────────────────────
  Widget _buildDatePickerButton({
    required BuildContext context,
    required String label,
    required String currentDate,
    required String subtitle,
    required ValueChanged<String> onDateSelected,
    required VoidCallback onClear,
  }) {
    final hasDate = currentDate.isNotEmpty;
    final display = hasDate ? _formatDateWithDay(currentDate) : 'Select date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kSlate,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final initial = DateTime.tryParse(currentDate) ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              final ymd =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              onDateSelected(ymd);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: _kBlue),
                const SizedBox(width: 8),
                Text(
                  display,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                    color: hasDate ? _kDark : const Color(0xFF94A3B8),
                  ),
                ),
                if (hasDate) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onClear,
                    child: const Icon(Icons.close, size: 14, color: _kSlate),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
        ),
      ],
    );
  }

  // ── Interactive Toggle Field (Yes / No) ────────────────────────────────────
  Widget _buildInteractiveToggleField({
    required String label,
    required bool isYes,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kSlate,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildClickableSegmentOption('Yes', isYes, () => onChanged(true)),
              _buildClickableSegmentOption('No', !isYes, () => onChanged(false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickableSegmentOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _StepConfig {
  final int stepIndex;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isSelected;
  final bool isRestrictedToHead;

  const _StepConfig({
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isSelected,
    this.isRestrictedToHead = false,
  });
}
