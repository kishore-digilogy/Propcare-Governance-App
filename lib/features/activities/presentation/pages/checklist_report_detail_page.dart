import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/activities_remote_datasource.dart';
import '../../data/models/checklist_report_model.dart';
import '../bloc/checklist_report_bloc.dart';
import '../bloc/checklist_report_event.dart';
import '../bloc/checklist_report_state.dart';

class ChecklistReportDetailPage extends StatefulWidget {
  final String siteId;
  final String siteName;
  final String? initialActivityId;
  final ChecklistReportBloc? bloc;

  const ChecklistReportDetailPage({
    super.key,
    required this.siteId,
    required this.siteName,
    this.initialActivityId,
    this.bloc,
  });

  @override
  State<ChecklistReportDetailPage> createState() =>
      _ChecklistReportDetailPageState();
}

class _ChecklistReportDetailPageState extends State<ChecklistReportDetailPage> {
  late final ChecklistReportBloc _bloc;
  final bool _ownsBloc = false;

  // Cache text controllers for remarks to prevent recreating them on every rebuild
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ??
        ChecklistReportBloc(
          remoteDataSource: ActivitiesRemoteDataSourceImpl(),
        );

    _bloc.add(LoadSiteChecklistDetail(
      siteId: widget.siteId,
      initialActivityId: widget.initialActivityId,
    ));
  }

  @override
  void dispose() {
    for (final controller in _remarksControllers.values) {
      controller.dispose();
    }
    _remarksControllers.clear();
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  TextEditingController _getRemarksController(String key, String initialText) {
    if (!_remarksControllers.containsKey(key)) {
      _remarksControllers[key] = TextEditingController(text: initialText);
    }
    return _remarksControllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ChecklistReportBloc, ChecklistReportState>(
        listener: (context, state) {
          if (state.saveSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Checklist saved successfully',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.saveError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to save checklist: ${state.saveError}',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: state.isLoadingDetail && state.detailSite == null
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : state.detailError != null && state.detailSite == null
                      ? _buildErrorView(state.detailError!)
                      : _buildContent(state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              'Failed to load site checklist',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _bloc.add(LoadSiteChecklistDetail(
                siteId: widget.siteId,
                initialActivityId: widget.initialActivityId,
              )),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ChecklistReportState state) {
    final activity = state.selectedActivity;
    final site = state.detailSite;
    final siteName = site?.siteName.isNotEmpty == true
        ? site!.siteName
        : widget.siteName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 960;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 16 : 28,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Breadcrumbs & Back
              _buildTopBar(siteName),
              const SizedBox(height: 16),

              // Title, Subtitle, and Summary Badges
              _buildTitleSection(activity, siteName, state),
              const SizedBox(height: 20),

              // Visit Date Tabs
              if (site != null && site.items.isNotEmpty)
                _buildVisitDateTabs(site, state),
              const SizedBox(height: 24),

              // Responsive Two-Column or Stacked View
              if (isNarrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChecklistSection(activity, state),
                    const SizedBox(height: 24),
                    _buildActivityMasterCard(activity, siteName, site),
                    const SizedBox(height: 16),
                    _buildFollowUpCard(state),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column: Checklist
                    Expanded(
                      flex: 7,
                      child: _buildChecklistSection(activity, state),
                    ),
                    const SizedBox(width: 24),
                    // Right column: Activity Master & Follow-Up
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildActivityMasterCard(activity, siteName, site),
                          const SizedBox(height: 16),
                          _buildFollowUpCard(state),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(String siteName) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Checklist Report',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded,
            size: 16, color: Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(
          siteName,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(
    SiteChecklistActivityItemModel? activity,
    String siteName,
    ChecklistReportState state,
  ) {
    final role = activity?.roleLabel.isNotEmpty == true
        ? activity!.roleLabel
        : 'Cluster Lead';
    final code = activity?.code.isNotEmpty == true ? activity!.code : 'ACT-2882C';
    final date = activity?.visitDate.isNotEmpty == true
        ? activity!.visitDate
        : '3 Nov 2026';

    final totalCount = activity?.template.length ?? 0;
    final yesCount = state.currentYesCount;
    final noCount = state.currentNoCount;
    final naCount = state.currentNaCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          siteName,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$role · Walk Around Follow-Up · $code · $date',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBadge('$totalCount Items', const Color(0xFFF1F5F9),
                const Color(0xFF475569)),
            _buildBadge('Completed $yesCount', const Color(0xFFDCFCE7),
                const Color(0xFF16A34A)),
            _buildBadge('Pending $noCount', const Color(0xFFFEF3C7),
                const Color(0xFFD97706)),
            _buildBadge(
                'NA $naCount', const Color(0xFFF1F5F9), const Color(0xFF64748B)),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildVisitDateTabs(
    SiteChecklistDetailResponseModel site,
    ChecklistReportState state,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: site.items.map((item) {
          final isSelected = item.id == state.selectedActivity?.id;
          final dateText = item.visitDate.isNotEmpty
              ? item.visitDate
              : item.scheduledDate;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                _bloc.add(SelectVisitDate(item.id));
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateText,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    if (item.pending > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.pending}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChecklistSection(
    SiteChecklistActivityItemModel? activity,
    ChecklistReportState state,
  ) {
    if (activity == null || activity.template.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            'No checklist items available for this visit',
            style: GoogleFonts.outfit(
                fontSize: 14, color: const Color(0xFF64748B)),
          ),
        ),
      );
    }

    // Group template items by section
    final grouped = <String, List<ChecklistTemplateItemModel>>{};
    for (final tmpl in activity.template) {
      final sec = tmpl.section.isNotEmpty ? tmpl.section : 'General';
      grouped.putIfAbsent(sec, () => []).add(tmpl);
    }

    final role = activity.roleLabel.isNotEmpty
        ? activity.roleLabel
        : 'Cluster Lead';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Walk Around Checklist · $role',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${activity.template.length} items',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Yes / No / NA · Remarks On No · Update & Save',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Section Cards
        ...grouped.entries.map((entry) {
          return _buildSectionCard(entry.key, entry.value, state);
        }),

        const SizedBox(height: 20),

        // Save Checklist Button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: state.isSaving
                ? null
                : () {
                    _bloc.add(const SaveCurrentChecklist());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFF93C5FD),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save checklist',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    String sectionTitle,
    List<ChecklistTemplateItemModel> items,
    ChecklistReportState state,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              sectionTitle,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'AREA',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    'STATUS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Text(
                    'REMARKS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, idx) {
              final tmpl = items[idx];
              final ans = state.currentAnswers[tmpl.key] ??
                  ChecklistAnswerItemModel(
                    key: tmpl.key,
                    status: 'OK',
                    remarks: '',
                  );

              final isNo = ans.status == 'ISSUE';

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isNo ? const Color(0xFFFFF5F5) : Colors.white,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Area title
                    Expanded(
                      flex: 5,
                      child: Text(
                        tmpl.title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status segmented pill buttons (Yes | No | NA)
                    SizedBox(
                      width: 140,
                      child: _buildStatusPillSelector(tmpl.key, ans.status),
                    ),
                    const SizedBox(width: 12),

                    // Remarks field
                    Expanded(
                      flex: 4,
                      child: _buildRemarksField(tmpl.key, ans.remarks, isNo),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPillSelector(String key, String currentStatus) {
    // Current mapping:
    // 'OK' -> Yes
    // 'ISSUE' -> No
    // 'NA' -> NA

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillOption(
            label: 'Yes',
            isSelected: currentStatus == 'OK',
            activeBg: const Color(0xFFDCFCE7),
            activeText: const Color(0xFF16A34A),
            onTap: () {
              _bloc.add(UpdateChecklistAnswer(key: key, status: 'OK'));
            },
          ),
          _buildPillOption(
            label: 'No',
            isSelected: currentStatus == 'ISSUE',
            activeBg: const Color(0xFFFEE2E2),
            activeText: const Color(0xFFEF4444),
            onTap: () {
              _bloc.add(UpdateChecklistAnswer(key: key, status: 'ISSUE'));
            },
          ),
          _buildPillOption(
            label: 'NA',
            isSelected: currentStatus == 'NA',
            activeBg: const Color(0xFFE2E8F0),
            activeText: const Color(0xFF475569),
            onTap: () {
              _bloc.add(UpdateChecklistAnswer(key: key, status: 'NA'));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillOption({
    required String label,
    required bool isSelected,
    required Color activeBg,
    required Color activeText,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeText : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemarksField(String key, String currentRemarks, bool isNo) {
    final controller = _getRemarksController(key, currentRemarks);

    // Keep controller in sync if state changed externally
    if (controller.text != currentRemarks && !controller.value.isComposingRangeValid) {
      controller.text = currentRemarks;
    }

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isNo ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Optional',
          hintStyle: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
        onChanged: (val) {
          _bloc.add(UpdateChecklistAnswer(key: key, remarks: val));
        },
      ),
    );
  }

  Widget _buildActivityMasterCard(
    SiteChecklistActivityItemModel? activity,
    String siteName,
    SiteChecklistDetailResponseModel? site,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Activity Master',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Activity ID', activity?.code ?? '—'),
                _buildInfoRow('Site', siteName),
                _buildInfoRow('Role', activity?.roleLabel ?? '—'),
                _buildInfoRow('SPOC', activity?.spoc ?? 'Balasubramani'),
                _buildInfoRow('Client Type',
                    activity?.clientType ?? site?.siteClientType ?? 'A'),
                _buildInfoRow('Frequency', activity?.frequencyLabel ?? 'Monthly'),
                _buildInfoRow('Visit Date', activity?.visitDate ?? '—'),
                _buildInfoRow('Due', activity?.dueDate ?? '—'),
                _buildInfoRow('MOM', activity?.mom ?? 'Sent'),
                _buildInfoRow('Status', activity?.status ?? 'Completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard(ChecklistReportState state) {
    final yesCount = state.currentYesCount;
    final noCount = state.currentNoCount;
    final naCount = state.currentNaCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow-Up',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Text(
              'Mark Pending (No) Lines As Yes After Fix. Save At The Bottom — MOM Send Is Separate.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF1E40AF),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildFollowUpPill('Yes $yesCount', const Color(0xFFDCFCE7),
                  const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              _buildFollowUpPill('No $noCount', const Color(0xFFFEF3C7),
                  const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _buildFollowUpPill('NA $naCount', const Color(0xFFF1F5F9),
                  const Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpPill(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
