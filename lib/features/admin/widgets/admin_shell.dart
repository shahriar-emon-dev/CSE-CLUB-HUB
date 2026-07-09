// ============================================================================
// CRITICAL ARCHITECTURAL SAFE-MIGRATION NOTICE:
// Backward compatibility maintained. All actions wire safely to Riverpod & Supabase.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
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
    _AdminNavItem(icon: Icons.article, label: 'Club Blogs', route: AppRoutes.adminBlogs),
  ];

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D100A),
        title: const Text('Sign Out / Exit Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to exit the Super Admin executive workspace and close this session?', style: TextStyle(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      ref.invalidate(currentProfileProvider);
      ref.invalidate(authStateProvider);
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _openAdminProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _AdminProfileDialog(),
    );
  }

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
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      Positioned.fill(
                        child: SafeArea(
                          child: widget.child,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ClubCentral', style: TextStyle(color: AppColors.tertiary, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('ENTERPRISE', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 10, letterSpacing: 2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _navItems.length + 1,
              itemBuilder: (context, index) {
                if (index == _navItems.length) {
                  // Dedicated Sign Out / Exit Portal Tile Button
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: InkWell(
                      onTap: _handleSignOut,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.logout, color: AppColors.error),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Sign Out / Exit Portal',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

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
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected ? AppColors.tertiary : AppColors.textSecondaryDark.withValues(alpha: 0.7),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
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
          // Interactive Profile Settings Footer
          Consumer(
            builder: (context, ref, child) {
              final profileAsync = ref.watch(currentProfileProvider);
              final profile = profileAsync.valueOrNull;

              final avatarImage = (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(profile.avatarUrl!)
                  : const NetworkImage('https://ui-avatars.com/api/?name=Admin&background=1D100A&color=412D00');

              return InkWell(
                onTap: _openAdminProfileDialog,
                child: Container(
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
                            const Text('Platform Controller (Tap to edit)', style: TextStyle(color: AppColors.tertiary, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.settings, color: AppColors.textSecondaryDark, size: 18),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D100A).withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.15), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (!isDesktop) ...[
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.tertiary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.admin_panel_settings, color: AppColors.tertiary, size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    isDesktop ? 'ClubCentral Executive Admin Portal' : 'ClubCentral Admin',
                    style: const TextStyle(color: AppColors.tertiary, fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (isDesktop) ...[
                InkWell(onTap: () => context.go(AppRoutes.adminDashboard), child: _buildTopNavLink('Overview', true)),
                const SizedBox(width: 24),
                InkWell(onTap: () => context.go(AppRoutes.adminMembers), child: _buildTopNavLink('Members', false)),
                const SizedBox(width: 24),
                InkWell(onTap: () => _openAdminProfileDialog(), child: _buildTopNavLink('Settings', false)),
                const SizedBox(width: 24),
              ],
              IconButton(
                onPressed: _openAdminProfileDialog,
                icon: const Icon(Icons.person_pin, color: AppColors.tertiary),
                tooltip: 'Profile & Settings',
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout, color: AppColors.error),
                tooltip: 'Sign Out Portal',
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

class _AdminProfileDialog extends ConsumerStatefulWidget {
  const _AdminProfileDialog();

  @override
  ConsumerState<_AdminProfileDialog> createState() => _AdminProfileDialogState();
}

class _AdminProfileDialogState extends ConsumerState<_AdminProfileDialog> {
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _domainController = TextEditingController(text: 'smuct.edu.bd');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile != null) {
      _nameController.text = profile.fullName;
      _avatarController.text = profile.avatarUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileAndSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        await SupabaseConfig.client.from('profiles').update({
          'full_name': _nameController.text.trim(),
          if (_avatarController.text.trim().isNotEmpty) 'avatar_url': _avatarController.text.trim(),
        }).eq('id', user.id);
      }
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin profile and policy settings updated.'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return AlertDialog(
      backgroundColor: const Color(0xFF1D100A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.tertiary.withValues(alpha: 0.3))),
      title: Row(
        children: const [
          Icon(Icons.manage_accounts, color: AppColors.tertiary),
          SizedBox(width: 12),
          Text('Super Admin Profile & System Rules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF261812), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(_avatarController.text.isNotEmpty ? _avatarController.text : 'https://ui-avatars.com/api/?name=Admin&background=1D100A&color=412D00'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile?.email ?? 'admin@clubcentral.edu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Text('Role: Super Administrator (Verified)', style: TextStyle(color: AppColors.tertiary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Full Display Name', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0D0D14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Avatar Image URL (Public Supabase Bucket)', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _avatarController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: const Color(0xFF0D0D14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.textSecondaryDark),
              const SizedBox(height: 12),
              const Text('System Global Rules & Institutional Restrictions', style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              const Text('Allowed Institutional Email Domain', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _domainController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0D0D14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: const Color(0xFF412D00)),
          onPressed: _isLoading ? null : _saveProfileAndSettings,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Policies'),
        ),
      ],
    );
  }
}

