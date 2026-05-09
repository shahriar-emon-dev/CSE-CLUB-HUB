import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/main_bottom_nav.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/stats_card.dart';
import '../../../../shared/widgets/user_row.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/profile_edit_modal.dart';

class ProfileDashboardScreen extends ConsumerWidget {
  const ProfileDashboardScreen({super.key});

  String _initialsFrom(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile;
    final roleLabel = switch (authState.role) {
      AppUserRole.admin => 'Admin',
      AppUserRole.executive => 'Executive',
      AppUserRole.student => 'Student',
    };

    final displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : 'Your Name';
    final displayEmail = profile?.email.isNotEmpty == true
        ? profile!.email
        : authState.user?.email ?? 'student@smuct.edu';
    final displayStudentId = profile?.studentId?.trim().isNotEmpty == true
        ? profile!.studentId!.trim()
        : '—';
    final displayBatch = profile?.batch?.trim().isNotEmpty == true
        ? profile!.batch!.trim()
        : '—';
    final displaySection = profile?.section?.trim().isNotEmpty == true
        ? profile!.section!.trim()
        : '—';
    final displayDepartment = profile?.department?.trim().isNotEmpty == true
      ? profile!.department!.trim()
      : 'CSE';
    final displayAvatarUrl = profile?.avatarUrl?.trim().isNotEmpty == true ? profile!.avatarUrl!.trim() : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(
                    title: 'Profile Dashboard',
                    subtitle: 'Manage your student identity and club activity.',
                    trailing: const Icon(
                      Icons.account_circle_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFFFFBF5)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.inputBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.cta.withValues(alpha: 0.18), width: 4),
                                    ),
                                    child: AvatarWidget(
                                      fallbackLabel: _initialsFrom(displayName),
                                      imageUrl: displayAvatarUrl,
                                      size: 90,
                                      backgroundColor: AppColors.cta.withValues(alpha: 0.14),
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.cta,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.school_outlined,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      displayEmail,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _initialsFrom(displayName) == '?' ? 'Profile details will appear here' : _joinedLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        RoleBadge(
                                          label: roleLabel,
                                          icon: Icons.workspace_premium_outlined,
                                        ),
                                        RoleBadge(
                                          label: 'Department: $displayDepartment',
                                          icon: Icons.school_outlined,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _ProfileOverviewTile(
                            studentId: displayStudentId,
                            batch: displayBatch,
                            section: displaySection,
                            department: displayDepartment,
                          ),
                          const SizedBox(height: 14),
                          _IdentityGrid(
                            studentId: displayStudentId,
                            batch: displayBatch,
                            section: displaySection,
                            department: displayDepartment,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AppHeader(
                    title: 'Your Activity',
                    subtitle: 'At a glance, your following and engagement stats.',
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 2 : 1;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 2.5 : 1.8,
                        children: const [
                          StatsCard(
                            label: 'Clubs followed',
                            value: '0',
                            icon: Icons.groups_2_outlined,
                          ),
                          StatsCard(
                            label: 'Events attended',
                            value: '0',
                            icon: Icons.event_available_outlined,
                          ),
                          StatsCard(
                            label: 'Posts liked',
                            value: '0',
                            icon: Icons.favorite_border,
                          ),
                          StatsCard(
                            label: 'Notifications',
                            value: '0',
                            icon: Icons.notifications_none,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: 'Edit Profile',
                          icon: Icons.edit_outlined,
                          isPrimary: true,
                          onPressed: () async {
                            await showProfileEditModal(
                              context,
                              name: displayName,
                              studentId: displayStudentId,
                              batch: displayBatch,
                              section: displaySection,
                              department: displayDepartment,
                              avatarUrl: displayAvatarUrl,
                            );

                            ref.invalidate(authNotifierProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Students can only view profile information here. Executive and admin controls stay on their dedicated dashboards.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Logout',
                    icon: Icons.logout,
                    onPressed: () async {
                      final shouldLogout = await showConfirmActionDialog(
                        context,
                        title: 'Logout from profile dashboard?',
                        message: 'You will be signed out from the current session.',
                        confirmLabel: 'Logout',
                        isDestructive: true,
                      );

                      if (shouldLogout != true) return;

                      await ref.read(authNotifierProvider.notifier).signOut();
                      ref.invalidate(authNotifierProvider);
                      ref.invalidate(authSessionProvider);

                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(
        activeRoute: AppRoutes.profileDashboard,
      ),
    );
  }
}

class _ProfileOverviewTile extends StatelessWidget {
  const _ProfileOverviewTile({
    required this.studentId,
    required this.batch,
    required this.section,
    required this.department,
  });

  final String studentId;
  final String batch;
  final String section;
  final String department;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: AppColors.cta, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Student ID $studentId • Batch $batch • Section $section • $department',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityGrid extends StatelessWidget {
  const _IdentityGrid({
    required this.studentId,
    required this.batch,
    required this.section,
    required this.department,
  });

  final String studentId;
  final String batch;
  final String section;
  final String department;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 2 : 1;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 3.8 : 2.1,
          children: [
            _IdentityTile(label: 'Student ID', value: studentId),
            _IdentityTile(label: 'Batch', value: batch),
            _IdentityTile(label: 'Section', value: section),
            _IdentityTile(label: 'Department', value: department),
          ],
        );
      },
    );
  }
}

class _IdentityTile extends StatelessWidget {
  const _IdentityTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
