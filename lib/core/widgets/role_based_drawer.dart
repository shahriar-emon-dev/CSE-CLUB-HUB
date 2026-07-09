import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../router/app_router.dart';
import '../../features/auth/providers/auth_provider.dart';

class RoleBasedDrawer extends ConsumerWidget {
  const RoleBasedDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Drawer(
      backgroundColor: const Color(0xFF0D0D14),
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                const Text('Authorization Error', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(err.toString(), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentProfileProvider),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Retry Connection'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                  child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerDark,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.hub_rounded, color: AppColors.primary, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      profile?.fullName ?? 'ClubHub User',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      profile?.email ?? '',
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (profile != null && profile.isAdmin) ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('ADMINISTRATION', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_rounded, color: Colors.white70),
                  title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_rounded, color: Colors.white70),
                  title: const Text('Role Assignment', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/members');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.gavel_rounded, color: Colors.white70),
                  title: const Text('Content Moderation', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/moderation');
                  },
                ),
                const Divider(color: Colors.white10),
              ],
              if (profile != null && (profile.isExecutive || profile.isAdmin)) ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('EXECUTIVE TOOLS', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                ListTile(
                  leading: const Icon(Icons.post_add_rounded, color: Colors.white70),
                  title: const Text('Create Post', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/post/create');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_available_rounded, color: Colors.white70),
                  title: const Text('Event Management', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/events/create');
                  },
                ),
                const Divider(color: Colors.white10),
              ],
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white70),
                title: const Text('My Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded, color: Colors.white70),
                title: const Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.editProfile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authNotifierProvider.notifier).signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
