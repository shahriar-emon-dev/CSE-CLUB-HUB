import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final List<_AdminNavItem> _navItems = [
    _AdminNavItem(icon: Icons.dashboard, label: 'System Overview', route: AppRoutes.adminDashboard),
    _AdminNavItem(icon: Icons.groups, label: 'Member Management', route: AppRoutes.adminMembers),
    _AdminNavItem(icon: Icons.gavel, label: 'Content Moderation', route: AppRoutes.adminModeration),
    _AdminNavItem(icon: Icons.receipt_long, label: 'Audit Logs', route: ''),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final currentRoute = GoRouterState.of(context).fullPath ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(currentRoute)),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 288, // w-72
              child: _buildSidebar(currentRoute),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(isDesktop, context),
                Expanded(
                  child: Stack(
                    children: [
                      // Atmospheric Shader Layer
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.2,
                          child: Container(color: Colors.transparent), // mock shader
                        ),
                      ),
                      widget.child,
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

  Widget _buildSidebar(String currentRoute) {
    return Container(
      color: const Color(0xFF1D100A), // surface-dim
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.tertiary, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.5), blurRadius: 10)]),
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFF412D00)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('ClubCentral', style: TextStyle(color: AppColors.tertiary, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('ENTERPRISE', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 10, letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),
          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = currentRoute == item.route || (item.route.isNotEmpty && currentRoute.startsWith(item.route) && item.route != AppRoutes.adminDashboard);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: item.route.isNotEmpty ? () {
                      if (MediaQuery.of(context).size.width < 1024) Navigator.pop(context);
                      context.go(item.route);
                    } : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.tertiaryContainer.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? const Border(left: BorderSide(color: AppColors.tertiary, width: 4)) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, color: isSelected ? AppColors.tertiary : AppColors.textSecondaryDark.withValues(alpha: 0.7)),
                          const SizedBox(width: 16),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? AppColors.tertiary : AppColors.textSecondaryDark.withValues(alpha: 0.7),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Profile Footer
          Consumer(
            builder: (context, ref, child) {
              final profileAsync = ref.watch(currentProfileProvider);
              final profile = profileAsync.valueOrNull;

              final avatarImage = (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(profile.avatarUrl!)
                  : const NetworkImage('https://ui-avatars.com/api/?name=Admin&background=1D100A&color=412D00');

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: avatarImage as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.fullName ?? 'Super Admin', 
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text('Platform Controller', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(bool isDesktop, BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1D100A).withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.15), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.tertiary),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (isDesktop) ...[
                const Icon(Icons.admin_panel_settings, color: AppColors.tertiary, size: 24),
                const SizedBox(width: 16),
                const Text('ClubCentral Admin', style: TextStyle(color: AppColors.tertiary, fontSize: 24, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          Row(
            children: [
              if (isDesktop) ...[
                _buildTopNavLink('Overview', true),
                const SizedBox(width: 32),
                _buildTopNavLink('Management', false),
                const SizedBox(width: 32),
                _buildTopNavLink('Reports', false),
                const SizedBox(width: 32),
              ],
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.notifications, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavLink(String label, bool isSelected) {
    return Text(
      label,
      style: TextStyle(
        color: isSelected ? AppColors.tertiary : AppColors.textSecondaryDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
      ),
    );
  }
}

class _AdminNavItem {
  final IconData icon;
  final String label;
  final String route;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
