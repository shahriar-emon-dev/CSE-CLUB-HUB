import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/post_card_widget.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/primary_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final role = authState.role;
    final requestedExecutive = authState.profile?.roleRequest ?? false;

    final roleLabel = switch (role) {
      AppUserRole.admin => 'Admin',
      AppUserRole.executive => 'Executive',
      AppUserRole.student => 'Student',
    };

    final canCreate =
        role == AppUserRole.executive || role == AppUserRole.admin;
    final isAdmin = role == AppUserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CSE Club Hub'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppHeader(
            title: 'Welcome, ${user?.email ?? 'Student'}',
            subtitle: 'Role: $roleLabel',
          ),
          const SizedBox(height: 12),
          if (requestedExecutive && role == AppUserRole.student)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Executive request is pending admin approval.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _QuickActionGrid(
            isAdmin: isAdmin,
            canCreate: canCreate,
          ),
          const SizedBox(height: 16),
          const Text(
            'Home Feed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const PostCardWidget(
            author: 'Machine Learning Club',
            club: 'ML Club',
            content: 'This week: Intro to CNNs and hands-on model training session.',
            timestamp: '3h ago',
          ),
          const SizedBox(height: 12),
          const PostCardWidget(
            author: 'IoT & Robotics Club',
            club: 'IoT Club',
            content: 'Build challenge: Smart attendance tracker using ESP32.',
            timestamp: '6h ago',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Logout',
            isLoading: authState.isLoading,
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.cta,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.isAdmin,
    required this.canCreate,
  });

  final bool isAdmin;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionItem>[
      const _QuickActionItem(
        title: 'Clubs',
        icon: Icons.groups_2_outlined,
        route: AppRoutes.clubs,
      ),
      const _QuickActionItem(
        title: 'Events',
        icon: Icons.event_outlined,
        route: AppRoutes.events,
      ),
      const _QuickActionItem(
        title: 'Profile',
        icon: Icons.account_circle_outlined,
        route: AppRoutes.profileDashboard,
      ),
      const _QuickActionItem(
        title: 'Notifications',
        icon: Icons.notifications_none,
        route: AppRoutes.notifications,
      ),
      if (canCreate)
        const _QuickActionItem(
          title: 'Executive',
          icon: Icons.workspace_premium_outlined,
          route: AppRoutes.executiveDashboard,
        ),
      if (isAdmin)
        const _QuickActionItem(
          title: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          route: AppRoutes.adminPanel,
        ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(action.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(action.icon, color: AppColors.cta),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String route;
}
