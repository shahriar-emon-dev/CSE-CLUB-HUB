import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

// ==========================================
// MAIN BOTTOM NAVIGATION
// ==========================================

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    required this.activeRoute,
    super.key,
  });

  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: const <Widget>[
            Expanded(
              child: _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                route: AppRoutes.home,
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Search',
                icon: Icons.search,
                route: AppRoutes.search,
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Clubs',
                icon: Icons.groups_2_outlined,
                route: AppRoutes.clubs,
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Events',
                icon: Icons.event_outlined,
                route: AppRoutes.events,
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Profile',
                icon: Icons.person_outline,
                route: AppRoutes.profileDashboard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<MainBottomNav>();
    final isActive = parent?.activeRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isActive) return;
            context.go(route);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.cta : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
