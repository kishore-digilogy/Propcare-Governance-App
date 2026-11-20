import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../data/datasources/governance_matrix_remote_datasource.dart';
import '../../data/models/governance_matrix_model.dart';
import '../bloc/governance_matrix_bloc.dart';
import '../bloc/governance_matrix_event.dart';
import '../bloc/governance_matrix_state.dart';

const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

class GovernanceMatrixPage extends StatefulWidget {
  final GovernanceMatrixBloc? bloc;

  const GovernanceMatrixPage({super.key, this.bloc});

  @override
  State<GovernanceMatrixPage> createState() => _GovernanceMatrixPageState();
}

class _GovernanceMatrixPageState extends State<GovernanceMatrixPage> {
  late final GovernanceMatrixBloc _bloc;
  bool _ownsBloc = false;

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      _ownsBloc = true;
      _bloc = GovernanceMatrixBloc(
        dataSource: GovernanceMatrixRemoteDataSourceImpl(),
      );
    }
    _bloc.add(const LoadGovernanceMatrix());
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: const _GovernanceMatrixView(),
    );
  }
}

class _GovernanceMatrixView extends StatefulWidget {
  const _GovernanceMatrixView();

  @override
  State<_GovernanceMatrixView> createState() => _GovernanceMatrixViewState();
}

