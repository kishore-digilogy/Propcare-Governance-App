import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import 'dashboard_page.dart';
import 'placeholder_page_view.dart';

enum NavMenuState {
  main,
  sites,
  activities,
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
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  NavMenuState _menuState = NavMenuState.main;
  int _activePageIndex = 0;

  // Pages index mapping:
  // 0: Dashboard
  // 1: All Sites
  // 2: Renewal Sites
  // 3: Create Site
  // 4: Transition & Start-Up
  // 5: My Activities
  // 6: Team Activities
  // 7: Attendance
  // 8: MOM & Email

  void _onSelectMainItem(int itemIndex) {
    if (itemIndex == 0) {
      // Dashboard
      setState(() {
        _activePageIndex = 0;
      });
    } else if (itemIndex == 1) {
      // Sites -> Expand Submenu & select All Sites (index 1)
      setState(() {
        _menuState = NavMenuState.sites;
        _activePageIndex = 1;
      });
    } else if (itemIndex == 2) {
      // Activities -> Expand Submenu & select My Activities (index 5)
      setState(() {
        _menuState = NavMenuState.activities;
        _activePageIndex = 5;
      });
    } else if (itemIndex == 3) {
      // Attendance
      setState(() {
        _activePageIndex = 7;
      });
    } else if (itemIndex == 4) {
      // MOM & Email
      setState(() {
        _activePageIndex = 8;
      });
    }
  }

  void _onBackToMain() {
    setState(() {
      _menuState = NavMenuState.main;
      // return to dashboard or stay on current if appropriate
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
            isSelected: _activePageIndex >= 1 && _activePageIndex <= 4,
            onTap: () => _onSelectMainItem(1),
          ),
          NavItemData(
            label: 'Activities',
            icon: Icons.assignment_rounded,
            isSelected: _activePageIndex == 5 || _activePageIndex == 6,
            onTap: () => _onSelectMainItem(2),
          ),
          NavItemData(
            label: 'Attendance',
            icon: Icons.calendar_today_rounded,
            isSelected: _activePageIndex == 7,
            onTap: () => _onSelectMainItem(3),
          ),
          NavItemData(
            label: 'MOM & Mail',
            icon: Icons.mail_outline_rounded,
            isSelected: _activePageIndex == 8,
            onTap: () => _onSelectMainItem(4),
          ),
        ];

      case NavMenuState.sites:
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
            label: 'Create',
            icon: Icons.add_business_rounded,
            isSelected: _activePageIndex == 3,
            onTap: () => setState(() => _activePageIndex = 3),
          ),
          NavItemData(
            label: 'Transition',
            icon: Icons.swap_horiz_rounded,
            isSelected: _activePageIndex == 4,
            onTap: () => setState(() => _activePageIndex = 4),
          ),
        ];

      case NavMenuState.activities:
        return [
          NavItemData(
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            isBack: true,
            isSelected: false,
            onTap: _onBackToMain,
          ),
          NavItemData(
            label: 'My Activities',
            icon: Icons.person_outline_rounded,
            isSelected: _activePageIndex == 5,
            onTap: () => setState(() => _activePageIndex = 5),
          ),
          NavItemData(
            label: 'Team',
            icon: Icons.groups_rounded,
            isSelected: _activePageIndex == 6,
            onTap: () => setState(() => _activePageIndex = 6),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _buildCurrentNavItems();

    return Scaffold(
      body: IndexedStack(
        index: _activePageIndex,
        children: const [
          DashboardPage(),
          PlaceholderPageView(
            title: 'All Sites',
            parentTitle: 'Sites',
            icon: Icons.domain_rounded,
          ),
          PlaceholderPageView(
            title: 'Renewal Sites',
            parentTitle: 'Sites',
            icon: Icons.history_rounded,
          ),
          PlaceholderPageView(
            title: 'Create Site',
            parentTitle: 'Sites',
            icon: Icons.add_business_rounded,
          ),
          PlaceholderPageView(
            title: 'Transition & Start-Up',
            parentTitle: 'Sites',
            icon: Icons.swap_horiz_rounded,
          ),
          PlaceholderPageView(
            title: 'My Activities',
            parentTitle: 'Activities',
            icon: Icons.person_outline_rounded,
          ),
          PlaceholderPageView(
            title: 'Team Activities',
            parentTitle: 'Activities',
            icon: Icons.groups_rounded,
          ),
          PlaceholderPageView(
            title: 'Attendance',
            parentTitle: 'Governance',
            icon: Icons.calendar_today_rounded,
          ),
          PlaceholderPageView(
            title: 'MOM & Email',
            parentTitle: 'Governance',
            icon: Icons.mail_outline_rounded,
          ),
        ],
      ),
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
            height: 64,
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

