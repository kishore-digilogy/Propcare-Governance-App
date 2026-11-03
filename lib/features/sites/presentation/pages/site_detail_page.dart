import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/datasources/sites_remote_datasource.dart';
import '../../data/models/site_detail_model.dart';
import '../../../activities/presentation/pages/activity_execution_page.dart';
import '../bloc/site_detail_bloc.dart';
import '../bloc/site_detail_event.dart';
import '../bloc/site_detail_state.dart';
import '../widgets/site_action_dialogs.dart';

const Color _kBlue = Color(0xFF1A73E8);
const Color _kDark = Color(0xFF0F172A);
const Color _kSlate = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kBg = Color(0xFFF8FAFC);
const Color _kGreen = Color(0xFF16A34A);
const Color _kRed = Color(0xFFEF4444);
const Color _kAmber = Color(0xFFD97706);

class SiteDetailPage extends StatelessWidget {
  final String siteId;
  final SiteDetailBloc? bloc;
  final Widget Function(BuildContext context, String activityId)? activityExecutionPageBuilder;

  const SiteDetailPage({
    super.key,
    required this.siteId,
    this.bloc,
    this.activityExecutionPageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: _SiteDetailView(
          siteId: siteId,
          activityExecutionPageBuilder: activityExecutionPageBuilder,
        ),
      );
    }

    return BlocProvider(
      create: (_) => SiteDetailBloc(
        dataSource: SitesRemoteDataSourceImpl(),
      )..add(LoadSiteDetail(siteId)),
      child: _SiteDetailView(
        siteId: siteId,
        activityExecutionPageBuilder: activityExecutionPageBuilder,
      ),
    );
  }
}

class _SiteDetailView extends StatelessWidget {
  final String siteId;
  final Widget Function(BuildContext context, String activityId)? activityExecutionPageBuilder;

