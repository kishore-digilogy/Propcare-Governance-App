import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_avatar.dart';
import '../../../activities/presentation/pages/activity_execution_page.dart';
import '../../../activities/presentation/pages/checklist_report_page.dart';
import '../../../activities/presentation/pages/mmr_mis_page.dart';
import '../../../activities/presentation/pages/rr_page.dart';
import '../../../governance_matrix/presentation/pages/governance_matrix_page.dart';
import '../../../issues/presentation/pages/issues_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../sites/presentation/pages/all_sites_page.dart';
import '../../../sites/presentation/pages/transition_sites_page.dart';
import '../../../sites/presentation/pages/transition_site_detail_page.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/dashboard_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import 'placeholder_page_view.dart';

// ─── colour helpers ───────────────────────────────────────────────────────────
const _kBlue = Color(0xFF1A73E8);
const _kGreen = Color(0xFF22C55E);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE8EDF2);
const _kBg = Colors.white;

// ─────────────────────────────────────────────────────────────────────────────
// Entry widget
// ─────────────────────────────────────────────────────────────────────────────

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @visibleForTesting
  static Widget testableStatGrid({required DashboardModel data}) =>
      _StatGrid(data: data);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardBloc(dataSource: DashboardRemoteDataSourceImpl())
            ..add(const LoadDashboard()),
      child: const _DashboardView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scaffold (No AppBar - Custom Left-Aligned Header)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final initials = _initials(
      HiveStorage.userName ?? 'PropCare Administrator',
    );

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _CustomHeader(initials: initials),
            Expanded(
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading || state is DashboardInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kBlue),
                    );
                  }
                  if (state is DashboardError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<DashboardBloc>().add(
                        const LoadDashboard(),
                      ),
                    );
                  }
                  if (state is DashboardLoaded) {
                    return _Body(data: state.data);
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name.substring(0, math.min(2, name.length)).toUpperCase();
    }
    return 'PA';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Header (Logo at Left + Notification Bell + Profile Pill with Dropdown)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomHeader extends StatelessWidget {
  final String initials;

  const _CustomHeader({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Logo strictly aligned at left
          Image.asset(
            'assets/icons/gov_icon.png',
            height: 38,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          // Bell with red notification badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: _kSlate,
                  size: 24,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '3',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          // Profile Pill with Popup Menu
          _ProfileDropdownPill(initials: initials),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Dropdown Pill with "View Profile" & "Log Out" Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileDropdownPill extends StatelessWidget {
  final String initials;

  const _ProfileDropdownPill({required this.initials});

  @override
  Widget build(BuildContext context) {
    final userName = HiveStorage.userName ?? 'PropCare Administrator';
    final userEmail = HiveStorage.userEmail ?? 'admin@casagrandepropcare.com';
    final userRole = HiveStorage.displayRole;

    return PopupMenuButton<String>(
      tooltip: 'Account Menu',
      offset: const Offset(0, 48),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      onSelected: (value) {
        if (value == 'profile') {
          _showProfileBottomSheet(
            context,
            userName,
            userEmail,
            userRole,
            initials,
          );
        } else if (value == 'logout') {
          _showLogoutDialog(context);
        }
      },
      itemBuilder: (context) => [
        // Header account info tile
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _kBlue.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: GoogleFonts.outfit(
                    color: _kBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      userEmail,
                      style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Clean subtle separator
        const PopupMenuItem<String>(
          enabled: false,
          height: 1,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ),
        // View Profile option
        PopupMenuItem<String>(
          value: 'profile',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _kBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'View Profile',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        // Log Out option
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Log Out',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: _kBlue,
              child: Text(
                initials,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _kSlate,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileBottomSheet(
    BuildContext context,
    String name,
    String email,
    String role,
    String initials,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _kBlue.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      color: _kBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    (role.toUpperCase() == 'CRRM' ||
                            role.toUpperCase().contains('ADMIN'))
                        ? 'CRRM / Super Admin'
                        : role,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                // Details rows
                _ProfileInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: email,
                ),
                _ProfileInfoTile(
                  icon: Icons.shield_outlined,
                  label: 'Account Role',
                  value:
                      (role.toUpperCase() == 'CRRM' ||
                          role.toUpperCase().contains('ADMIN'))
                      ? 'CRRM / Super Admin'
                      : role,
                ),
                _ProfileInfoTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Account Status',
                  value: 'Active',
                  valueColor: _kGreen,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
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
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Log Out',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out of PropCare Governance? You will need your credentials to log back in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _kSlate,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kSlate,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await HiveStorage.clearAuth();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Yes, Log Out',
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
            ],
          ),
        );
      },
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _kSlate),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scrollable body
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatefulWidget {
  final DashboardModel data;
  const _Body({required this.data});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final PageController _pageController;
  int _activeToggle = 0; // 0: Governance Overview, 1: Quick Actions
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);
  static const double _maxHeroOffset = 136.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final clamped = notification.metrics.pixels.clamp(0.0, _maxHeroOffset);
      if (_scrollOffset.value != clamped) {
        _scrollOffset.value = clamped;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final userName = data.workspace.viewer.name.isNotEmpty
        ? data.workspace.viewer.name
        : (HiveStorage.userName ?? 'PropCare Administrator');

    return Column(
      children: [
        // Hero Banner moves above naturally as you scroll down
        ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (context, offset, child) {
            final visibleHeight = math.max(0.0, _maxHeroOffset - offset);
            if (visibleHeight <= 0.5) {
              return const SizedBox.shrink();
            }
            return IgnorePointer(
              ignoring: visibleHeight < 15.0,
              child: ClipRect(
                child: SizedBox(
                  height: visibleHeight,
                  child: OverflowBox(
                    minHeight: _maxHeroOffset,
                    maxHeight: _maxHeroOffset,
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: Offset(0, -offset),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: _HeroBanner(userName: userName),
          ),
        ),

        // Toggle Bar (Capsule design matching new Dashboard layout)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: _DashboardToggleBar(
            selectedIndex: _activeToggle,
            onSelect: (idx) {
              setState(() => _activeToggle = idx);
              _pageController.animateToPage(
                idx,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
              );
            },
          ),
        ),

        // PageView: Page 0 = Governance Overview, Page 1 = Quick Actions
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (idx) {
                setState(() => _activeToggle = idx);
              },
              children: [
                // Page 0: Governance Overview
                _buildGovernanceOverviewPage(data),

                // Page 1: Quick Actions
                _buildQuickActionsPage(data),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGovernanceOverviewPage(DashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return RefreshIndicator(
          color: _kBlue,
          onRefresh: () async =>
              context.read<DashboardBloc>().add(const LoadDashboard()),
          child: ListView(
            key: const PageStorageKey('governance_overview_page'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              // ── 6 stat cards (2-col grid)
              _StatGrid(data: data),
              const SizedBox(height: 14),

              // ── Unique & attractive divider
              const _DueSitesDivider(),
              const SizedBox(height: 14),

              // ── Due sites bar (Calendar icon + 30d/60d/90d dot stats)
              _DueSitesBar(renewals: data.renewals),
              const SizedBox(height: 14),

              // ── Adaptive Analytics Section (2-Col on Tablet / 1-Col on Mobile)
              if (isWide) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SitesByZoneCard(
                        geography: data.geography,
                        zones: data.workspace.zones,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: _GovernanceCard(overview: data.overview)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ZonesCard(zones: data.workspace.zones)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ClustersCard(clusters: data.workspace.clusters),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ] else ...[
                // ── Sites By Zone (Teal Progress Bars & View All)
                _SitesByZoneCard(
                  geography: data.geography,
                  zones: data.workspace.zones,
                ),
                const SizedBox(height: 14),

                // ── Governance Overview (Donut + Legend + Clipboard Illustration)
                _GovernanceCard(overview: data.overview),
                const SizedBox(height: 14),

                // ── Zones table
                _ZonesCard(zones: data.workspace.zones),
                const SizedBox(height: 14),

                // ── Clusters table
                _ClustersCard(clusters: data.workspace.clusters),
                const SizedBox(height: 14),
              ],

              // ── Recent Governance
              _RecentGovernanceCard(items: data.overview.governanceList),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsPage(DashboardModel data) {
    return RefreshIndicator(
      color: _kBlue,
      onRefresh: () async =>
          context.read<DashboardBloc>().add(const LoadDashboard()),
      child: ListView(
        key: const PageStorageKey('quick_actions_page'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [_QuickActionsGridView()],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Greeting Banner (with Light Blue Buildings & Clouds Illustration - Image 1)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String userName;

  const _HeroBanner({required this.userName});

  @override
  Widget build(BuildContext context) {
    // Dynamic greeting based on time of day
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour >= 4 && hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon,';
    } else {
      greeting = 'Good Evening,';
    }

    // Resolve actual user name
    String displayName = '';
    if (HiveStorage.userName != null &&
        HiveStorage.userName!.trim().isNotEmpty) {
      displayName = HiveStorage.userName!.trim();
    } else if (userName.trim().isNotEmpty) {
      displayName = userName.trim();
    } else {
      displayName = 'PropCare Admin';
    }

    if (displayName.toLowerCase().contains('administrator')) {
      displayName = 'PropCare Admin';
    }

    final formattedName = displayName.endsWith('!')
        ? displayName
        : '$displayName!';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFCFF), Color(0xFFEEF5FE)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Right illustration seamlessly positioned
            Positioned(
              right: -4,
              bottom: 0,
              top: 0,
              child: Image.asset(
                AppAssets.dashboardHeroBuildings,
                width: 170,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
            // Left text content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 160, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          formattedName,
                          style: GoogleFonts.outfit(
                            fontSize: formattedName.length > 16 ? 19 : 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('👋', style: TextStyle(fontSize: 19)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor and manage governance across all modules.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Toggle Bar (Capsule Pill Segmented Design from Image 2)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardToggleBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _DashboardToggleBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light grey capsule background
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Governance Overview Tab
          Expanded(
            child: _ToggleTabItem(
              title: 'Governance Overview',
              icon: Icons.shield_outlined,
              isSelected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
          ),
          // Quick Actions Tab
          Expanded(
            child: _ToggleTabItem(
              title: 'Quick Actions',
              icon: Icons.bolt_rounded,
              isSelected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTabItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleTabItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                bottom: 0,
                child: Container(
                  height: 3,
                  width: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Grid (Shown when Quick Actions pill is active)
// ─────────────────────────────────────────────────────────────────────────────

typedef QuickActionsGridView = _QuickActionsGridView;

class _QuickActionsGridView extends StatelessWidget {
  const _QuickActionsGridView();

  @override
  Widget build(BuildContext context) {
    final isLd = HiveStorage.isLdRole;
    final isClusterLead = HiveStorage.isClusterLead;
    final isSuperAdmin = HiveStorage.isSuperAdmin;

    // Role-based Quick Actions:
    // 1. L&D Team: Training, Role & Access, Approvals, Checklist Report.
    // 2. Cluster Lead: MMR / MIS, R&R, Issues, Checklist Report.
    // 3. CRRM / Super Admin: MMR / MIS, R&R, Issues, Governance Matrix, Checklist Report.
    // 4. Others (HR, Operations, EHS, etc.): Issues, R&R, Checklist Report.
    // (Note: Reports is provided by default in the bottom nav & sidebar).
    final List<
      ({
        String title,
        String subtitle,
        IconData icon,
        Color iconColor,
        Color bgColor,
      })
    >
    items;

    if (isLd) {
      items = [
        (
          title: 'Reports',
          subtitle: 'Governance visits, metrics & performance exports',
          icon: Icons.bar_chart_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
        ),
        (
          title: 'Checklist Report',
          subtitle: 'Update walkaround pending lines to completed',
          icon: Icons.assignment_turned_in_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'Training',
          subtitle: 'Training modules, sessions & certifications',
          icon: Icons.school_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'Role & Access',
          subtitle: 'User roles, permissions & site scope',
          icon: Icons.badge_outlined,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
        ),
        (
          title: 'Approvals',
          subtitle: 'Site transition review & sign-offs',
          icon: Icons.assignment_turned_in_outlined,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFFFBEB),
        ),
      ];
    } else if (isClusterLead) {
      items = [
        (
          title: 'Reports',
          subtitle: 'Governance visits, metrics & performance exports',
          icon: Icons.bar_chart_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
        ),
        (
          title: 'Checklist Report',
          subtitle: 'Update walkaround pending lines to completed',
          icon: Icons.assignment_turned_in_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'MMR / MIS',
          subtitle: 'Monthly review & MIS preparation governance',
          icon: Icons.fact_check_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'R&R',
          subtitle: 'Recognition and reward governance visits',
          icon: Icons.workspace_premium_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'Issues',
          subtitle: 'Site incidents, complaints & escalations',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
        ),
      ];
    } else if (isSuperAdmin) {
      items = [
        (
          title: 'Reports',
          subtitle: 'Governance visits, metrics & performance exports',
          icon: Icons.bar_chart_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
        ),
        (
          title: 'Checklist Report',
          subtitle: 'Update walkaround pending lines to completed',
          icon: Icons.assignment_turned_in_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'MMR / MIS',
          subtitle: 'Monthly review & MIS preparation governance',
          icon: Icons.fact_check_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'R&R',
          subtitle: 'Recognition and reward governance visits',
          icon: Icons.workspace_premium_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'Issues',
          subtitle: 'Site incidents, complaints & escalations',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
        ),
        (
          title: 'Governance Matrix',
          subtitle: 'Compliance matrix, standards & audit rules',
          icon: Icons.grid_view_rounded,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
        ),
      ];
    } else {
      // Others (HR, Operations, EHS, etc. as shown in image)
      items = [
        (
          title: 'Reports',
          subtitle: 'Governance visits, metrics & performance exports',
          icon: Icons.bar_chart_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
        ),
        (
          title: 'Checklist Report',
          subtitle: 'Update walkaround pending lines to completed',
          icon: Icons.assignment_turned_in_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'R&R',
          subtitle: 'Recognition and reward governance visits',
          icon: Icons.workspace_premium_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
        (
          title: 'Issues',
          subtitle: 'Site incidents, complaints & escalations',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
        ),
      ];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 550 ? 3 : 2);
        final aspectRatio = constraints.maxWidth >= 900
            ? 1.5
            : (constraints.maxWidth >= 550 ? 1.45 : 1.38);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _QuickActionGridCard(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.icon,
              iconColor: item.iconColor,
              bgColor: item.bgColor,
              onTap: () => _handleQuickActionTap(context, item.title),
            );
          },
        );
      },
    );
  }

  void _handleQuickActionTap(BuildContext context, String title) {
    if (title == 'Checklist Report') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ChecklistReportPage()));
      return;
    }

    if (title == 'MMR / MIS' || title == 'MMR/MIS') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MmrMisPage()));
      return;
    }

    if (title == 'R&R' || title == 'RR' || title == 'R & R') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RrPage()));
      return;
    }

    if (title == 'Training') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PlaceholderPageView(
            title: 'Training',
            parentTitle: 'Training module is coming soon',
            icon: Icons.school_outlined,
          ),
        ),
      );
      return;
    }

    if (title == 'Role & Access' || title == 'Roles') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PlaceholderPageView(
            title: 'Role & Access',
            parentTitle: 'Role & Access management is coming soon',
            icon: Icons.badge_outlined,
          ),
        ),
      );
      return;
    }

    if (title == 'Approvals') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PlaceholderPageView(
            title: 'Approvals',
            parentTitle: 'Approvals queue & site sign-offs are coming soon',
            icon: Icons.assignment_turned_in_outlined,
          ),
        ),
      );
      return;
    }

    if (title == 'Issues') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const IssuesPage()));
      return;
    }

    if (title == 'Governance Matrix') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const GovernanceMatrixPage()));
      return;
    }

    if (title == 'Reports' || title == 'Reports & Export') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ReportsPage()));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$title module is available for Super Admin management.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Box (chips removed as requested)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Subtitle
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// White card wrapper with smooth radius 16 & gentle shadow
// ─────────────────────────────────────────────────────────────────────────────

