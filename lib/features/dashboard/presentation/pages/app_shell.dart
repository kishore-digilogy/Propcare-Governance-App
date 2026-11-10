import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../activities/presentation/pages/activities_page.dart';
import '../../../activities/presentation/pages/checklist_report_page.dart';
import '../../../activities/presentation/pages/mmr_mis_page.dart';
import '../../../activities/presentation/pages/rr_page.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../issues/presentation/pages/issues_page.dart';
import '../../../mom/presentation/pages/mom_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../sites/presentation/pages/all_sites_page.dart';
import '../../../sites/presentation/pages/renewal_sites_page.dart';
import '../../../sites/presentation/pages/transition_sites_page.dart';
import 'dashboard_page.dart';
import 'placeholder_page_view.dart';

enum NavMenuState {
  main,
  sites,
  governance,
}

class NavItemData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isBack;

  const NavItemData({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.isBack = false,
  });
}

class AppShell extends StatefulWidget {
  final List<Widget>? pages;
  final int initialPageIndex;
  const AppShell({super.key, this.pages, this.initialPageIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  NavMenuState _menuState = NavMenuState.main;
  late int _activePageIndex;
  bool _isSidebarCollapsed = false;
  bool _sitesExpanded = true;
  bool _governanceExpanded = true;

  @override
  void initState() {
    super.initState();
    _activePageIndex = widget.initialPageIndex;
  }

  // Pages index mapping:
  // 0: Dashboard
  // 1: All Sites
  // 2: Renewal Sites
  // 3: Draft Sites (AllSitesPage(initialStatus: 'DRAFT'))
  // 4: Transition & Start-Up
  // 5: Create Site
  // 6: My Governance (ActivitiesPage(isTeam: false))
  // 7: Team Governance (ActivitiesPage(isTeam: true))
  // 8: Attendance
  // 9: Reports
  // 10: MOM & Email
  // 11: Training
  // 12: Checklist Report
  // 13: MMR / MIS
  // 14: R&R
  // 15: Issues

  void _onSelectMainItem(int itemIndex) {
    if (itemIndex == 0) {
      setState(() => _activePageIndex = 0);
    } else if (itemIndex == 1) {
      setState(() {
        _menuState = NavMenuState.sites;
        _activePageIndex = 1;
      });
    } else if (itemIndex == 2) {
      setState(() {
        _menuState = NavMenuState.governance;
        _activePageIndex = 6;
      });
    } else if (itemIndex == 3) {
      setState(() => _activePageIndex = 8);
    } else if (itemIndex == 4) {
      setState(() => _activePageIndex = 9);
    }
  }

  void _onBackToMain() {
    setState(() {
      _menuState = NavMenuState.main;
    });
  }

  List<NavItemData> _buildCurrentNavItems() {
    switch (_menuState) {
      case NavMenuState.main:
        return [
          NavItemData(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            isSelected: _activePageIndex == 0,
            onTap: () => _onSelectMainItem(0),
          ),
          NavItemData(
            label: 'Sites',
            icon: Icons.apartment_rounded,
            isSelected: _activePageIndex >= 1 && _activePageIndex <= 5,
            onTap: () => _onSelectMainItem(1),
          ),
          NavItemData(
            label: 'Governance',
            icon: Icons.verified_outlined,
            isSelected: _activePageIndex == 6 || _activePageIndex == 7,
            onTap: () => _onSelectMainItem(2),
          ),
          NavItemData(
            label: 'Attendance',
            icon: Icons.calendar_today_rounded,
            isSelected: _activePageIndex == 8,
            onTap: () => _onSelectMainItem(3),
          ),
          NavItemData(
            label: 'Reports',
            icon: Icons.bar_chart_rounded,
            isSelected: _activePageIndex == 9,
            onTap: () => _onSelectMainItem(4),
          ),
        ];

      case NavMenuState.sites:
        final isSuperAdmin = HiveStorage.isSuperAdmin;

        return [
          NavItemData(
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            isBack: true,
            isSelected: false,
            onTap: _onBackToMain,
          ),
          NavItemData(
            label: 'All Sites',
            icon: Icons.domain_rounded,
            isSelected: _activePageIndex == 1,
            onTap: () => setState(() => _activePageIndex = 1),
          ),
          NavItemData(
            label: 'Renewals',
            icon: Icons.history_rounded,
            isSelected: _activePageIndex == 2,
            onTap: () => setState(() => _activePageIndex = 2),
          ),
          NavItemData(
            label: 'Draft Sites',
            icon: Icons.edit_note_rounded,
            isSelected: _activePageIndex == 3,
            onTap: () => setState(() => _activePageIndex = 3),
          ),
          if (isSuperAdmin)
            NavItemData(
              label: 'Transition',
              icon: Icons.swap_horiz_rounded,
              isSelected: _activePageIndex == 4,
              onTap: () => setState(() => _activePageIndex = 4),
            ),
        ];

      case NavMenuState.governance:
        return [
          NavItemData(
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            isBack: true,
            isSelected: false,
            onTap: _onBackToMain,
          ),
          NavItemData(
            label: 'My Governance',
            icon: Icons.person_outline_rounded,
            isSelected: _activePageIndex == 6,
            onTap: () => setState(() => _activePageIndex = 6),
          ),
          NavItemData(
            label: 'Team Governance',
            icon: Icons.groups_rounded,
            isSelected: _activePageIndex == 7,
            onTap: () => setState(() => _activePageIndex = 7),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isTabletOrDesktop = media.size.shortestSide >= 700 || media.size.width >= 960;

    final pagesWidget = IndexedStack(
      index: _activePageIndex,
      children: widget.pages ??
          const [
            DashboardPage(), // 0
            AllSitesPage(), // 1
            RenewalSitesPage(), // 2
            AllSitesPage(initialStatus: 'DRAFT'), // 3
            TransitionSitesPage(), // 4
            PlaceholderPageView( // 5
              title: 'Create Site',
              parentTitle: 'Sites',
              icon: Icons.add_business_rounded,
            ),
            ActivitiesPage(isTeam: false), // 6
            ActivitiesPage(isTeam: true), // 7
            AttendancePage(), // 8
            ReportsPage(), // 9
            MomPage(), // 10
            PlaceholderPageView( // 11
              title: 'Training',
              parentTitle: 'L&D',
              icon: Icons.school_outlined,
            ),
            ChecklistReportPage(), // 12
            MmrMisPage(), // 13
            RrPage(), // 14
            IssuesPage(), // 15
          ],
    );

    if (isTabletOrDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Row(
            children: [
              _buildTabletSidebar(),
              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Expanded(child: pagesWidget),
            ],
          ),
        ),
      );
    }

    final navItems = _buildCurrentNavItems();

    return Scaffold(
      body: pagesWidget,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE8EDF2), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: media.orientation == Orientation.landscape ? 54 : 64,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 0.25),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Row(
                key: ValueKey<NavMenuState>(_menuState),
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navItems.map((item) {
                  return Expanded(
                    child: _BottomNavItemWidget(
                      item: item,
                      isInSubMenu: _menuState != NavMenuState.main,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── iPad / Tablet Sidebar Navigation ───────────────────────────────────────
  Widget _buildTabletSidebar() {
    final isSuperAdmin = HiveStorage.isSuperAdmin;
    final width = _isSidebarCollapsed ? 76.0 : 252.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: width,
      color: Colors.white,
      child: Column(
        children: [
          // Sidebar Header
          Container(
            height: 68,
            padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 8 : 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: _isSidebarCollapsed
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      tooltip: 'Expand sidebar',
                      onPressed: () {
                        setState(() {
                          _isSidebarCollapsed = false;
                        });
                      },
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/icons/gov_icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.apartment_rounded,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PropCare',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'Governance',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_double_arrow_left_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        tooltip: 'Collapse sidebar',
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = true;
                          });
                        },
                      ),
                    ],
                  ),
          ),

          // Scrollable Sidebar Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _buildSidebarTile(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  pageIndex: 0,
                ),
                const SizedBox(height: 4),

                // Sites Expandable Group
                _buildSidebarGroup(
                  label: 'Sites',
                  icon: Icons.apartment_rounded,
                  isExpanded: _sitesExpanded,
                  onToggle: () => setState(() => _sitesExpanded = !_sitesExpanded),
                  children: [
                    _buildSidebarChildTile(label: 'All Sites', pageIndex: 1),
                    _buildSidebarChildTile(label: 'Renewal Sites', pageIndex: 2, badge: '5', badgeColor: const Color(0xFFFEF3C7), badgeTextColor: const Color(0xFFD97706)),
                    _buildSidebarChildTile(label: 'Draft Sites', pageIndex: 3, badge: '5', badgeColor: const Color(0xFFFEF3C7), badgeTextColor: const Color(0xFFD97706)),
                    _buildSidebarChildTile(label: 'Create Site', pageIndex: 5),
                  ],
                ),
                const SizedBox(height: 4),

                if (isSuperAdmin) ...[
                  _buildSidebarTile(
                    icon: Icons.sync_alt_rounded,
                    label: 'Transition',
                    pageIndex: 4,
                  ),
                  const SizedBox(height: 4),
                ],

                // Governance Expandable Group
                _buildSidebarGroup(
                  label: 'Governance',
                  icon: Icons.assignment_outlined,
                  isExpanded: _governanceExpanded,
                  onToggle: () => setState(() => _governanceExpanded = !_governanceExpanded),
                  children: [
                    _buildSidebarChildTile(label: 'My Governance', pageIndex: 6, badge: '8', badgeColor: const Color(0xFFDBEAFE), badgeTextColor: const Color(0xFF2563EB)),
                    _buildSidebarChildTile(label: 'Team Governance', pageIndex: 7),
                  ],
                ),
                const SizedBox(height: 4),

                _buildSidebarTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Attendance',
                  pageIndex: 8,
                ),
                const SizedBox(height: 4),

                _buildSidebarTile(
                  icon: Icons.mail_outline_rounded,
                  label: 'MOM & Email',
                  pageIndex: 10,
                  badge: '3',
                  badgeColor: const Color(0xFFFEE2E2),
                  badgeTextColor: const Color(0xFFDC2626),
                ),
                const SizedBox(height: 4),

                _buildSidebarTile(
                  icon: Icons.fact_check_outlined,
                  label: 'Checklist Report',
                  pageIndex: 12,
                ),
                const SizedBox(height: 4),

                _buildSidebarTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'MMR / MIS',
                  pageIndex: 13,
                ),
                const SizedBox(height: 4),

                _buildSidebarTile(
                  icon: Icons.military_tech_outlined,
                  label: 'R&R',
                  pageIndex: 14,
                ),
                const SizedBox(height: 4),

                _buildSidebarTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Issues',
                  pageIndex: 15,
                ),
                const SizedBox(height: 4),

                _buildSidebarTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  pageIndex: 9,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String label,
    required int pageIndex,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    final isSelected = _activePageIndex == pageIndex;
    final primaryColor = const Color(0xFF2563EB);

    if (_isSidebarCollapsed) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: () => setState(() => _activePageIndex = pageIndex),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? primaryColor : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => setState(() => _activePageIndex = pageIndex),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primaryColor : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryColor : const Color(0xFF334155),
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor ?? primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarGroup({
    required String label,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    if (_isSidebarCollapsed) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: () {
            setState(() {
              _isSidebarCollapsed = false;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF64748B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Stack(
              children: [
                Positioned(
                  left: 2,
                  top: 0,
                  bottom: 8,
                  child: Container(
                    width: 1.5,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                Column(children: children),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarChildTile({
    required String label,
    required int pageIndex,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    final isSelected = _activePageIndex == pageIndex;
    final primaryColor = const Color(0xFF2563EB);

    return InkWell(
      onTap: () => setState(() => _activePageIndex = pageIndex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.only(left: 18, right: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryColor : const Color(0xFF475569),
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor ?? primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItemWidget extends StatelessWidget {
  final NavItemData item;
  final bool isInSubMenu;

  const _BottomNavItemWidget({
    required this.item,
    required this.isInSubMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = item.isSelected;
    final isBack = item.isBack;

    final activeColor = isBack ? const Color(0xFFE11D48) : AppColors.primary;
    final inactiveColor = const Color(0xFF64748B);

    return InkWell(
      onTap: item.onTap,
      splashColor: activeColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 0,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : (isBack ? const Color(0xFFFFF1F2) : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: isSelected ? activeColor : (isBack ? activeColor : inactiveColor),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isSelected || isBack ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : (isBack ? activeColor : inactiveColor),
            ),
          ),
        ],
      ),
    );
  }
}
