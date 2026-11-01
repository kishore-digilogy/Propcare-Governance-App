import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/dashboard_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

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
    final userRole = HiveStorage.userRole ?? 'CRRM / Super Admin';

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
                    role,
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
                  value: role,
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
  static const double _maxHeroOffset = 126.0;

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

  bool _isSuperAdmin(DashboardModel data) {
    final role =
        (data.workspace.viewer.role.isNotEmpty
                ? data.workspace.viewer.role
                : (HiveStorage.userRole ?? ''))
            .toLowerCase();
    final roleLabel =
        (data.workspace.viewer.roleLabel.isNotEmpty
                ? data.workspace.viewer.roleLabel
                : (HiveStorage.userRole ?? ''))
            .toLowerCase();

    return role.contains('super') ||
        role.contains('admin') ||
        role.contains('crrm') ||
        roleLabel.contains('super') ||
        roleLabel.contains('admin') ||
        roleLabel.contains('crrm');
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

    final isSuperAdmin = _isSuperAdmin(data);

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
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: _HeroBanner(userName: userName),
          ),
        ),

        // Toggle Bar for Super Admin (Moves to top directly below header)
        if (isSuperAdmin) ...[
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
        ] else
          const SizedBox(height: 6),

        // PageView: Page 0 = Governance Overview, Page 1 = Quick Actions
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: PageView(
              controller: _pageController,
              physics: isSuperAdmin
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) {
                setState(() => _activeToggle = idx);
              },
              children: [
                // Page 0: Governance Overview
                _buildGovernanceOverviewPage(data),

                // Page 1: Quick Actions (Only for Super Admin)
                if (isSuperAdmin)
                  _buildQuickActionsPage(data)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGovernanceOverviewPage(DashboardModel data) {
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
          const SizedBox(height: 12),

          // ── Due sites bar (Calendar icon + 30d/60d/90d dot stats)
          _DueSitesBar(renewals: data.renewals),
          const SizedBox(height: 14),

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

          // ── Recent Governance
          _RecentGovernanceCard(items: data.overview.governanceList),
          const SizedBox(height: 24),
        ],
      ),
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
      displayName = 'PropCare Administrator';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFD), Color(0xFFF0F6FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background soft cloud accents
          Positioned(
            right: 88,
            top: 2,
            child: Icon(
              Icons.cloud_rounded,
              size: 34,
              color: const Color(0xFFDCEAF9).withValues(alpha: 0.65),
            ),
          ),
          Positioned(
            right: 18,
            top: 0,
            child: Icon(
              Icons.cloud_rounded,
              size: 24,
              color: const Color(0xFFE5F0FC).withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            right: 130,
            bottom: 6,
            child: Icon(
              Icons.cloud_rounded,
              size: 22,
              color: const Color(0xFFE8F3FD).withValues(alpha: 0.6),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
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
                            displayName,
                            style: GoogleFonts.outfit(
                              fontSize: displayName.length > 16 ? 18 : 23,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('👋', style: TextStyle(fontSize: 19)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitor and manage governance across all modules.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Light sky blue buildings illustration with orange shield & trees
              Image.asset(
                AppAssets.dashboardHeroBuildings,
                width: 148,
                height: 108,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ],
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
        color: const Color(
          0xFFF1F5F9,
        ), // Light grey capsule background (Image 2)
        borderRadius: BorderRadius.circular(24),
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Grid (Shown when Quick Actions pill is active)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGridView extends StatelessWidget {
  const _QuickActionsGridView();

  @override
  Widget build(BuildContext context) {
    // Exactly the 4 items requested for Super Admin:
    // 1. Issues
    // 2. Approvals
    // 3. Governance Matrix
    // 4. Reports
    final items = [
      (
        title: 'Issues',
        subtitle: 'Site incidents, complaints & escalations',
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEF2F2),
      ),
      (
        title: 'Approvals',
        subtitle: 'Work permits, sign-offs & budget requests',
        icon: Icons.assignment_turned_in_rounded,
        iconColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
      ),
      (
        title: 'Governance Matrix',
        subtitle: 'Compliance matrix, standards & audit rules',
        icon: Icons.grid_view_rounded,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
      ),
      (
        title: 'Reports',
        subtitle: 'Governance visits, metrics & performance exports',
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.38,
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
  }

  void _handleQuickActionTap(BuildContext context, String title) {
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
// 6-stat grid (2 Columns x 3 Rows)
// ─────────────────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  final DashboardModel data;
  const _StatGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final ov = data.overview;
    final cards = [
      _SC(
        icon: Icons.domain_rounded,
        label: 'Overall Sites',
        value: '${ov.sites}',
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
      ),
      _SC(
        icon: Icons.check_circle_rounded,
        label: 'Live Sites',
        value: '${ov.live}',
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFFDCFCE7),
      ),
      _SC(
        icon: Icons.sync_alt_rounded,
        label: 'Transition Sites',
        value: '${ov.transition}',
        color: const Color(0xFF9333EA),
        bgColor: const Color(0xFFF3E8FF),
      ),
      _SC(
        icon: Icons.groups_rounded,
        label: 'Users',
        value: '${ov.users}',
        color: const Color(0xFF0284C7),
        bgColor: const Color(0xFFE0F2FE),
      ),
      _SC(
        icon: Icons.hourglass_bottom_rounded,
        label: 'R&R Pending',
        value: '0',
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _SC(
        icon: Icons.bar_chart_rounded,
        label: 'Survey Count',
        value: '0',
        color: const Color(0xFF0D9488),
        bgColor: const Color(0xFFCCFBF1),
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < cards.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: _StatCard(sc: cards[i])),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < cards.length
                      ? _StatCard(sc: cards[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SC {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  const _SC({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });
}

class _StatCard extends StatelessWidget {
  final _SC sc;
  const _StatCard({required this.sc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: sc.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(sc.icon, color: sc.color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sc.label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  sc.value,
                  style: GoogleFonts.outfit(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Due sites bar (Calendar Icon + 30 Days, 60 Days, 90 Days Dots)
// ─────────────────────────────────────────────────────────────────────────────

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
        color: const Color(0xFFFFF7ED), // Soft warm peach-cream background
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Orange Calendar Icon
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFFF97316),
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Due Sites',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),
              Container(height: 28, width: 1, color: const Color(0xFFFFE0B2)),
              const Spacer(),

              // 30 Days Column
              _DueSiteIntervalColumn(
                dotColor: const Color(0xFFEF4444),
                label: '30 Days',
                count: r.d30,
                isSelected: _selectedBucket == 30,
                onTap: () {
                  setState(() {
                    _selectedBucket = _selectedBucket == 30 ? null : 30;
                  });
                },
              ),
              const Spacer(),
              Container(height: 28, width: 1, color: const Color(0xFFFFE0B2)),
              const Spacer(),

              // 60 Days Column
              _DueSiteIntervalColumn(
                dotColor: const Color(0xFFF59E0B),
                label: '60 Days',
                count: r.d60,
                isSelected: _selectedBucket == 60,
                onTap: () {
                  setState(() {
                    _selectedBucket = _selectedBucket == 60 ? null : 60;
                  });
                },
              ),
              const Spacer(),
              Container(height: 28, width: 1, color: const Color(0xFFFFE0B2)),
              const Spacer(),

              // 90 Days Column
              _DueSiteIntervalColumn(
                dotColor: const Color(0xFF2563EB),
                label: '90 Days',
                count: r.d90,
                isSelected: _selectedBucket == 90,
                onTap: () {
                  setState(() {
                    _selectedBucket = _selectedBucket == 90 ? null : 90;
                  });
                },
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

class _DueSiteIntervalColumn extends StatelessWidget {
  final Color dotColor;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _DueSiteIntervalColumn({
    required this.dotColor,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7.5,
                  height: 7.5,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
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

class _SitesByZoneCard extends StatefulWidget {
  final List<GeographyItemModel> geography;
  final List<ZoneModel> zones;
  const _SitesByZoneCard({required this.geography, required this.zones});

  @override
  State<_SitesByZoneCard> createState() => _SitesByZoneCardState();
}

class _SitesByZoneCardState extends State<_SitesByZoneCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final geo = widget.geography;
    final maxSites = geo.fold<int>(1, (m, g) => g.sites > m ? g.sites : m);
    final displayed = _showAll ? geo : geo.take(4).toList();

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
              const Spacer(),
              if (geo.length > 2)
                InkWell(
                  onTap: () {
                    setState(() {
                      _showAll = !_showAll;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        _showAll ? 'Show Less' : 'View All',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFFD97706),
                        size: 14,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayed.map((g) {
            final frac = maxSites == 0 ? 0.0 : g.sites / maxSites;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
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
                                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
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

// ─────────────────────────────────────────────────────────────────────────────
// Governance Overview (Donut Chart + Legend + Clipboard Illustration - Image 3)
// ─────────────────────────────────────────────────────────────────────────────

class _GovernanceCard extends StatelessWidget {
  final OverviewModel overview;
  const _GovernanceCard({required this.overview});

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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFF1E60EB),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Governance Overview',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Donut Chart
              SizedBox(
                width: 100,
                height: 100,
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
                            fontSize: 24,
                            color: const Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Total',
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
              ),
              const SizedBox(width: 14),

              // 2. Legend Items
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GovLegendRow(
                      dotColor: const Color(0xFF1E60EB),
                      label: 'Pending',
                      count: overview.governancePending,
                    ),
                    const SizedBox(height: 11),
                    _GovLegendRow(
                      dotColor: const Color(0xFF22C55E),
                      label: 'Completed',
                      count: overview.governanceCompleted,
                    ),
                    const SizedBox(height: 11),
                    _GovLegendRow(
                      dotColor: const Color(0xFFEF4444),
                      label: 'Due',
                      count: overview.governanceDue,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Right side 3D illustration (Image 3)
              Image.asset(
                AppAssets.governanceClipboard,
                width: 105,
                height: 105,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GovLegendRow extends StatelessWidget {
  final Color dotColor;
  final String label;
  final int count;

  const _GovLegendRow({
    required this.dotColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
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
    const stroke = 15.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    if (total == 0) {
      paint.color = const Color(0xFFE2E8F0);
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, paint);
      return;
    }

    // Base background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFF1F5F9);
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    // Green segment at top-left (~ -0.65 pi)
    double start = -math.pi * 0.65;
    final segs = [
      (count: completed, color: const Color(0xFF22C55E)),
      (count: pending, color: const Color(0xFF1E60EB)),
      (count: due, color: const Color(0xFFEF4444)),
    ];
    for (final s in segs) {
      if (s.count == 0) continue;
      final sweep = 2 * math.pi * (s.count / total);
      paint.color = s.color;
      canvas.drawArc(rect, start, sweep - 0.05, false, paint);
      start += sweep;
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

class _ZonesCard extends StatefulWidget {
  final List<ZoneModel> zones;
  const _ZonesCard({required this.zones});

  @override
  State<_ZonesCard> createState() => _ZonesCardState();
}

class _ZonesCardState extends State<_ZonesCard> {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  zone.name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
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
            ],
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

class _ClustersCard extends StatefulWidget {
  final List<ClusterModel> clusters;
  const _ClustersCard({required this.clusters});

  @override
  State<_ClustersCard> createState() => _ClustersCardState();
}

class _ClustersCardState extends State<_ClustersCard> {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.name,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cluster.zoneName,
                      style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: _kBorder,
                size: 18,
              ),
            ],
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
// Recent Governance Activity
// ─────────────────────────────────────────────────────────────────────────────

class _RecentGovernanceCard extends StatelessWidget {
  final List<GovernanceListItemModel> items;
  const _RecentGovernanceCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _WCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 16, color: _kBlue),
                const SizedBox(width: 6),
                Text(
                  'Recent Governance Activity',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.secondary,
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
                  'No recent activities',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSlate),
                ),
              ),
            )
          else
            ...items.map((i) => _GovActivityRow(item: i)),
        ],
      ),
    );
  }
}

class _GovActivityRow extends StatelessWidget {
  final GovernanceListItemModel item;
  const _GovActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isPending = item.state.toLowerCase() == 'pending';
    return Column(
      children: [
        const Divider(height: 1, color: _kBorder),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
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
                      '${item.siteName}  ·  ${item.roleLabel}',
                      style: GoogleFonts.outfit(fontSize: 11, color: _kBlue),
                    ),
                    Text(
                      'Assignee: ${item.assigneeName}  ·  Due: ${item.dueDate}',
                      style: GoogleFonts.outfit(fontSize: 11, color: _kSlate),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.state,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPending ? _kBlue : _kGreen,
                  ),
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
