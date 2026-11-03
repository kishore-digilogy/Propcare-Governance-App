import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/meta_model.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';
import '../widgets/report_card_item.dart';
import 'report_viewer_page.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportsBloc(
        dataSource: ReportsRemoteDataSourceImpl(),
      )..add(const LoadReportCatalog()),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocConsumer<ReportsBloc, ReportsState>(
          listener: (context, state) {
            if (state is ReportsLoaded) {
              if (state.downloadError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.downloadError!,
                      style: GoogleFonts.outfit(),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else if (state.downloadedCsvContent != null) {
                final content = state.downloadedCsvContent!;
                final title = state.downloadedReportTitle ?? 'Report Export';
                context.read<ReportsBloc>().add(const DismissCsvPreview());
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportViewerPage(
                      title: title,
                      csvContent: content,
                    ),
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Header (Screenshot 1)
                _buildHeader(context, state),

                // Body content
                Expanded(
                  child: Builder(
                    builder: (ctx) {
                      if (state is ReportsLoading || state is ReportsInitial) {
                        return const Center(
                          child: CircularProgressIndicator(color: _kBlue),
                        );
                      }
                      if (state is ReportsError) {
                        return _buildErrorView(context, state.message);
                      }
                      if (state is ReportsLoaded) {
                        return _buildLoadedContent(context, state);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReportsState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 18, color: _kBlue),
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

              // Filter button in header (replaces Excel/CSV/PDF buttons)
              if (state is ReportsLoaded)
                _buildHeaderFilterButton(context, state, MetaService.instance.meta),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reports & Export',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Role-Wise View For All Roles In Your Site Scope — Counts Respect Your Site Scope And Filters.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: _kSlate,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  int _activeFiltersCount(ReportsLoaded state) {
    int count = 0;
    if (state.selectedDateRange != 'last_30') count++;
    if (state.selectedZoneId != null) count++;
    if (state.selectedClusterId != null) count++;
    if (state.selectedClientType != null) count++;
    if (state.selectedFunction != null) count++;
    if (state.selectedStatus != null) count++;
    return count;
  }

  Widget _buildHeaderFilterButton(
    BuildContext context,
    ReportsLoaded state,
    MetaDataModel meta,
  ) {
    final activeCount = _activeFiltersCount(state);

    return InkWell(
      onTap: () => _openFilterBottomSheet(context, state, meta),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activeCount > 0 ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activeCount > 0 ? _kBlue : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15,
              color: activeCount > 0 ? _kBlue : const Color(0xFF334155),
            ),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: activeCount > 0 ? _kBlue : const Color(0xFF334155),
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, ReportsLoaded state) {
    final catalog = state.catalog;
    final meta = MetaService.instance.meta;
    final activeCount = _activeFiltersCount(state);

    String dateRangeLabel;
    switch (state.selectedDateRange) {
      case 'last_7':
        dateRangeLabel = 'Last 7 Days';
        break;
      case 'last_90':
        dateRangeLabel = 'Last 90 Days';
        break;
      case 'this_month':
        dateRangeLabel = 'This Month';
        break;
      case 'all':
        dateRangeLabel = 'All Time';
        break;
      default:
        dateRangeLabel = 'Last 30 Days';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── Active Scope & Filter summary bar ─────────────────────────────
        InkWell(
          onTap: () => _openFilterBottomSheet(context, state, meta),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 16, color: _kBlue),
                const SizedBox(width: 8),
                Text(
                  '${catalog.scopeSites} Sites in Scope',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dateRangeLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kSlate,
                    ),
                  ),
                ),
                const Spacer(),
                if (activeCount > 0)
                  InkWell(
                    onTap: () {
                      context.read<ReportsBloc>().add(const ResetAllReportFilters());
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.tune_rounded, size: 15, color: _kSlate),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Reports List / Grid (Card spacing is compact & natural) ────────
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 720;
            if (!isWide) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: catalog.reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final r = catalog.reports[idx];
                  final isRunning = state.isRunningReport && state.runningExportKind == r.exportKind;

                  return ReportCardItem(
                    report: r,
                    isRunning: isRunning,
                    onRun: () {
                      context.read<ReportsBloc>().add(
                            RunReportCsv(
                              exportKind: r.exportKind,
                              reportTitle: r.title,
                            ),
                          );
                    },
                  );
                },
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemCount: catalog.reports.length,
              itemBuilder: (ctx, idx) {
                final r = catalog.reports[idx];
                final isRunning = state.isRunningReport && state.runningExportKind == r.exportKind;

                return ReportCardItem(
                  report: r,
                  isRunning: isRunning,
                  onRun: () {
                    context.read<ReportsBloc>().add(
                          RunReportCsv(
                            exportKind: r.exportKind,
                            reportTitle: r.title,
                          ),
                        );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _openFilterBottomSheet(
    BuildContext context,
    ReportsLoaded state,
    MetaDataModel meta,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<ReportsBloc>(),
          child: BlocBuilder<ReportsBloc, ReportsState>(
            builder: (bottomSheetContext, bottomSheetState) {
              if (bottomSheetState is! ReportsLoaded) return const SizedBox.shrink();
              final currentActiveCount = _activeFiltersCount(bottomSheetState);

              final dateRangeOptions = const <DropdownItemOption<String?>>[
                DropdownItemOption(value: 'last_7', label: 'Last 7 Days'),
                DropdownItemOption(value: 'last_30', label: 'Last 30 Days'),
                DropdownItemOption(value: 'last_90', label: 'Last 90 Days'),
                DropdownItemOption(value: 'this_month', label: 'This Month'),
                DropdownItemOption(value: 'all', label: 'All Time'),
              ];

              final zoneOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Zones'),
                ...meta.zones.map((z) => DropdownItemOption(value: z.id, label: z.name)),
              ];

              final groupClusterOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Groups'),
                ...meta.clusters
                    .where((c) => bottomSheetState.selectedZoneId == null || c.zoneId == bottomSheetState.selectedZoneId)
                    .map((c) => DropdownItemOption(value: c.parentId ?? c.id, label: c.name)),
              ];

              final clusterOptions = <DropdownItemOption<String?>>[
                const DropdownItemOption(value: null, label: 'All Clusters'),
                ...meta
                    .clustersForZone(bottomSheetState.selectedZoneId)
                    .map((c) => DropdownItemOption(value: c.id, label: c.name)),
              ];

              final clientTypeOptions = const <DropdownItemOption<String?>>[
                DropdownItemOption(value: null, label: 'All Types'),
                DropdownItemOption(value: 'A+', label: 'A+'),
                DropdownItemOption(value: 'A', label: 'A'),
                DropdownItemOption(value: 'B', label: 'B'),
                DropdownItemOption(value: 'C', label: 'C'),
              ];

              final functionOptions = const <DropdownItemOption<String?>>[
                DropdownItemOption(value: null, label: 'All Functions'),
                DropdownItemOption(value: 'OPERATIONS', label: 'Operations'),
                DropdownItemOption(value: 'TRANSITION', label: 'Transition / L&D'),
                DropdownItemOption(value: 'EHS', label: 'EHS'),
                DropdownItemOption(value: 'HR', label: 'HR'),
                DropdownItemOption(value: 'MACHINE_TECHNICIAN', label: 'Machine Technician'),
              ];

              final statusOptions = const <DropdownItemOption<String?>>[
                DropdownItemOption(value: null, label: 'All Statuses'),
                DropdownItemOption(value: 'LIVE', label: 'Live'),
                DropdownItemOption(value: 'PRE_TRANSITION', label: 'Pre-Transition'),
                DropdownItemOption(value: 'POST_TRANSITION', label: 'Post-Transition'),
                DropdownItemOption(value: 'READY', label: 'Ready'),
                DropdownItemOption(value: 'INACTIVE', label: 'Inactive'),
                DropdownItemOption(value: 'DRAFT', label: 'Draft'),
              ];

              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.viewInsetsOf(ctx).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 20, color: _kBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Report Filters',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (currentActiveCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  '$currentActiveCount active',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kBlue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            if (currentActiveCount > 0)
                              TextButton(
                                onPressed: () {
                                  bottomSheetContext.read<ReportsBloc>().add(const ResetAllReportFilters());
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: Text(
                                  'Reset',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: const Color(0xFF64748B),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Filter Fields (Scrollable)
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdownField<String?>(
                              label: 'Date Range',
                              selectedValue: bottomSheetState.selectedDateRange,
                              options: dateRangeOptions,
                              onSelect: (val) {
                                if (val != null) {
                                  bottomSheetContext.read<ReportsBloc>().add(ChangeDateRange(val));
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField<String?>(
                              label: 'Zone',
                              selectedValue: bottomSheetState.selectedZoneId,
                              options: zoneOptions,
                              onSelect: (id) {
                                bottomSheetContext.read<ReportsBloc>().add(ChangeZoneFilter(id));
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField<String?>(
                              label: 'Group Cluster',
                              selectedValue: null,
                              options: groupClusterOptions,
                              onSelect: (_) {},
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField<String?>(
                              label: 'Cluster',
                              selectedValue: bottomSheetState.selectedClusterId,
                              options: clusterOptions,
                              onSelect: (id) {
                                bottomSheetContext.read<ReportsBloc>().add(ChangeClusterFilter(id));
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField<String?>(
                              label: 'Client Type',
                              selectedValue: bottomSheetState.selectedClientType,
                              options: clientTypeOptions,
                              onSelect: (val) {
                                bottomSheetContext.read<ReportsBloc>().add(ChangeClientTypeFilter(val));
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField<String?>(
                              label: 'Function',
                              selectedValue: bottomSheetState.selectedFunction,
                              options: functionOptions,
                              onSelect: (val) {
                                bottomSheetContext.read<ReportsBloc>().add(ChangeFunctionFilter(val));
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField<String?>(
                              label: 'Status',
                              selectedValue: bottomSheetState.selectedStatus,
                              options: statusOptions,
                              onSelect: (val) {
                                bottomSheetContext.read<ReportsBloc>().add(ChangeStatusFilter(val));
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? selectedValue,
    required List<DropdownItemOption<T>> options,
    required ValueChanged<T?> onSelect,
    bool enableSearch = true,
  }) {
    return CustomDropdownButton2<T>(
      label: label,
      selectedValue: selectedValue,
      options: options,
      onSelect: onSelect,
      enableSearch: enableSearch,
      maxHeight: 260,
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              'Failed to load reports catalog',
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
                context.read<ReportsBloc>().add(const LoadReportCatalog());
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
