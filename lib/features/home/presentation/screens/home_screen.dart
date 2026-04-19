import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/club_card_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/event_card_widget.dart';
import '../../../../shared/widgets/post_card_widget.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/confirm_action_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final role = authState.role;
    final requestedExecutive = authState.profile?.roleRequest ?? false;
    final profile = authState.profile;

    final roleLabel = switch (role) {
      AppUserRole.admin => 'Admin',
      AppUserRole.executive => 'Executive',
      AppUserRole.student => 'Student',
    };

    final canCreate =
        role == AppUserRole.executive || role == AppUserRole.admin;
    final isAdmin = role == AppUserRole.admin;
    final displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : user?.email?.split('@').first ?? 'Student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CSE Club Hub'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(
                    title: 'Welcome back, $displayName',
                    subtitle: 'Role: $roleLabel • stay on top of your club activity.',
                    trailing: const RoleBadge(
                      label: 'Live',
                      icon: Icons.bolt,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientMiddle,
                          AppColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'CSE Club Hub',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Your feed, events, clubs, and admin tools in one polished workspace.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.dashboard_customize_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 500 ? 3 : 2;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: columns,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: columns == 2 ? 2.1 : 1.7,
                              children: const [
                                _MiniStat(label: 'Clubs', value: '6'),
                                _MiniStat(label: 'Events', value: '24'),
                                _MiniStat(label: 'Posts', value: '128'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (requestedExecutive && role == AppUserRole.student)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: const Text(
                        'Executive request is pending admin approval.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  if (requestedExecutive && role == AppUserRole.student)
                    const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Quick Access',
                    subtitle: 'Jump to the most common destinations.',
                  ),
                  const SizedBox(height: 12),
                  _QuickActionGrid(
                    isAdmin: isAdmin,
                    canCreate: canCreate,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Your Profile',
                    subtitle: 'A compact summary of your student identity.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 120,
                          child: StatsCard(
                            label: 'Batch',
                            value: profile?.batch ?? '—',
                            icon: Icons.class_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 120,
                          child: StatsCard(
                            label: 'Section',
                            value: profile?.section ?? '—',
                            icon: Icons.segment,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SectionHeader(
                    title: 'Featured Feed',
                    subtitle: 'A few recent club updates to keep the home screen lively.',
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'Web Development Club',
                    club: 'Web Club',
                    content: 'React meetup slides are now available for members.',
                    timestamp: '10h ago',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Recommended Clubs',
                    subtitle: 'Follow clubs to personalize your feed.',
                  ),
                  const SizedBox(height: 12),
                  ClubCardWidget(
                    name: 'Machine Learning Club',
                    description: 'AI, data science, and deep learning community.',
                    isFollowing: true,
                    onTap: _noop,
                  ),
                  const SizedBox(height: 12),
                  ClubCardWidget(
                    name: 'Cyber Security Club',
                    description: 'Security, ethical hacking, and cryptography.',
                    onTap: _noop,
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Upcoming Events',
                    subtitle: 'Events that matter to your campus life.',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Flutter UI Bootcamp',
                    date: 'Apr 20, 2026 - 3:00 PM',
                    venue: 'SMUCT Lab 2',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Cyber Security Talk',
                    date: 'Apr 24, 2026 - 11:00 AM',
                    venue: 'Auditorium',
                  ),
                  const SizedBox(height: 16),
                  const EmptyState(
                    title: 'No more updates right now',
                    message: 'New posts, events, and notifications will appear here as clubs publish them.',
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Logout',
                    icon: Icons.logout,
                    onPressed: () async {
                      final shouldLogout = await showConfirmActionDialog(
                        context,
                        title: 'Log out of your account?',
                        message: 'You will need to sign in again to continue using the app.',
                        confirmLabel: 'Logout',
                        isDestructive: true,
                      );

                      if (shouldLogout != true) return;
                      ref.read(authNotifierProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(action.route),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.cta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: AppColors.cta),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