class _GovernanceMatrixViewState extends State<_GovernanceMatrixView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _chipsFadeAnimation;
  late final Animation<Offset> _chipsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _headerFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(_headerFadeAnimation);

    _chipsFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.18, 0.70, curve: Curves.easeOutCubic),
    );

    _chipsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(_chipsFadeAnimation);

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 650;

    return BlocBuilder<GovernanceMatrixBloc, GovernanceMatrixState>(
      builder: (context, state) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Column(
              children: [
                // 1. Light Top Header + 3D Illustration + Floating Overlapping Chips
                _buildHeaderWithOverlappingChips(context, state, isTablet),

                // 2. Light Body Content
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is GovernanceMatrixLoading ||
                          state is GovernanceMatrixInitial) {
                        return const ShimmerMatrixLoading();
                      }
                      if (state is GovernanceMatrixError) {
                        return _buildErrorView(context, state.message, isTablet);
                      }
                      if (state is GovernanceMatrixLoaded) {
                        return _buildLoadedContent(context, state, isTablet);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderWithOverlappingChips(
    BuildContext context,
    GovernanceMatrixState state,
    bool isTablet,
  ) {
    const chipHeight = 44.0;
    const halfChip = chipHeight / 2; // 22.0

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // 1. Light Header Container (ends directly at the vertical center of the chips)
        SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: halfChip),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF2FE),
                    Color(0xFFF3F7FD),
                    Colors.white,
                  ],
                ),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Decorative organic circular shapes in background
                    Positioned(
                      top: -30,
                      right: -30,
                      width: 150,
                      height: 150,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFDBEAFE).withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -15,
                      right: 80,
                      width: 85,
                      height: 85,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEFF6FF).withValues(alpha: 0.55),
                        ),
                      ),
                    ),

                    // Header Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 28 : 16,
                        12,
                        isTablet ? 28 : 16,
                        halfChip + 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Back & Refresh Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back Button
                              InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x06000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 13,
                                        color: Color(0xFF1A73E8),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Back',
                                        style: GoogleFonts.outfit(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A73E8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Refresh Button
                              InkWell(
                                onTap: () {
                                  context.read<GovernanceMatrixBloc>().add(
                                        const LoadGovernanceMatrix(
                                          isRefresh: true,
                                        ),
                                      );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x06000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    size: 17,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Title & Illustration Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title: Governance (navy) + Matrix (amber)
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Governance ',
                                            style: GoogleFonts.outfit(
                                              fontSize: isTablet ? 27 : 22,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0F172A),
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Matrix',
                                            style: GoogleFonts.outfit(
                                              fontSize: isTablet ? 27 : 22,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFF59E0B),
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // Horizontal yellow accent bar below title
                                    Container(
                                      width: 44,
                                      height: 3.5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Subtitle
                                    Text(
                                      'Client type × function × role × activity → frequency. Business users change this; developers never hard-code a frequency.',
                                      style: GoogleFonts.outfit(
                                        fontSize: isTablet ? 13 : 11.5,
                                        color: const Color(0xFF64748B),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 3D Clipboard Illustration
                              Image.asset(
                                AppAssets.governanceClipboard,
                                height: isTablet ? 112 : 92,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. Floating Chips Row: centered across the bottom edge of the container
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _chipsSlideAnimation,
            child: FadeTransition(
              opacity: _chipsFadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 16),
                child: _buildChipsRow(context, state, isTablet),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipsRow(
    BuildContext context,
    GovernanceMatrixState state,
    bool isTablet,
  ) {
    if (state is GovernanceMatrixLoaded) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: state.data.uniqueTabs.map((tab) {
            final isSelected = tab.key == state.selectedTabKey;
            return _buildTabPill(
              context: context,
              tab: tab,
              isSelected: isSelected,
              isTablet: isTablet,
            );
          }).toList(),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildPlaceholderTabPill('Operations', true, isTablet),
          _buildPlaceholderTabPill('L & D', false, isTablet),
          _buildPlaceholderTabPill('EHS Audit', false, isTablet),
          _buildPlaceholderTabPill('HR & Compliance', false, isTablet),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required BuildContext context,
    required ({String key, String name}) tab,
    required bool isSelected,
    required bool isTablet,
  }) {
    final icon = _getTabIcon(tab.key, tab.name);
    return Padding(
      padding: EdgeInsets.only(right: isTablet ? 10 : 8),
      child: InkWell(
        onTap: () {
          context.read<GovernanceMatrixBloc>().add(SelectTab(tab.key));
        },
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 15,
            vertical: isTablet ? 10 : 8.5,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isSelected ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isTablet ? 18 : 16.5,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                tab.name,
                style: GoogleFonts.outfit(
                  fontSize: isTablet ? 13.5 : 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTabPill(String name, bool isSelected, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(right: isTablet ? 10 : 8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 15,
          vertical: isTablet ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.8)
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: isTablet ? 13.5 : 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _getTabIcon(String key, String name) {
    final k = key.toLowerCase();
    final n = name.toLowerCase();
    if (k.contains('operation') || n.contains('operation')) {
      return Icons.settings_outlined;
    }
    if (k.contains('ld') ||
        k.contains('train') ||
        n.contains('l & d') ||
        n.contains('training')) {
      return Icons.school_outlined;
    }
    if (k.contains('ehs') ||
        k.contains('audit') ||
        n.contains('ehs') ||
        n.contains('audit')) {
      return Icons.verified_user_outlined;
    }
    if (k.contains('hr') ||
        k.contains('compliance') ||
        n.contains('hr') ||
        n.contains('compliance')) {
      return Icons.groups_outlined;
    }
    if (k.contains('machine') ||
        k.contains('tech') ||
        n.contains('machine') ||
        n.contains('technician')) {
      return Icons.handyman_outlined;
    }
    if (k.contains('crrm') || n.contains('crrm')) {
      return Icons.business_center_outlined;
    }
    return Icons.grid_view_outlined;
  }

  Widget _buildLoadedContent(
    BuildContext context,
    GovernanceMatrixLoaded state,
    bool isTablet,
  ) {
    final tabs = state.data.uniqueTabs;
    final selectedKey = state.selectedTabKey;
    final items = state.data.getItemsForTab(selectedKey);
    final columns = state.data.getColumnsConfigForTab(selectedKey);

    final selectedTabName = tabs
        .firstWhere(
          (t) => t.key == selectedKey,
          orElse: () => (key: selectedKey, name: selectedKey),
        )
        .name;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isTablet ? 28 : 16,
        18,
        isTablet ? 28 : 16,
        36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Title & Badge + View Mode Switcher ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      width: 4,
                      height: isTablet ? 20 : 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      '$selectedTabName frequency',
                      style: GoogleFonts.outfit(
                        fontSize: isTablet ? 17 : 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Final frequency sheet is the authority',
                        style: GoogleFonts.outfit(
                          fontSize: isTablet ? 11.5 : 10.5,
                          fontWeight: FontWeight.w500,
                          color: _kSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // View Mode Switcher (Matching screenshot with amber active button)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewModeButton(
                      icon: Icons.grid_view_rounded,
                      tooltip: 'Card view',
                      isActive: state.isCardView,
                      onTap: () {
                        context.read<GovernanceMatrixBloc>().add(
                              const ToggleViewMode(true),
                            );
                      },
                    ),
                    const SizedBox(width: 2),
                    _ViewModeButton(
                      icon: Icons.reorder_rounded,
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
          const SizedBox(height: 16),

          // ── Card View or Table View ────────────────────────────────────────
          if (state.isCardView) ...[
            if (items.isEmpty)
              _buildEmptyState(selectedTabName, isTablet)
            else if (!isTablet) ...[
              // Mobile: 1 column
              for (final item in items)
                _MatrixCardItem(
                  item: item,
                  columnsConfig: columns,
                  isOperations: selectedKey == 'operations',
                  isTablet: false,
                ),
            ] else ...[
              // Tablet / iPad: 2-column masonry grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 0; i < items.length; i += 2)
                          _MatrixCardItem(
                            item: items[i],
                            columnsConfig: columns,
                            isOperations: selectedKey == 'operations',
                            isTablet: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 1; i < items.length; i += 2)
                          _MatrixCardItem(
                            item: items[i],
                            columnsConfig: columns,
                            isOperations: selectedKey == 'operations',
                            isTablet: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            // Table view
            if (items.isEmpty)
              _buildEmptyState(selectedTabName, isTablet)
            else
              _MatrixTableView(
                items: items,
                columnsConfig: columns,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String tabName, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 48 : 36,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: isTablet ? 48 : 40,
            color: _kSlate.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No records found for $tabName',
            style: GoogleFonts.outfit(
              fontSize: isTablet ? 15 : 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 36 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load matrix',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
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
                backgroundColor: const Color(0xFFF59E0B),
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
// Card Design (Image 1 Style: Tier Header Banner & Role Items with Icons/Waves)
// ─────────────────────────────────────────────────────────────────────────────

class _TierTheme {
  final List<Color> bannerGradient;
  final Color badgeBg;
  final Color badgeText;
  final Color pillBg;
  final Color pillText;
  final Color cardBorder;

  const _TierTheme({
    required this.bannerGradient,
    required this.badgeBg,
    required this.badgeText,
    required this.pillBg,
    required this.pillText,
    required this.cardBorder,
  });

  static _TierTheme forType(String type) {
    switch (type.toUpperCase().trim()) {
      case 'A+':
        return const _TierTheme(
          bannerGradient: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          badgeBg: Color(0xFF7E22CE),
          badgeText: Colors.white,
          pillBg: Color(0xFFEDE9FE),
          pillText: Color(0xFF6D28D9),
          cardBorder: Color(0xFFE9D5FF),
        );
      case 'A':
        return const _TierTheme(
          bannerGradient: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          badgeBg: Color(0xFF2563EB),
          badgeText: Colors.white,
          pillBg: Color(0xFFDBEAFE),
          pillText: Color(0xFF1D4ED8),
          cardBorder: Color(0xFFBFDBFE),
        );
      case 'B':
        return const _TierTheme(
          bannerGradient: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          badgeBg: Color(0xFFD97706),
          badgeText: Colors.white,
          pillBg: Color(0xFFFEF3C7),
          pillText: Color(0xFFB45309),
          cardBorder: Color(0xFFFDE68A),
        );
      case 'C':
      default:
        return const _TierTheme(
          bannerGradient: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          badgeBg: Color(0xFF475569),
          badgeText: Colors.white,
          pillBg: Color(0xFFE2E8F0),
          pillText: Color(0xFF334155),
          cardBorder: Color(0xFFE2E8F0),
        );
    }
  }
}

class _RoleTheme {
  final Color iconBg;
  final Color iconBorder;
  final Color iconColor;
  final Color pillBg;
  final Color pillText;
  final Color dotColor;

  const _RoleTheme({
    required this.iconBg,
    required this.iconBorder,
    required this.iconColor,
    required this.pillBg,
    required this.pillText,
    required this.dotColor,
  });

  static _RoleTheme forRole(String key, String label) {
    final k = key.toLowerCase();
    final l = label.toLowerCase();

    // 1. Leadership (COO, Zonal Head, Group Cluster Head)
    if (k.contains('coo') ||
        l.contains('coo') ||
        k.contains('zonal') ||
        l.contains('zonal') ||
        k.contains('group') ||
        l.contains('group')) {
      return const _RoleTheme(
        iconBg: Color(0xFFFAF5FF),
        iconBorder: Color(0xFFE9D5FF),
        iconColor: Color(0xFF7C3AED),
        pillBg: Color(0xFFF5F3FF),
        pillText: Color(0xFF6D28D9),
        dotColor: Color(0xFF8B5CF6),
      );
    }

    // 2. Cluster Level (Cluster Head, Cluster Lead, Cluster Executive)
    if (k.contains('cluster') || l.contains('cluster')) {
      return const _RoleTheme(
        iconBg: Color(0xFFEFF6FF),
        iconBorder: Color(0xFFBFDBFE),
        iconColor: Color(0xFF2563EB),
        pillBg: Color(0xFFF0F9FF),
        pillText: Color(0xFF1D4ED8),
        dotColor: Color(0xFF3B82F6),
      );
    }

    // 3. Field / Operations Frontline (Field Executive)
    if (k.contains('field') || l.contains('field')) {
      return const _RoleTheme(
        iconBg: Color(0xFFECFDF5),
        iconBorder: Color(0xFFA7F3D0),
        iconColor: Color(0xFF059669),
        pillBg: Color(0xFFF0FDF4),
        pillText: Color(0xFF047857),
        dotColor: Color(0xFF10B981),
      );
    }

    // 4. Governance & Reporting (MMR, MIS)
    if (k.contains('mmr') ||
        l.contains('mmr') ||
        k.contains('mis') ||
        l.contains('mis')) {
      return const _RoleTheme(
        iconBg: Color(0xFFFFFBEB),
        iconBorder: Color(0xFFFDE68A),
        iconColor: Color(0xFFD97706),
        pillBg: Color(0xFFFEF3C7),
        pillText: Color(0xFFB45309),
        dotColor: Color(0xFFF59E0B),
      );
    }

    // 5. Rewards / Recognition / Default (R&R)
    if (k.contains('rr') || l.contains('r&r') || k.contains('reward')) {
      return const _RoleTheme(
        iconBg: Color(0xFFFFF1F2),
        iconBorder: Color(0xFFFECDD3),
        iconColor: Color(0xFFE11D48),
        pillBg: Color(0xFFFFF1F2),
        pillText: Color(0xFFBE123C),
        dotColor: Color(0xFFF43F5E),
      );
    }

    return const _RoleTheme(
      iconBg: Color(0xFFF8FAFC),
      iconBorder: Color(0xFFE2E8F0),
      iconColor: Color(0xFF475569),
      pillBg: Color(0xFFF1F5F9),
      pillText: Color(0xFF334155),
      dotColor: Color(0xFF64748B),
    );
  }
}

class _MatrixCardItem extends StatelessWidget {
  final GovernanceMatrixItemModel item;
  final List<GovernanceColumnConfig> columnsConfig;
  final bool isOperations;
  final bool isTablet;

  const _MatrixCardItem({
    required this.item,
    required this.columnsConfig,
    required this.isOperations,
    this.isTablet = false,
  });

  static IconData _getRoleIcon(String key, String label) {
    final k = key.toLowerCase();
    final l = label.toLowerCase();
    if (k.contains('field') || l.contains('field')) {
      return Icons.business_center_outlined;
    }
    if (k.contains('clusterexecutive') ||
        (k.contains('cluster') && k.contains('exec')) ||
        l.contains('cluster executive')) {
      return Icons.layers_outlined;
    }
    if (k.contains('clusterlead') || l.contains('cluster lead')) {
      return Icons.supervisor_account_outlined;
    }
    if (k.contains('clusterhead') || l.contains('cluster head')) {
      return Icons.military_tech_outlined;
    }
    if (k.contains('group') || l.contains('group')) {
      return Icons.corporate_fare_outlined;
    }
    if (k.contains('zonal') || l.contains('zonal')) {
      return Icons.location_city_outlined;
    }
    if (k.contains('coo') || l.contains('coo')) {
      return Icons.trending_up_rounded;
    }
    if (k.contains('mmr') || l.contains('mmr')) {
      return Icons.assignment_outlined;
    }
    if (k.contains('mis') || l.contains('mis')) {
      return Icons.insights_outlined;
    }
    if (k.contains('rr') || l.contains('r&r')) {
      return Icons.emoji_events_outlined;
    }
    return Icons.work_outline_rounded;
  }

  Widget _buildRoleContainer({
    required GovernanceColumnConfig col,
    required String freq,
  }) {
    final isMuted = freq.toLowerCase() == 'nil' || freq.toLowerCase() == 'n/a';
    final icon = _getRoleIcon(col.key, col.label);
    final roleTheme = _RoleTheme.forRole(col.key, col.label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isMuted
              ? const Color(0xFFF1F5F9)
              : roleTheme.iconBorder.withValues(alpha: 0.65),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Distinct Category-Colored Icon Container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isMuted ? const Color(0xFFF8FAFC) : roleTheme.iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMuted ? const Color(0xFFE2E8F0) : roleTheme.iconBorder,
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isMuted ? const Color(0xFF94A3B8) : roleTheme.iconColor,
            ),
          ),
          const SizedBox(width: 8),
          // Role Title & Frequency Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  col.label,
                  style: GoogleFonts.outfit(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7.5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isMuted ? const Color(0xFFF1F5F9) : roleTheme.pillBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isMuted
                          ? const Color(0xFFE2E8F0)
                          : roleTheme.iconBorder.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMuted) ...[
                        Container(
                          width: 4.5,
                          height: 4.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: roleTheme.dotColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          freq,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: isMuted
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: isMuted
                                ? const Color(0xFF94A3B8)
                                : roleTheme.pillText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildSingleFrequencyContainer({required String freq}) {
    final isMuted = freq.toLowerCase() == 'nil' || freq.toLowerCase() == 'n/a';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Icon(
              Icons.event_repeat_rounded,
              size: 22,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FREQUENCY',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _kSlate,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: isMuted
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMuted
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFFDE68A),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    freq,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight:
                          isMuted ? FontWeight.w500 : FontWeight.w700,
                      color: isMuted
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _TierTheme.forType(item.clientType);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.cardBorder.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 14 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header Banner with Tier Gradient ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.bannerGradient,
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: theme.cardBorder.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Solid oval badge (e.g. Purple with white "A+")
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.badgeBg.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Text(
                          item.clientType,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: theme.badgeText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          'Client Tier ${item.clientType}',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Billing PM pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.pillBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.cardBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    item.billingPm,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: theme.pillText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Card Body: Single Frequency or Multi-Role Grid ─────────────────
          if (!isOperations) ...[
            _buildSingleFrequencyContainer(
              freq: item.frequencies['frequency'] ?? '—',
            ),
          ] else ...[
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
                    childAspectRatio: isCompact ? 2.15 : 2.5,
                  ),
                  itemCount: columnsConfig.length,
                  itemBuilder: (ctx, idx) {
                    final col = columnsConfig[idx];
                    final freq = item.frequencies[col.key] ?? 'Nil';
                    return _buildRoleContainer(col: col, freq: freq);
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
// Table View (Full-width flexible)
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
                                      ? (items[i].frequencies[
                                              columnsConfig.first.key] ??
                                          '—')
                                      : (items[i].frequencies['frequency'] ??
                                          '—'),
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
    final theme = _TierTheme.forType(clientType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: theme.badgeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        clientType,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: theme.badgeText,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View Mode Switcher Button (Amber active pill, clean rounded styling)
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
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF59E0B) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
