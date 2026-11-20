import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../data/datasources/activities_remote_datasource.dart';
import '../../data/models/checklist_report_model.dart';
import '../bloc/checklist_report_bloc.dart';
import '../bloc/checklist_report_event.dart';
import '../bloc/checklist_report_state.dart';
import 'checklist_report_detail_page.dart';

class ChecklistReportPage extends StatefulWidget {
  final ChecklistReportBloc? bloc;

  const ChecklistReportPage({
    super.key,
    this.bloc,
  });

  @override
  State<ChecklistReportPage> createState() => _ChecklistReportPageState();
}

class _ChecklistReportPageState extends State<ChecklistReportPage> {
  late final ChecklistReportBloc _bloc;
  late final TextEditingController _searchController;
  final bool _ownsBloc = false;

  String _selectedStatusFilter = 'all'; // 'all' | 'pending' | 'completed'
  String? _selectedZone;
  String? _selectedCluster;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ??
        ChecklistReportBloc(
          remoteDataSource: ActivitiesRemoteDataSourceImpl(),
        );
    _searchController = TextEditingController();

    _bloc.add(const LoadChecklistReport());
    _searchController.addListener(() {
      _bloc.add(SearchChecklistReport(_searchController.text));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedStatusFilter != 'all' ||
      (_selectedZone != null && _selectedZone!.isNotEmpty) ||
      (_selectedCluster != null && _selectedCluster!.isNotEmpty);

  List<ChecklistReportItemModel> _applyFilters(List<ChecklistReportItemModel> items) {
    var list = items;
    if (_selectedStatusFilter == 'pending') {
      list = list.where((it) => it.pending > 0).toList();
    } else if (_selectedStatusFilter == 'completed') {
      list = list.where((it) => it.pending == 0).toList();
    }
    if (_selectedZone != null && _selectedZone!.isNotEmpty) {
      list = list.where((it) => it.zoneName == _selectedZone).toList();
    }
    if (_selectedCluster != null && _selectedCluster!.isNotEmpty) {
      list = list.where((it) => it.clusterName == _selectedCluster).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<ChecklistReportBloc, ChecklistReportState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leadingWidth: 64,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                'Checklist Report',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: InkWell(
                      onTap: () => _openFilterBottomSheet(context, state),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hasActiveFilters
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _hasActiveFilters
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: _hasActiveFilters
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Subtle organic background gradient and curved accent
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 240,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFEAF2FE),
                          Color(0xFFF3F7FD),
                          Color(0xFFF8FAFC),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -40,
                  right: -40,
                  width: 220,
                  height: 220,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE0EDFC).withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 40,
                  width: 140,
                  height: 140,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDBEAFE).withValues(alpha: 0.35),
                    ),
                  ),
                ),
                // Main content
                _buildBodyContent(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, ChecklistReportState state) {
    if (state.isLoadingSummary && state.summary == null) {
      return const ShimmerListLoading();
    }

    if (state.summaryError != null && state.summary == null) {
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
                'Failed to load checklist report',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.summaryError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    _bloc.add(const LoadChecklistReport(isRefresh: true)),
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

    return RefreshIndicator(
      onRefresh: () async {
        _bloc.add(const LoadChecklistReport(isRefresh: true));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 768;
          final displayedItems = _applyFilters(state.filteredItems);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 24,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildTopStatCards(state),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 16),
                if (isNarrow)
                  _buildCardsList(displayedItems)
                else
                  _buildDataTable(displayedItems),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Checklist Report',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Update walkaround pending (No) lines to completed after the visit.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(
          AppAssets.governanceClipboard,
          height: 110,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTopStatCards(ChecklistReportState state) {
    final allCount = state.summary?.allCount ?? 0;
    final pendingCount = state.summary?.pending ?? 0;
    final completedCount = state.summary?.completed ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'All',
            count: allCount,
            icon: Icons.apartment_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBgColor: const Color(0xFFEBF3FE),
            waveColor: const Color(0xFFE0EDFB).withValues(alpha: 0.55),
            isSelected: _selectedStatusFilter == 'all',
            onTap: () {
              setState(() {
                _selectedStatusFilter = 'all';
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Pending',
            count: pendingCount,
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFFEA580C),
            iconBgColor: const Color(0xFFFEF3C7),
            waveColor: const Color(0xFFFDE68A).withValues(alpha: 0.55),
            isSelected: _selectedStatusFilter == 'pending',
            onTap: () {
              setState(() {
                _selectedStatusFilter =
                    _selectedStatusFilter == 'pending' ? 'all' : 'pending';
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Completed',
            count: completedCount,
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF16A34A),
            iconBgColor: const Color(0xFFDCFCE7),
            waveColor: const Color(0xFFBBF7D0).withValues(alpha: 0.55),
            isSelected: _selectedStatusFilter == 'completed',
            onTap: () {
              setState(() {
                _selectedStatusFilter =
                    _selectedStatusFilter == 'completed' ? 'all' : 'completed';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color waveColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0x142563EB)
                  : const Color(0x06000000),
              blurRadius: isSelected ? 8 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Bottom decorative organic wave
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 24,
                child: CustomPaint(
                  painter: _CardWavePainter(waveColor: waveColor),
                ),
              ),
              // Card content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 14, color: iconColor),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$count',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Search site, zone, cluster, activity...',
          hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    _bloc.add(const SearchChecklistReport(''));
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<ChecklistReportItemModel> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Site',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Zone',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Cluster',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Frequency',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Completed',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Pending',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => _openDetail(item),
                  hoverColor: const Color(0xFFF8FAFC),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Site
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.apartment_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.siteName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Zone
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.zoneName.isNotEmpty ? item.zoneName : '—',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Cluster
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.clusterName.isNotEmpty ? item.clusterName : '—',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Activity
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.activityLabel.isNotEmpty
                                ? item.activityLabel
                                : 'Visit',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Frequency
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.frequencyLabel.isNotEmpty
                                ? item.frequencyLabel
                                : '—',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Completed pill
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${item.completed}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Pending pill
                        SizedBox(
                          width: 70,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.pending > 0
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${item.pending}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: item.pending > 0
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Chevron
                        const SizedBox(
                          width: 32,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList(List<ChecklistReportItemModel> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _openDetail(item),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFFAFCFF),
                  Color(0xFFF1F6FD),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Top-right organic subtle waves
                  Positioned(
                    top: 0,
                    right: 0,
                    width: 220,
                    height: 110,
                    child: CustomPaint(
                      painter: _SiteCardTopRightWavePainter(),
                    ),
                  ),
                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upper row: Icon, vertical accent bar, site info, chevron
                        Row(
                          children: [
                            // Unique verified building icon container
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                  width: 1.0,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x06000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.domain_verification_rounded,
                                  size: 22,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Site Name & Location
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.siteName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.zoneName} · ${item.clusterName}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: Color(0xFF475569),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Inner Activity Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Yellow vertical accent bar 2
                              Container(
                                width: 3.5,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.activityLabel.isNotEmpty
                                          ? item.activityLabel
                                          : 'Visit',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.frequencyLabel.isNotEmpty
                                          ? item.frequencyLabel
                                          : '—',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Completed pill badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${item.completed}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Pending pill badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: item.pending > 0
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${item.pending}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: item.pending > 0
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.checklist_rounded,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'No checklist items found',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _hasActiveFilters
                ? 'Try resetting your filters or adjusting your search'
                : 'Try adjusting your search query',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatusFilter = 'all';
                  _selectedZone = null;
                  _selectedCluster = null;
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Reset Filters',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openFilterBottomSheet(
      BuildContext context, ChecklistReportState state) {
    final allItems = state.summary?.items ?? [];
    final zones = allItems
        .map((e) => e.zoneName)
        .where((z) => z.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final clusters = allItems
        .map((e) => e.clusterName)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    String tempStatus = _selectedStatusFilter;
    String? tempZone = _selectedZone;
    String? tempCluster = _selectedCluster;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Checklist Reports',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempStatus = 'all';
                              tempZone = null;
                              tempCluster = null;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status Filter
                    Text(
                      'STATUS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFilterChip(
                          label: 'All',
                          isSelected: tempStatus == 'all',
                          onTap: () => setModalState(() => tempStatus = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Pending Only',
                          isSelected: tempStatus == 'pending',
                          onTap: () =>
                              setModalState(() => tempStatus = 'pending'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Completed Only',
                          isSelected: tempStatus == 'completed',
                          onTap: () =>
                              setModalState(() => tempStatus = 'completed'),
                        ),
                      ],
                    ),
                    if (zones.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'ZONE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(
                            label: 'All Zones',
                            isSelected: tempZone == null,
                            onTap: () => setModalState(() => tempZone = null),
                          ),
                          ...zones.map((z) => _buildFilterChip(
                                label: z,
                                isSelected: tempZone == z,
                                onTap: () => setModalState(() => tempZone = z),
                              )),
                        ],
                      ),
                    ],
                    if (clusters.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'CLUSTER',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(
                            label: 'All Clusters',
                            isSelected: tempCluster == null,
                            onTap: () =>
                                setModalState(() => tempCluster = null),
                          ),
                          ...clusters.map((c) => _buildFilterChip(
                                label: c,
                                isSelected: tempCluster == c,
                                onTap: () =>
                                    setModalState(() => tempCluster = c),
                              )),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedStatusFilter = tempStatus;
                            _selectedZone = tempZone;
                            _selectedCluster = tempCluster;
                          });
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  void _openDetail(ChecklistReportItemModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChecklistReportDetailPage(
          siteId: item.siteId,
          siteName: item.siteName,
          initialActivityId: item.id,
        ),
      ),
    );
  }
}

class _CardWavePainter extends CustomPainter {
  final Color waveColor;

  const _CardWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.15,
      size.width * 0.65,
      size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.95,
      size.width,
      size.height * 0.70,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CardWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}

class _SiteCardTopRightWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFDBEAFE).withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(size.width * 0.40, 0);
    path1.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.50,
      size.width,
      size.height * 0.28,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFBFDBFE).withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.62, 0);
    path2.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.68,
      size.width,
      size.height * 0.52,
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