  const _SiteDetailView({
    required this.siteId,
    this.activityExecutionPageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: BlocConsumer<SiteDetailBloc, SiteDetailState>(
          listener: (context, state) {
            if (state is SiteDetailLoaded) {
              if (state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                );
              } else if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: _kRed,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            if (state is SiteDetailLoading || state is SiteDetailInitial) {
              return const Center(child: CircularProgressIndicator(color: _kBlue));
            }

            if (state is SiteDetailError) {
              return _buildErrorView(context, state.message);
            }

            if (state is SiteDetailLoaded) {
              return _buildLoadedView(context, state.detail);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, SiteDetailResponseModel detail) {
    final site = detail.site;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : 16,
            vertical: 18,
          ),
          children: [
            // ── Breadcrumb & Top Bar with Clear Back Button ──────────────────
            Row(
              children: [
                InkWell(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          'Back',
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
                const SizedBox(width: 12),
                Text(
                  'Sites',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kSlate,
                  ),
                ),
                Text(
                  '  ›  ',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                ),
                Text(
                  site.code,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: _kDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Title Header & Action Buttons (Screenshot 1) ─────────────────
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildTitleAndChips(site)),
                  const SizedBox(width: 16),
                  _buildActionButtons(context, site),
                ],
              )
            else ...[
              _buildTitleAndChips(site),
              const SizedBox(height: 14),
              _buildActionButtons(context, site),
            ],
            const SizedBox(height: 20),

            // ── 4 Stat Cards Row ──────────────────────────────────────────────
            _buildStatCardsRow(site, isDesktop),
            const SizedBox(height: 22),

            // ── 2-Column Split: Governance Activities (Left) + Site Master (Right) ─
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 65,
                    child: _buildGovernanceActivitiesCard(context, detail.activities),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 35,
                    child: _buildSiteMasterCard(site),
                  ),
                ],
              )
            else ...[
              _buildGovernanceActivitiesCard(context, detail.activities),
              const SizedBox(height: 18),
              _buildSiteMasterCard(site),
            ],
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildTitleAndChips(SiteDetailModel site) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          site.name,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          site.zoneAndClusterBreadcrumb,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: _kSlate,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),

        // Badges Row: [● LIVE] [A] [Billing PM ₹7.40L] [HK] [Start-up 2 Nov 2026]
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: site.status == 'LIVE' ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: site.status == 'LIVE' ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: site.status == 'LIVE' ? _kGreen : _kSlate,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    site.status,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: site.status == 'LIVE' ? _kGreen : _kDark,
                    ),
                  ),
                ],
              ),
            ),

            // Client Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                site.clientType,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
            ),

            // Billing PM
            _buildInfoChip('Billing PM ${site.formattedBillingPm}'),

            // Service
            if (site.service.isNotEmpty) _buildInfoChip(site.service),

            // Start Date
            _buildInfoChip('Start-up ${site.formattedActualStartDate}'),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SiteDetailModel site) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 1. Mark special attention button
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBlue,
            side: const BorderSide(color: Color(0xFF93C5FD)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => SpecialAttentionDialog(
                site: site,
                onConfirm: (fromDate, toDate, reason) {
                  context.read<SiteDetailBloc>().add(
                        SubmitSpecialAttention(
                          siteId: site.id,
                          enabled: true,
                          fromDate: fromDate.toIso8601String().substring(0, 10),
                          toDate: toDate.toIso8601String().substring(0, 10),
                          reason: reason,
                        ),
                      );
                },
              ),
            );
          },
          child: Text(
            'Mark special attention',
            style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),

        // 2. Client type button
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBlue,
            side: const BorderSide(color: Color(0xFF93C5FD)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => ClientTypeDialog(
                site: site,
                onConfirm: (type, reason) {
                  final now = DateTime.now();
                  final todayStr =
                      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                  context.read<SiteDetailBloc>().add(
                        SubmitClassification(
                          siteId: site.id,
                          clientType: type,
                          effectiveDate: todayStr,
                          reason: reason,
                        ),
                      );
                },
              ),
            );
          },
          child: Text(
            'Client type',
            style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),

        // 3. Mark inactive button
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            side: const BorderSide(color: Color(0xFFFCA5A5)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => MarkInactiveDialog(
                site: site,
                onConfirm: (reason) {
                  context.read<SiteDetailBloc>().add(
                        SubmitLifecycle(
                          siteId: site.id,
                          action: 'inactive',
                          reason: reason,
                        ),
                      );
                },
              ),
            );
          },
          child: Text(
            'Mark inactive',
            style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ── 4 Stat Cards Row (Manpower, Open issues, Machinery, Next Activity) ──────
  Widget _buildStatCardsRow(SiteDetailModel site, bool isDesktop) {
    final cards = [
      _buildStatCard(
        title: 'Manpower',
        value: '${site.manpowerDeployed}/${site.manpowerRequired}',
        subtitle: 'Shortage ${site.shortage}',
        subtitleColor: _kRed,
        accentColor: _kRed,
      ),
      _buildStatCard(
        title: 'Open issues',
        value: '${site.openIssuesCount}',
        subtitle: 'Across all functions',
        accentColor: _kAmber,
      ),
      _buildStatCard(
        title: 'Machinery',
        value: '${site.machineryCount}',
        subtitle: 'Under PPM schedule',
        accentColor: const Color(0xFF475569),
      ),
      _buildStatCard(
        title: 'Next Activity',
        value: site.formattedNextActivityDay,
        subtitle: site.nextActivityTitle ?? 'Scheduled Visit',
        accentColor: _kBlue,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: cards,
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    Color? subtitleColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -14,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3.5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kSlate,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor ?? _kSlate,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Governance Activities Card (Card View) ────────────────────────────────
  Widget _buildGovernanceActivitiesCard(BuildContext context, List<SiteActivityModel> activities) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Governance Activities',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
                Text(
                  '${activities.length} total',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _kSlate,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No governance activities scheduled',
                  style: GoogleFonts.outfit(color: _kSlate),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _buildActivityCard(context, activities[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, SiteActivityModel act) {
    final isCompleted = act.status == 'COMPLETED';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (ctx) => activityExecutionPageBuilder != null
                  ? activityExecutionPageBuilder!(ctx, act.id)
                  : ActivityExecutionPage(
                      activityId: act.id,
                    ),
            ),
          );
          if (result == true && context.mounted) {
            context.read<SiteDetailBloc>().add(LoadSiteDetail(siteId));
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kDark,
                          ),
                        ),
                        if (act.code.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            act.code,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _kSlate,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? _kGreen : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          act.statusDisplay,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCompleted ? const Color(0xFF15803D) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActivityDetailMeta(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: act.roleLabel,
                    ),
                  ),
                  Expanded(
                    child: _buildActivityDetailMeta(
                      icon: Icons.person_outline_rounded,
                      label: 'SPOC',
                      value: act.spocName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildActivityDetailMeta(
                      icon: Icons.repeat_rounded,
                      label: 'Frequency',
                      value: act.freq,
                    ),
                  ),
                  Expanded(
                    child: _buildActivityDetailMeta(
                      icon: Icons.calendar_today_rounded,
                      label: 'Due',
                      value: act.formattedDueDate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityDetailMeta({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: _kSlate),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: _kSlate,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Site Master Card (Right Column Key-Value List) ────────────────────────
  Widget _buildSiteMasterCard(SiteDetailModel site) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Text(
                'Site Master',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          _buildMasterRow('Site code', site.code),
          _buildMasterRow('Client', site.clientName),
          _buildMasterRow('Contact person', site.contactPersonName ?? '—'),
          _buildMasterRow('Contact email', site.clientEmail ?? '—'),
          _buildMasterRow('Contact phone', site.contactPhone ?? '—'),
          _buildMasterRow('Zone / Group', site.zoneGroupDisplay),
          _buildMasterRow('Cluster', site.clusterName.isNotEmpty ? site.clusterName : site.cluster),
          _buildMasterRow('Zonal head', site.zonalHead),
          _buildMasterRow('Group cluster head', site.groupClusterHead),
          _buildMasterRow('Cluster head', site.clusterHead),
          _buildMasterRow('Cluster lead', site.clusterLead),
          _buildMasterRow('Field executive', site.fieldExecutive),
          _buildMasterRow('Contract award', site.formattedContractAwardDate),
          _buildMasterRow('Actual start-up', site.formattedActualStartDate),
        ],
      ),
    );
  }

  Widget _buildMasterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 45,
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 12.5, color: _kSlate),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 55,
            child: Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kRed),
            const SizedBox(height: 12),
            Text(
              'Failed to load site details',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SiteDetailBloc>().add(LoadSiteDetail(siteId));
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