class _WCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _WCard({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered Stat Grid (Professional Lightweight Pastel Design)
// ─────────────────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  final DashboardModel data;
  const _StatGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final ov = data.overview;

    return Column(
      children: [
        // ── TOP ROW: Overall Sites (Pill) + Live Sites (Compact Card) ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 12,
              child: _OverallSitesCard(
                sitesCount: ov.sites,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AllSitesPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 8,
              child: _LiveSitesCard(
                liveCount: ov.live,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllSitesPage(initialStatus: 'Live'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── BOTTOM SECTION: Staggered Layout ──
        // Left Column: Transition Sites (Tall Vertical Card with Dashed Border)
        // Right Column: Users (Top Pill) + [R&R Pending + Survey Count] (Bottom Row)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transition Sites (Vertical Card)
              Expanded(
                flex: 6,
                child: _TransitionSitesCard(
                  transitionCount: ov.transition,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const AllSitesPage(initialStatus: 'Transition'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Right Group: Users Pill + 2 Mini Cards
              Expanded(
                flex: 14,
                child: Column(
                  children: [
                    // Users Card (Pill)
                    _UsersCard(
                      usersCount: ov.users,
                      onTap: () {
                        // Action/Feedback
                      },
                    ),
                    const SizedBox(height: 10),

                    // Bottom Row: R&R Pending + Survey Count
                    Row(
                      children: [
                        Expanded(
                          child: _PendingCard(
                            pendingCount: 0,
                            onTap: () {
                              // Optional action
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SurveyCard(
                            surveyCount: 0,
                            onTap: () {
                              // Optional action
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Overall Sites Card (Pill Shape with Colorful Dynamic Sparkline)
// ─────────────────────────────────────────────────────────────────────────────

class _OverallSitesCard extends StatelessWidget {
  final int sitesCount;
  final VoidCallback onTap;

  const _OverallSitesCard({required this.sitesCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE4EBFC), Color(0xFFD6E3FC)],
          ),
          border: Border.all(color: const Color(0xFFC7D8FA), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D5BFF).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              // Vibrant multi-color flowing sparkline chart on right
              const Positioned(
                right: 6,
                bottom: 4,
                width: 78,
                height: 38,
                child: CustomPaint(painter: _SparklinePainter()),
              ),

              // Left circular badge & text
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Concentric circle icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2D5BFF).withValues(alpha: 0.12),
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2D5BFF),
                          ),
                          child: const Icon(
                            Icons.domain_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Label & Count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Overall Sites',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '$sitesCount',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.05,
                          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Live Sites Card (Compact Pastel Mint with Verified Badge & No Empty Gaps)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveSitesCard extends StatelessWidget {
  final int liveCount;
  final VoidCallback onTap;

  const _LiveSitesCard({required this.liveCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F6EE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFCEEFDB), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Dot matrix background pattern on right
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 36,
                child: const CustomPaint(
                  painter: _DotMatrixPainter(
                    color: Color(0x1F16A34A),
                    rows: 4,
                    cols: 3,
                    spacing: 7.5,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFF15803D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Live Sites',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$liveCount',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8F0D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                'Active',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Transition Sites Card (Clean Vertical, No Unnecessary Arrow)
// ─────────────────────────────────────────────────────────────────────────────

class _TransitionSitesCard extends StatelessWidget {
  final int transitionCount;
  final VoidCallback onTap;

  const _TransitionSitesCard({
    required this.transitionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: Color(0xFFD8B4FE),
          strokeWidth: 1.2,
          radius: 20,
          dashWidth: 4.5,
          dashSpace: 3.5,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4FD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    'Transition\nSites',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$transitionCount',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              // Swap icon badge (no arrow button)
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Users Card (Clean Background Without Circle Containers, No Arrow)
// ─────────────────────────────────────────────────────────────────────────────

class _UsersCard extends StatelessWidget {
  final int usersCount;
  final VoidCallback onTap;

  const _UsersCard({required this.usersCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2E6),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFFFDEC2), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA580C).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Donut chart ring around users icon
            CustomPaint(
              painter: const _DonutRingPainter(),
              child: Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF334155),
                    size: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Label & Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Users',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '$usersCount',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.05,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Active Now badge (clean, without arrow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6D1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Active Now',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C2D12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. R&R Pending Card
// ─────────────────────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const _PendingCard({required this.pendingCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9C3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Label + Sync icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'R&R Pending',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDE68A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: Color(0xFFB45309),
                    size: 11,
                  ),
                ),
              ],
            ),

            // Bottom row: Hourglass badge + count
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDE68A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: Color(0xFFB45309),
                    size: 15,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '$pendingCount',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF78350F),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Survey Count Card (Fixed clipping issue, No right arrow)
// ─────────────────────────────────────────────────────────────────────────────

class _SurveyCard extends StatelessWidget {
  final int surveyCount;
  final VoidCallback onTap;

  const _SurveyCard({required this.surveyCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 74,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 5,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dot matrix background on right
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 32,
              child: const CustomPaint(
                painter: _DotMatrixPainter(
                  color: Color(0x1F475569),
                  rows: 4,
                  cols: 3,
                  spacing: 6.5,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Survey Count',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Color(0xFF334155),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '$surveyCount',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters for Staggered Stat Cards
// ─────────────────────────────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.radius = 22,
    this.dashWidth = 5.0,
    this.dashSpace = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Smooth flowing dynamic trend curve
    final path = Path();
    path.moveTo(0, h * 0.75);
    path.cubicTo(w * 0.22, h * 0.85, w * 0.35, h * 0.32, w * 0.55, h * 0.55);
    path.cubicTo(w * 0.70, h * 0.70, w * 0.82, h * 0.15, w * 0.95, h * 0.20);

    // Multi-color Area Fill underneath (Pink/Purple/Blue glow)
    final fillPath = Path.from(path)
      ..lineTo(w * 0.95, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF43F5E).withValues(alpha: 0.28),
          const Color(0xFF8B5CF6).withValues(alpha: 0.14),
          const Color(0xFF06B6D4).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Secondary subtle turquoise-purple shadow line for depth
    final shadowPath = Path();
    shadowPath.moveTo(0, h * 0.85);
    shadowPath.cubicTo(
      w * 0.25,
      h * 0.92,
      w * 0.40,
      h * 0.55,
      w * 0.60,
      h * 0.72,
    );
    shadowPath.cubicTo(
      w * 0.75,
      h * 0.85,
      w * 0.85,
      h * 0.40,
      w * 0.95,
      h * 0.38,
    );

    final shadowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFFA855F7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(shadowPath, shadowPaint);

    // Main Vibrant Gradient Curve (Cyan -> Royal Blue -> Purple -> Coral)
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF06B6D4), // Cyan
          Color(0xFF3B82F6), // Royal Blue
          Color(0xFF8B5CF6), // Purple
          Color(0xFFF43F5E), // Coral / Hot Pink
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Glowing endpoint node
    final endPoint = Offset(w * 0.95, h * 0.20);

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFF43F5E).withValues(alpha: 0.35);
    canvas.drawCircle(endPoint, 6.0, glowPaint);

    // Middle solid coral circle
    final dotPaint = Paint()..color = const Color(0xFFF43F5E);
    canvas.drawCircle(endPoint, 3.5, dotPaint);

    // Inner bright white center
    final innerDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(endPoint, 1.8, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => false;
}

class _DonutRingPainter extends CustomPainter {
  const _DonutRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 2.6;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 4 segments: Blue, Amber, Emerald, Rose
    final segments = [
      (const Color(0xFF3B82F6), -1.5, 1.3),
      (const Color(0xFFF59E0B), -0.1, 1.2),
      (const Color(0xFF10B981), 1.2, 1.4),
      (const Color(0xFFF43F5E), 2.7, 1.0),
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.$1
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, seg.$2, seg.$3, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutRingPainter oldDelegate) => false;
}

class _DotMatrixPainter extends CustomPainter {
  final Color color;
  final int rows;
  final int cols;
  final double spacing;

  const _DotMatrixPainter({
    required this.color,
    this.rows = 4,
    this.cols = 4,
    this.spacing = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(
          Offset(size.width - (c * spacing) - 8, (r * spacing) + 8),
          1.2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Unique & Attractive Divider between Stat Cards and Due Sites
// ─────────────────────────────────────────────────────────────────────────────

class _DueSitesDivider extends StatelessWidget {
  const _DueSitesDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Left gradient line fading from transparent to sky blue
          Expanded(
            child: Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFFE2E8F0),
                    Color(0xFF93C5FD),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Left diamond accent
          Container(
            width: 4,
            height: 4,
            transform: Matrix4.rotationZ(0.785398),
            decoration: const BoxDecoration(color: Color(0xFF60A5FA)),
          ),
          const SizedBox(width: 8),

          // Center unique decorative capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing pulsating status beacon
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.55),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6.5),
                Text(
                  'RENEWAL WATCH',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.auto_awesome,
                  size: 11,
                  color: Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right diamond accent
          Container(
            width: 4,
            height: 4,
            transform: Matrix4.rotationZ(0.785398),
            decoration: const BoxDecoration(color: Color(0xFF60A5FA)),
          ),
          const SizedBox(width: 8),

          // Right gradient line fading from sky blue to transparent
          Expanded(
            child: Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF93C5FD),
                    Color(0xFFE2E8F0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Due sites bar (3D Map Illustration + Due Sites Across Zones + 30/60/90 Cards)
// ─────────────────────────────────────────────────────────────────────────────

typedef DueSitesBar = _DueSitesBar;

class _DueSitesBar extends StatefulWidget {
  final RenewalCountsModel renewals;
  const _DueSitesBar({required this.renewals});

  @override
  State<_DueSitesBar> createState() => _DueSitesBarState();
}

class _DueSitesBarState extends State<_DueSitesBar> {
  int? _selectedBucket; // 30, 60, 90, or null

  @override
  Widget build(BuildContext context) {
    final r = widget.renewals;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCE7F6), width: 0),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white, // Soft sky blue on the left
            Colors.white, // Smooth transition
            Colors.white, // Pure clean white on the right
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC7DBFA).withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Map Illustration (top) + Due Sites Across Zones (bottom) in same Column
              SizedBox(
                width: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/due_sites_map.png',
                      width: 58,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFF97316),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Due Sites',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0C2340),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Across Zones',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF627D98),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Vertical subtle divider line
              Container(height: 62, width: 1.2, color: const Color(0xFFE2E8F0)),

              const SizedBox(width: 8),

              // Right: 3 Interval Cards: 30 Days (Pink/Red), 60 Days (Yellow/Orange), 90 Days (Ice Blue/Navy)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _DueSiteIntervalCard(
                        days: 30,
                        count: r.d30,
                        bgColor: const Color(0xFFFFECEF),
                        badgeColor: const Color(0xFFEF384F),
                        isSelected: _selectedBucket == 30,
                        onTap: () {
                          setState(() {
                            _selectedBucket = _selectedBucket == 30 ? null : 30;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _DueSiteIntervalCard(
                        days: 60,
                        count: r.d60,
                        bgColor: const Color(0xFFFFF2DC),
                        badgeColor: const Color(0xFFFA8C16),
                        isSelected: _selectedBucket == 60,
                        onTap: () {
                          setState(() {
                            _selectedBucket = _selectedBucket == 60 ? null : 60;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _DueSiteIntervalCard(
                        days: 90,
                        count: r.d90,
                        bgColor: const Color(0xFFE4F0FF),
                        badgeColor: const Color(0xFF1E88E5),
                        isSelected: _selectedBucket == 90,
                        onTap: () {
                          setState(() {
                            _selectedBucket = _selectedBucket == 90 ? null : 90;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedBucket != null) ...[
            const SizedBox(height: 12),
            _RenewalDetailsList(
              bucket: _selectedBucket!,
              items: _selectedBucket == 30
                  ? r.items30
                  : (_selectedBucket == 60 ? r.items60 : r.items90),
              onClose: () => setState(() => _selectedBucket = null),
            ),
          ],
        ],
      ),
    );
  }
}

class _DueSiteIntervalCard extends StatelessWidget {
  final int days;
  final int count;
  final Color bgColor;
  final Color badgeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _DueSiteIntervalCard({
    required this.days,
    required this.count,
    required this.bgColor,
    required this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 86,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // 1. Base card body with rounded corners - clean crisp WHITE
              Positioned.fill(
                top: 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.fromLTRB(2, 18, 2, 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? badgeColor : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 0.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? badgeColor.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$days Days',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF486581),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$count',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A2540),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Top dome arch extending upwards with white background
              Positioned(
                top: 0,
                child: Container(
                  width: 36,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isSelected
                            ? badgeColor
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 0.3,
                      ),
                      // left: BorderSide(
                      //   color: isSelected
                      //       ? badgeColor
                      //       : const Color(0xFFE2E8F0),
                      //   width: isSelected ? 2.0 : 1.0,
                      // ),
                      // right: BorderSide(
                      //   color: isSelected
                      //       ? badgeColor
                      //       : const Color(0xFFE2E8F0),
                      //   width: isSelected ? 2.0 : 1.0,
                      // ),
                    ),
                  ),
                ),
              ),

              // 3. Circular icon avatar with soft matching halo and same avatar color
              Positioned(
                top: 3,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 11.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenewalDetailsList extends StatelessWidget {
  final int bucket;
  final List<RenewalItemModel> items;
  final VoidCallback onClose;

  const _RenewalDetailsList({
    required this.bucket,
    required this.items,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Text(
                'Due in $bucket Days (${items.length})',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: _kSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'No sites in this interval.',
              style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 14,
                      color: _kBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            '${item.clusterName} · ${item.zoneName}',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: _kSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '${item.daysRemaining}d left',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.daysRemaining <= 7
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sites By Zone — Teal Capsule Progress Bars + View All
// ─────────────────────────────────────────────────────────────────────────────

class SitesByZoneCard extends StatelessWidget {
  final List<GeographyItemModel> geography;
  final List<ZoneModel> zones;
  const SitesByZoneCard({
    super.key,
    required this.geography,
    required this.zones,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer geography if available; otherwise fallback to zones
    final displayItems = geography.isNotEmpty
        ? geography.map((g) => (name: g.name, sites: g.sites)).toList()
        : zones.map((z) => (name: z.name, sites: z.sites)).toList();

    final hasSites = displayItems.any((g) => g.sites > 0);
    final maxSites = displayItems.fold<int>(
      1,
      (m, g) => g.sites > m ? g.sites : m,
    );

    return _WCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sites By Zone',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayItems.isEmpty || !hasSites)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.domain_disabled_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No sites allocated yet',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sites allocated to your zones will appear here',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            ...displayItems.map((g) {
              final frac = maxSites == 0 ? 0.0 : g.sites / maxSites;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    StateAvatar(name: g.name, size: 22),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 85,
                      child: Text(
                        g.name,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: frac.clamp(0.06, 1.0),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0D9488),
                                    Color(0xFF14B8A6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${g.sites}',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
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
}

typedef _SitesByZoneCard = SitesByZoneCard;

// ─────────────────────────────────────────────────────────────────────────────
// Governance Overview (Donut Chart + Legend + Clipboard Illustration - Image 3)
// ─────────────────────────────────────────────────────────────────────────────

class GovernanceCard extends StatelessWidget {
  final OverviewModel overview;
  const GovernanceCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final total =
        overview.governancePending +
        overview.governanceCompleted +
        overview.governanceDue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF1E60EB),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Governance Overview',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Current status of governance',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // View Details is omitted as requested by user
            ],
          ),
          const SizedBox(height: 20),

          // ── Body: Donut Chart on Left, Divider, 3 Stat Cards on Right (or fallback if 0) ──
          if (total == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No governance',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No governance activities or visits scheduled yet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isVeryNarrow = constraints.maxWidth < 340;

                final donutWidget = SizedBox(
                  width: 116,
                  height: 116,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      pending: overview.governancePending,
                      completed: overview.governanceCompleted,
                      due: overview.governanceDue,
                      total: total,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: const Color(0xFF0F172A),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Items',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                final cardsWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _GovStatCard(
                            count: overview.governancePending,
                            label: 'Pending',
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFF1E60EB),
                            iconBg: const Color(0xFFDBEAFE),
                            cardBg: const Color(0xFFF0F7FF),
                            borderColor: const Color(0xFFE0EDFD),
                            waveColor: const Color(0xFFBFDBFE),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GovStatCard(
                            count: overview.governanceCompleted,
                            label: 'Completed',
                            icon: Icons.check_rounded,
                            iconColor: const Color(0xFF16A34A),
                            iconBg: const Color(0xFFDCFCE7),
                            cardBg: const Color(0xFFF0FDF4),
                            borderColor: const Color(0xFFDCFCE7),
                            waveColor: const Color(0xFFBBF7D0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _GovStatCard(
                            count: overview.governanceDue,
                            label: 'Due',
                            icon: Icons.priority_high_rounded,
                            iconColor: const Color(0xFFEF4444),
                            iconBg: const Color(0xFFFEE2E2),
                            cardBg: const Color(0xFFFEF2F2),
                            borderColor: const Color(0xFFFEE2E2),
                            waveColor: const Color(0xFFFECACA),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ],
                );

                if (isVeryNarrow) {
                  return Column(
                    children: [
                      donutWidget,
                      const SizedBox(height: 16),
                      cardsWidget,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    donutWidget,
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 120,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: cardsWidget),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

typedef _GovernanceCard = GovernanceCard;

class _GovStatCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color cardBg;
  final Color borderColor;
  final Color waveColor;

  const _GovStatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.cardBg,
    required this.borderColor,
    required this.waveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(painter: _CardWavePainter(color: waveColor)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(icon, size: 14, color: iconColor),
                      ),
                    ),
                    Text(
                      '$count',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
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
}

class _CardWavePainter extends CustomPainter {
  final Color color;
  const _CardWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPath = Path()
      ..moveTo(0, h * 0.70)
      ..cubicTo(w * 0.25, h * 0.55, w * 0.45, h * 0.90, w * 0.70, h * 0.75)
      ..cubicTo(w * 0.85, h * 0.65, w * 0.95, h * 0.85, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.08)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()
      ..moveTo(0, h * 0.70)
      ..cubicTo(w * 0.25, h * 0.55, w * 0.45, h * 0.90, w * 0.70, h * 0.75)
      ..cubicTo(w * 0.85, h * 0.65, w * 0.95, h * 0.85, w, h * 0.70);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.6);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(_CardWavePainter old) => old.color != color;
}

class _DonutPainter extends CustomPainter {
  final int pending, completed, due, total;
  const _DonutPainter({
    required this.pending,
    required this.completed,
    required this.due,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Base background track (soft light grey/blue)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFEFF4FB);
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (total == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Start angle: top-right (~ -0.15 * pi)
    double start = -math.pi * 0.15;

    // Segments: Pending (gradient/vibrant blue), Completed (green), Due (red)
    final segs = [
      (count: pending, color: const Color(0xFF0284C7)),
      (count: completed, color: const Color(0xFF22C55E)),
      (count: due, color: const Color(0xFFEF4444)),
    ];

    double? firstSegmentEndAngle;

    for (var i = 0; i < segs.length; i++) {
      final s = segs[i];
      if (s.count == 0) continue;
      final sweep = 2 * math.pi * (s.count / total);
      paint.color = s.color;

      canvas.drawArc(
        rect,
        start,
        sweep.clamp(0.05, 2 * math.pi - 0.05),
        false,
        paint,
      );

      if (i == 0) {
        firstSegmentEndAngle = start;
      }
      start += sweep;
    }

    // Draw the stylish indicator circle on the blue arc endpoint (as seen in screenshot)
    if (firstSegmentEndAngle != null && pending > 0) {
      final dotAngle = firstSegmentEndAngle;
      final dotCenter = Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      );

      final outerDot = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, stroke * 0.65, outerDot);

      final innerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, stroke * 0.28, innerDot);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.pending != pending ||
      old.completed != completed ||
      old.due != due ||
      old.total != total;
}

// ─────────────────────────────────────────────────────────────────────────────
// Zones table
// ─────────────────────────────────────────────────────────────────────────────

typedef _ZonesCard = ZonesCard;

class ZonesCard extends StatefulWidget {
  final List<ZoneModel> zones;
  const ZonesCard({super.key, required this.zones});

  @override
  State<ZonesCard> createState() => _ZonesCardState();
}

class _ZonesCardState extends State<ZonesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final displayedZones = _expanded
        ? widget.zones
        : widget.zones.take(5).toList();

    return _WCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: _kBlue),
                const SizedBox(width: 6),
                Text(
                  'Zones',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.zones.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          if (widget.zones.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  'No zones allocated yet',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                ),
              ),
            )
          else ...[
            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _TH('Name')),
                  _TH('Sites', width: 48),
                  _TH('Live', width: 48),
                  _TH('Transition', width: 72),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            // Rows (first 5 by default)
            ...displayedZones.map((z) => _ZoneRow(zone: z)),
          ],
          // View all at bottom
          if (widget.zones.length > 5) ...[
            const Divider(height: 1, color: _kBorder),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'View all zones (${widget.zones.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: _kBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final ZoneModel zone;
  const _ZoneRow({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final meta = MetaService.instance.meta;
              final resolvedZoneId = zone.id.isNotEmpty
                  ? zone.id
                  : (meta.zones
                            .where(
                              (z) =>
                                  z.name.trim().toLowerCase() ==
                                  zone.name.trim().toLowerCase(),
                            )
                            .firstOrNull
                            ?.id ??
                        '');

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AllSitesPage(
                    initialZoneId: resolvedZoneId.isNotEmpty
                        ? resolvedZoneId
                        : null,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  StateAvatar(name: zone.name, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      zone.name,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _TC('${zone.sites}', width: 48),
                  _TC(
                    '${zone.live}',
                    width: 48,
                    color: zone.live > 0 ? _kBlue : _kSlate,
                  ),
                  _TC(
                    '${zone.transition}',
                    width: 72,
                    color: zone.transition > 0 ? _kBlue : _kSlate,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          height: 1,
          color: Color(0xFFF1F5F9),
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clusters table
// ─────────────────────────────────────────────────────────────────────────────

typedef _ClustersCard = ClustersCard;

class ClustersCard extends StatefulWidget {
  final List<ClusterModel> clusters;
  const ClustersCard({super.key, required this.clusters});

  @override
  State<ClustersCard> createState() => _ClustersCardState();
}

class _ClustersCardState extends State<ClustersCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final displayedClusters = _expanded
        ? widget.clusters
        : widget.clusters.take(5).toList();

    return _WCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.workspaces_outlined, size: 16, color: _kBlue),
                const SizedBox(width: 6),
                Text(
                  'Clusters',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.clusters.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          if (widget.clusters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  'No clusters allocated yet',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                ),
              ),
            )
          else ...[
            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _TH('Name\nRegion')),
                  _TH('Sites', width: 44),
                  _TH('Live', width: 44),
                  _TH('Transition', width: 66),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            // Rows (first 5 by default)
            ...displayedClusters.map((c) => _ClusterRow(cluster: c)),
          ],
          // View all at bottom
          if (widget.clusters.length > 5) ...[
            const Divider(height: 1, color: _kBorder),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'View all clusters (${widget.clusters.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: _kBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClusterRow extends StatelessWidget {
  final ClusterModel cluster;
  const _ClusterRow({required this.cluster});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final meta = MetaService.instance.meta;
              final resolvedClusterId = cluster.id.isNotEmpty
                  ? cluster.id
                  : (meta.clusters
                            .where(
                              (c) =>
                                  c.name.trim().toLowerCase() ==
                                  cluster.name.trim().toLowerCase(),
                            )
                            .firstOrNull
                            ?.id ??
                        '');

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AllSitesPage(
                    initialClusterId: resolvedClusterId.isNotEmpty
                        ? resolvedClusterId
                        : null,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  StateAvatar(
                    name: cluster.zoneName.isNotEmpty
                        ? cluster.zoneName
                        : cluster.name,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cluster.name,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cluster.zoneName,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: _kSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TC('${cluster.sites}', width: 44),
                  _TC(
                    '${cluster.live}',
                    width: 44,
                    color: cluster.live > 0 ? _kBlue : _kSlate,
                  ),
                  _TC(
                    '${cluster.transition}',
                    width: 66,
                    color: cluster.transition > 0 ? _kBlue : _kSlate,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          height: 1,
          color: Color(0xFFF1F5F9),
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Governance Activity / Upcoming L&D Work
// ─────────────────────────────────────────────────────────────────────────────

typedef _RecentGovernanceCard = RecentGovernanceCard;

class RecentGovernanceCard extends StatelessWidget {
  final List<GovernanceListItemModel> items;
  const RecentGovernanceCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isLd = HiveStorage.isLdRole;
    return _WCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  isLd
                      ? Icons.calendar_today_rounded
                      : Icons.assignment_outlined,
                  size: 16,
                  color: _kBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLd ? 'Upcoming L&D Work' : 'Recent Governance Activity',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                if (isLd)
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TransitionSitesPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'View All',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kBlue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  isLd ? 'No upcoming L&D work' : 'No recent activities',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                ),
              ),
            )
          else
            ...items.map((i) => GovActivityRow(item: i, isLd: isLd)),
        ],
      ),
    );
  }
}

class _ParsedDate {
  final String month;
  final String day;
  final String weekday;
  const _ParsedDate({
    required this.month,
    required this.day,
    required this.weekday,
  });
}

class GovActivityRow extends StatelessWidget {
  final GovernanceListItemModel item;
  final bool isLd;

  const GovActivityRow({super.key, required this.item, this.isLd = false});

  _ParsedDate _parseDate(String dateStr) {
    if (dateStr.trim().isEmpty) {
      return const _ParsedDate(month: 'L&D', day: '•', weekday: '');
    }
    final dt = DateTime.tryParse(dateStr.trim());
    if (dt != null) {
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return _ParsedDate(
        month: months[dt.month - 1],
        day: '${dt.day}',
        weekday: days[dt.weekday - 1],
      );
    }
    final parts = dateStr
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    String? weekday;
    String? month;
    String? day;

    const weekDaysMap = {
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };
    const monthsList = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];

    for (final p in parts) {
      final lower = p.toLowerCase();
      final three = lower.length >= 3 ? lower.substring(0, 3) : lower;
      if (int.tryParse(p) != null) {
        day = p;
      } else if (monthsList.contains(three)) {
        month = three.toUpperCase();
      } else if (weekDaysMap.containsKey(three)) {
        weekday = weekDaysMap[three];
      }
    }

    return _ParsedDate(
      month: month ?? 'OCT',
      day: day ?? '•',
      weekday: weekday ?? '',
    );
  }

  Widget _buildStateBadge(String state) {
    final s = state.trim().toLowerCase();
    Color bg;
    Color text;
    Color border;

    if (s == 'verified' || s == 'completed' || s == 'done' || s == 'closed') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF16A34A);
      border = const Color(0xFFBBF7D0);
    } else if (s == 'wip' || s == 'in progress' || s == 'pending') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
      border = const Color(0xFFFDE68A);
    } else if (s == 'overdue' || s == 'due') {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFEF4444);
      border = const Color(0xFFFECACA);
    } else {
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF1A73E8);
      border = const Color(0xFFBFDBFE);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        state.isNotEmpty ? state : 'Verified',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLdItem = isLd || HiveStorage.isLdRole;
    final parsedDate = _parseDate(item.dueDate);

    return Column(
      children: [
        const Divider(height: 1, color: _kBorder),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Check if item points to an L&D Transition page
              final href = item.href ?? '';
              String? siteId;
              if (href.isNotEmpty &&
                  (href.contains('ld-transition') ||
                      href.contains('transition'))) {
                siteId = href.split('/').where((s) => s.isNotEmpty).last;
              } else if (isLdItem || item.id.startsWith('ld-rev-')) {
                // Try extracting UUID from id: ld-rev-{siteId}-...
                final match = RegExp(
                  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
                ).firstMatch(item.id);
                if (match != null) {
                  siteId = match.group(0);
                }
              }

              if (siteId != null && siteId.isNotEmpty) {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => TransitionSiteDetailPage(siteId: siteId!),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<DashboardBloc>().add(const LoadDashboard());
                }
                return;
              }

              if (item.id.isNotEmpty) {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ActivityExecutionPage(
                      activityId: item.id,
                      siteName: item.siteName.isNotEmpty ? item.siteName : null,
                    ),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<DashboardBloc>().add(const LoadDashboard());
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isLdItem) ...[
                    // Blue calendar date container (matching web image)
                    Container(
                      width: 46,
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1E40AF,
                            ).withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            parsedDate.month,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            parsedDate.day,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          if (parsedDate.weekday.isNotEmpty)
                            Text(
                              parsedDate.weekday,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.isNotEmpty
                              ? item.title
                              : (item.activityLabel ?? ''),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLdItem
                              ? (item.siteName.isNotEmpty
                                    ? item.siteName
                                    : 'DIGILOGY-DEV')
                              : '${item.siteName}  ·  ${item.roleLabel}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: isLdItem
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: _kBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isLdItem) ...[
                          if (item.dueDate.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              item.dueDate,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: _kSlate,
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            'Assignee: ${item.assigneeName}  ·  Due: ${item.dueDate}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: _kSlate,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStateBadge(item.state),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared table helpers
// ─────────────────────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final double? width;
  const _TH(this.text, {this.width});

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        color: const Color(0xFF94A3B8),
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
    );
    return width != null ? SizedBox(width: width, child: child) : child;
  }
}

class _TC extends StatelessWidget {
  final String value;
  final double? width;
  final Color? color;
  const _TC(this.value, {this.width, this.color});

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      value,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? _kSlate,
      ),
    );
    return width != null
        ? SizedBox(
            width: width,
            child: Center(child: child),
          )
        : child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: _kSlate),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Retry',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
