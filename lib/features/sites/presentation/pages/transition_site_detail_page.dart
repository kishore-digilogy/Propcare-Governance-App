import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _TransitionSiteDetailView extends StatelessWidget {
  final String siteId;

  const _TransitionSiteDetailView({required this.siteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: BlocBuilder<TransitionDetailBloc, TransitionDetailState>(
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
                    .add(LoadTransitionDetail(siteId: siteId, isRefresh: true));
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
            .add(LoadTransitionDetail(siteId: siteId, isRefresh: true));
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

              // ── 4-Stage Stepper Bar ─────────────────────────────────────────
              _buildStepperCard(context, state, isDesktop),
              const SizedBox(height: 16),

              // ── Active Step Body ───────────────────────────────────────────
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
                'Back to Sites List',
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
                // Site title & code
                _buildSiteTitleAndCode(site),
                // 3 Date cards
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              site.name,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                site.status.isNotEmpty ? site.status[0].toUpperCase() + site.status.substring(1).toLowerCase() : 'Live',
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
          site.code,
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

  // ── 4-Stage Stepper Card ────────────────────────────────────────────────────
  Widget _buildStepperCard(
    BuildContext context,
    TransitionDetailLoaded state,
    bool isDesktop,
  ) {
    final selectedStep = state.selectedStep;

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
                Expanded(
                  child: _buildStepItem(
                    context: context,
                    stepIndex: 1,
                    title: 'Site Creation',
                    subtitle: 'Completed',
                    isCompleted: true,
                    isSelected: selectedStep == 1,
                    icon: Icons.apartment_outlined,
                    isDesktop: true,
                  ),
                ),
                _buildStepArrow(),
                Expanded(
                  child: _buildStepItem(
                    context: context,
                    stepIndex: 2,
                    title: 'Internal Checklist',
                    subtitle: 'L&D Team',
                    isCompleted: false,
                    isSelected: selectedStep == 2,
                    icon: Icons.assignment_outlined,
                    isDesktop: true,
                  ),
                ),
                _buildStepArrow(),
                Expanded(
                  child: _buildStepItem(
                    context: context,
                    stepIndex: 3,
                    title: 'L&D Checklist',
                    subtitle: 'L&D Team',
                    isCompleted: false,
                    isSelected: selectedStep == 3,
                    icon: Icons.auto_awesome_outlined,
                    isDesktop: true,
                  ),
                ),
                _buildStepArrow(),
                Expanded(
                  child: _buildStepItem(
                    context: context,
                    stepIndex: 4,
                    title: 'Stability Verify',
                    subtitle: 'L&D Head',
                    isCompleted: false,
                    isSelected: selectedStep == 4,
                    icon: Icons.verified_user_outlined,
                    isDesktop: true,
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStepItem(
                    context: context,
                    stepIndex: 1,
                    title: 'Site Creation',
                    subtitle: 'Completed',
                    isCompleted: true,
                    isSelected: selectedStep == 1,
                    icon: Icons.apartment_outlined,
                    isDesktop: false,
                  ),
                  _buildStepArrow(),
                  _buildStepItem(
                    context: context,
                    stepIndex: 2,
                    title: 'Internal Checklist',
                    subtitle: 'L&D Team',
                    isCompleted: false,
                    isSelected: selectedStep == 2,
                    icon: Icons.assignment_outlined,
                    isDesktop: false,
                  ),
                  _buildStepArrow(),
                  _buildStepItem(
                    context: context,
                    stepIndex: 3,
                    title: 'L&D Checklist',
                    subtitle: 'L&D Team',
                    isCompleted: false,
                    isSelected: selectedStep == 3,
                    icon: Icons.auto_awesome_outlined,
                    isDesktop: false,
                  ),
                  _buildStepArrow(),
                  _buildStepItem(
                    context: context,
                    stepIndex: 4,
                    title: 'Stability Verify',
                    subtitle: 'L&D Head',
                    isCompleted: false,
                    isSelected: selectedStep == 4,
                    icon: Icons.verified_user_outlined,
                    isDesktop: false,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStepItem({
    required BuildContext context,
    required int stepIndex,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isSelected,
    required IconData icon,
    required bool isDesktop,
  }) {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: _kDark,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isCompleted ? _kGreen : _kSlate,
          ),
        ),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        context.read<TransitionDetailBloc>().add(SelectTransitionStep(stepIndex));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _kBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge / Number Circle
            if (isCompleted)
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
                  color: isSelected ? _kBlue : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: isSelected ? null : Border.all(color: const Color(0xFFCBD5E1)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$stepIndex',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _kSlate,
                  ),
                ),
              ),
            const SizedBox(width: 10),

            // Titles
            if (isDesktop)
              Expanded(child: titleColumn)
            else
              titleColumn,
            const SizedBox(width: 8),

            // Small side icon
            Icon(
              icon,
              size: 16,
              color: isSelected ? _kBlue : (isCompleted ? _kGreen : const Color(0xFF94A3B8)),
            ),
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
        return _buildStep1SiteCreation(state.response.site);
      case 2:
        return _buildStep2InternalChecklist(context, state);
      case 3:
        return _buildStep3LdChecklist(context, state);
      case 4:
        return _buildStep4StabilityVerify(state.response);
      default:
        return _buildStep2InternalChecklist(context, state);
    }
  }

  // ── Step 1: Site Creation Summary ──────────────────────────────────────────
  Widget _buildStep1SiteCreation(TransitionSiteInfoModel site) {
    return Container(
      padding: const EdgeInsets.all(22),
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
                  'Site Creation',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Completed',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _kGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 16),
          _buildInfoRow('Client Name', site.clientName),
          _buildInfoRow('Site Code', site.code),
          _buildInfoRow('Zone & Cluster', '${site.zoneName} · ${site.clusterName}'),
          _buildInfoRow('Service', site.serviceName.isNotEmpty ? site.serviceName : 'HK'),
          _buildInfoRow('Client Type', site.clientType),
          _buildInfoRow('Mode', site.mode),
          _buildInfoRow('Billing PM', '₹${site.billingPm}'),
          _buildInfoRow(
            'Manpower',
            'Deployed: ${site.manpowerDeployed} / Required: ${site.manpowerRequired} (Shortage: ${site.shortage})',
          ),
          _buildInfoRow('Contract Start', site.formattedStartDate),
          _buildInfoRow('Contract End', site.formattedEndDate),
        ],
      ),
    );
  }

  // ── Step 2: Internal Checklist ─────────────────────────────────────────────
  Widget _buildStep2InternalChecklist(
    BuildContext context,
    TransitionDetailLoaded state,
  ) {
    final preview = state.response.ldPreview;
    final kickoff = preview.kickoff;
    final items = preview.internal.isNotEmpty
        ? preview.internal
        : state.response.transitions.where((t) => t.phase == 'INTERNAL').toList();

    final openCount = items.where((i) => i.displayStatus != 'Completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Client Kick-Off ──
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

              // Row 1: Kick-Off With Client, Date, Participants
              Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  _buildDisabledToggleField(
                    label: 'Kick-Off With Client',
                    isYes: kickoff.isWithClientYes,
                  ),
                  _buildKickoffField(
                    label: 'Kick-Off Date',
                    value: kickoff.date.isNotEmpty ? kickoff.formattedDate : '—',
                  ),
                  _buildKickoffField(
                    label: 'Kick-Off Participants',
                    value: kickoff.participants.isNotEmpty
                        ? kickoff.participants.join(', ')
                        : '—',
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Row 2: Pre-Transition Meeting
              _buildDisabledToggleField(
                label: 'Pre-Transition Meeting',
                isYes: kickoff.isPreTransitionMeetingYes,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Card 2: Internal Checklist Table ──
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
                      '${items.length} Items · $openCount Open',
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

              _buildChecklistCards(items),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Action Button: Continue To L&D Checklist → ──
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: () {
                context.read<TransitionDetailBloc>().add(const SelectTransitionStep(3));
              },
              child: Text(
                'Continue To L&D Checklist →',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: L&D Checklist ──────────────────────────────────────────────────
  Widget _buildStep3LdChecklist(
    BuildContext context,
    TransitionDetailLoaded state,
  ) {
    final preview = state.response.ldPreview;
    final items = preview.ldTransition.isNotEmpty
        ? preview.ldTransition
        : state.response.transitions.where((t) => t.phase == 'LD_TRANSITION').toList();

    final openCount = items.where((i) => i.displayStatus != 'Completed').length;

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

              _buildChecklistCards(items),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Action Button: Continue To Stability Verify → ──
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: () {
                context.read<TransitionDetailBloc>().add(const SelectTransitionStep(4));
              },
              child: Text(
                'Continue To Stability Verify →',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4: Stability Verify ───────────────────────────────────────────────
  Widget _buildStep4StabilityVerify(TransitionSiteDetailResponseModel response) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Stability Verify',
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
                  color: response.site.ldTransitionComplete
                      ? const Color(0xFFDCFCE7)
                      : _kAmberBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  response.site.ldTransitionComplete ? 'Verified' : 'Pending',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: response.site.ldTransitionComplete ? _kGreen : _kAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Stability Verify is done by L&D Head in the L&D Transition module.',
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: _kSlate,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: _kBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'CRRM and Super Admin have read-only access to transition checklists and stability milestones.',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Common Checklist Cards (Simple Card View) ──────────────────────────────
  Widget _buildChecklistCards(List<TransitionChecklistItemModel> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No checklist items available for this phase.',
            style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildChecklistItemCard(item),
        );
      }).toList(),
    );
  }

  Widget _buildChecklistItemCard(TransitionChecklistItemModel item) {
    final isDone = item.displayStatus == 'Completed';
    final isInProgress = item.displayStatus == 'In progress';

    Color statusBg;
    Color statusBorder;
    Color statusText;
    IconData statusIcon;

    if (isDone) {
      statusBg = const Color(0xFFF0FDF4);
      statusBorder = const Color(0xFFBBF7D0);
      statusText = const Color(0xFF16A34A);
      statusIcon = Icons.check_circle_rounded;
    } else if (isInProgress) {
      statusBg = const Color(0xFFEFF6FF);
      statusBorder = const Color(0xFFBFDBFE);
      statusText = const Color(0xFF2563EB);
      statusIcon = Icons.sync_rounded;
    } else {
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusText = const Color(0xFFD97706);
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusText),
                    const SizedBox(width: 4),
                    Text(
                      item.displayStatus,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date row: Start Date & Target Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Text(
                        'Start: ',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          item.formattedStartDate,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: item.formattedStartDate == '—'
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 16, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Text(
                        'Target: ',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          item.formattedTargetDate,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: item.formattedTargetDate == '—'
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (item.remarks != null && item.remarks!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.remarks!.trim(),
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Disabled Kick-off Toggle Field (Yes / No) ──────────────────────────────
  Widget _buildSegmentOption(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF334155) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildDisabledToggleField({
    required String label,
    required bool isYes,
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
              _buildSegmentOption('Yes', isYes),
              _buildSegmentOption('No', !isYes),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKickoffField({
    required String label,
    required String value,
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
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 12.5, color: _kSlate),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
