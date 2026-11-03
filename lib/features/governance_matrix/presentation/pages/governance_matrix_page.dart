import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/datasources/governance_matrix_remote_datasource.dart';
import '../../data/models/governance_matrix_model.dart';
import '../bloc/governance_matrix_bloc.dart';
import '../bloc/governance_matrix_event.dart';
import '../bloc/governance_matrix_state.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

class GovernanceMatrixPage extends StatelessWidget {
  const GovernanceMatrixPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GovernanceMatrixBloc(
        dataSource: GovernanceMatrixRemoteDataSourceImpl(),
      )..add(const LoadGovernanceMatrix()),
      child: const _GovernanceMatrixView(),
    );
  }
}

class _GovernanceMatrixView extends StatelessWidget {
  const _GovernanceMatrixView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildHeader(context),
            // Body Content
            Expanded(
              child: BlocBuilder<GovernanceMatrixBloc, GovernanceMatrixState>(
                builder: (context, state) {
                  if (state is GovernanceMatrixLoading ||
                      state is GovernanceMatrixInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kBlue),
                    );
                  }
                  if (state is GovernanceMatrixError) {
                    return _buildErrorView(context, state.message);
                  }
                  if (state is GovernanceMatrixLoaded) {
                    return _buildLoadedContent(context, state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: _kSlate),
                tooltip: 'Refresh',
                onPressed: () {
                  context.read<GovernanceMatrixBloc>().add(
                        const LoadGovernanceMatrix(isRefresh: true),
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Governance Matrix',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Client type × function × role × activity → frequency. Business users change this; developers never hard-code a frequency.',
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

  Widget _buildLoadedContent(
    BuildContext context,
    GovernanceMatrixLoaded state,
  ) {
    final tabs = state.data.uniqueTabs;
    final selectedKey = state.selectedTabKey;
    final items = state.data.getItemsForTab(selectedKey);
    final columns = state.data.getColumnsConfigForTab(selectedKey);

    final selectedTabName = tabs
        .firstWhere((t) => t.key == selectedKey, orElse: () => (key: selectedKey, name: selectedKey))
        .name;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── Tab Pills (Scrollable) ───────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tabs.map((tab) {
              final isSelected = tab.key == selectedKey;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    context.read<GovernanceMatrixBloc>().add(SelectTab(tab.key));
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? _kBlue : _kBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _kBlue.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      tab.name,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _kBlue : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // ── Section Title & Badge + View Mode Switcher ───────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '$selectedTabName frequency',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Final frequency sheet is the authority',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: _kSlate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Toggle Cards vs Table
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ViewModeButton(
                    icon: Icons.view_agenda_rounded,
                    tooltip: 'Card view',
                    isActive: state.isCardView,
                    onTap: () {
                      context.read<GovernanceMatrixBloc>().add(
                            const ToggleViewMode(true),
                          );
                    },
                  ),
                  _ViewModeButton(
                    icon: Icons.table_chart_rounded,
                    tooltip: 'Table view',
                    isActive: !state.isCardView,
                    onTap: () {
                      context.read<GovernanceMatrixBloc>().add(
                            const ToggleViewMode(false),
                          );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Card View or Table View ──────────────────────────────────────────
        if (state.isCardView) ...[
          // Card design (User requested: "no need for edoit icon.. give in card deisgn..")
          ...items.map((item) {
            return _MatrixCardItem(
              item: item,
              columnsConfig: columns,
              isOperations: selectedKey == 'operations',
            );
          }),
        ] else ...[
          // Table design matching web screenshot (no edit icon)
          _MatrixTableView(
            items: items,
            columnsConfig: columns,
          ),
        ],
      ],
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
              'Failed to load matrix',
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
                context.read<GovernanceMatrixBloc>().add(
                      const LoadGovernanceMatrix(),
                    );
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

// ─────────────────────────────────────────────────────────────────────────────
// Card Design (Requested: "give in card deisgn.. no need for edoit icon..")
// ─────────────────────────────────────────────────────────────────────────────

class _MatrixCardItem extends StatelessWidget {
  final GovernanceMatrixItemModel item;
  final List<GovernanceColumnConfig> columnsConfig;
  final bool isOperations;

  const _MatrixCardItem({
    required this.item,
    required this.columnsConfig,
    required this.isOperations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header: Client Type Badge & Billing PM ────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _ClientTypeBadge(clientType: item.clientType),
                  const SizedBox(width: 8),
                  Text(
                    'Client Tier ${item.clientType}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  item.billingPm,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 12),

          // ── Card Body: Single Frequency or Multi-Role Grid ─────────────────
          if (!isOperations) ...[
            // Single Frequency Tab (L&D, EHS, HR, Machine, CRRM)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_repeat_rounded,
                      size: 20,
                      color: _kBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FREQUENCY',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _kSlate,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.frequencies['frequency'] ?? '—',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Operations: 10 roles frequency grid
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isCompact = constraints.maxWidth < 450;
                final crossAxisCount = isCompact ? 2 : 3;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isCompact ? 2.1 : 2.5,
                  ),
                  itemCount: columnsConfig.length,
                  itemBuilder: (ctx, idx) {
                    final col = columnsConfig[idx];
                    final freq = item.frequencies[col.key] ?? 'Nil';
                    final isMuted = freq.toLowerCase() == 'nil' ||
                        freq.toLowerCase() == 'n/a';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMuted
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMuted
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFDBEAFE),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            col.label,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _kSlate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            freq,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isMuted
                                  ? const Color(0xFF94A3B8)
                                  : (freq.toLowerCase().contains('weekly') ||
                                          freq.toLowerCase().contains('15 days')
                                      ? _kBlue
                                      : const Color(0xFF0F172A)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table View (Matching web screenshot, without edit icon, full-width flexible)
// ─────────────────────────────────────────────────────────────────────────────

class _MatrixTableView extends StatelessWidget {
  final List<GovernanceMatrixItemModel> items;
  final List<GovernanceColumnConfig> columnsConfig;

  const _MatrixTableView({
    required this.items,
    required this.columnsConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // For tabs with 1 or 2 frequency columns (L&D, EHS, HR, Machine, CRRM),
            // use a flexible edge-to-edge layout so columns span the entire card width
            if (columnsConfig.length <= 2) {
              final minW = constraints.maxWidth < 440 ? 440.0 : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Heading Row
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Client type',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Billing PM',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                columnsConfig.isNotEmpty
                                    ? columnsConfig.first.label
                                    : 'Frequency',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _kBorder),

                      // Data Rows
                      for (int i = 0; i < items.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _ClientTypeBadge(
                                    clientType: items[i].clientType,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  items[i].billingPm,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  columnsConfig.isNotEmpty
                                      ? (items[i].frequencies[columnsConfig.first.key] ?? '—')
                                      : (items[i].frequencies['frequency'] ?? '—'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
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
              );
            }

            // For Operations (10+ roles), use horizontally scrollable DataTable
            // with minWidth constraint to fill at least the card width
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dataRowColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.hovered)
                        ? const Color(0xFFF8FAFC)
                        : Colors.white,
                  ),
                  columnSpacing: 28,
                  horizontalMargin: 16,
                  headingTextStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                  dataTextStyle: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: const Color(0xFF0F172A),
                  ),
                  columns: [
                    const DataColumn(label: Text('Client type')),
                    const DataColumn(label: Text('Billing PM')),
                    ...columnsConfig.map((c) => DataColumn(label: Text(c.label))),
                  ],
                  rows: items.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(_ClientTypeBadge(clientType: item.clientType)),
                        DataCell(
                          Text(
                            item.billingPm,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        ...columnsConfig.map((c) {
                          final val = item.frequencies[c.key] ?? '—';
                          final isNil = val.toLowerCase() == 'nil' ||
                              val.toLowerCase() == 'n/a';
                          return DataCell(
                            Text(
                              val,
                              style: GoogleFonts.outfit(
                                fontWeight:
                                    isNil ? FontWeight.w400 : FontWeight.w600,
                                color: isNil
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client Type Badge Component (A+, A, B, C)
// ─────────────────────────────────────────────────────────────────────────────

class _ClientTypeBadge extends StatelessWidget {
  final String clientType;

  const _ClientTypeBadge({required this.clientType});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (clientType.toUpperCase()) {
      case 'A+':
        bg = const Color(0xFFF3E8FF);
        border = const Color(0xFFE9D5FF);
        text = const Color(0xFF7E22CE);
        break;
      case 'A':
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFDBEAFE);
        text = const Color(0xFF1D4ED8);
        break;
      case 'B':
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFB45309);
        break;
      case 'C':
      default:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFE2E8F0);
        text = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        clientType,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View Mode Switcher Button
// ─────────────────────────────────────────────────────────────────────────────

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? _kBlue : _kSlate,
          ),
        ),
      ),
    );
  }
}

