import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/event_card_widget.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/modal_dialog.dart';
import '../../../../shared/widgets/post_card_widget.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';

class ExecutiveDashboardScreen extends StatelessWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    title: 'Executive Dashboard',
                    subtitle: 'Operate your club with posts, events, and branding.',
                    trailing: const RoleBadge(
                      label: 'Executive',
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 3 : 1;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 3.7 : 1.5,
                        children: const [
                          StatsCard(
                            label: 'Total posts',
                            value: '128',
                            icon: Icons.post_add_outlined,
                          ),
                          StatsCard(
                            label: 'Total events',
                            value: '24',
                            icon: Icons.event_outlined,
                          ),
                          StatsCard(
                            label: 'Followers',
                            value: '2.4K',
                            icon: Icons.groups_2_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Create content and updates from one place.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: 'Create Post',
                          icon: Icons.post_add_outlined,
                          isPrimary: true,
                          onPressed: () => _showActionDialog(
                            context,
                            title: 'Create Post',
                            message: 'Hook this action to the existing post creation flow when available.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          label: 'Create Event',
                          icon: Icons.event_available_outlined,
                          onPressed: () => _showActionDialog(
                            context,
                            title: 'Create Event',
                            message: 'This is a UI-only action. Connect it to your event workflow later.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Manage Posts',
                    subtitle: 'Pin, edit, or delete posts for your club.',
                  ),
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'CSE Club',
                    club: 'Executive Feed',
                    content: 'Tech talk this Friday with limited seats. Register from the events tab.',
                    timestamp: 'Pinned',
                  ),
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'CSE Club',
                    club: 'Executive Feed',
                    content: 'New mentorship program applications are now open for first-year students.',
                    timestamp: '2h ago',
                  ),
                  const SizedBox(height: 12),
                  ActionButton(
                    label: 'Edit / Delete / Pin',
                    icon: Icons.tune,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Manage Events',
                    subtitle: 'Keep your club calendar current and easy to scan.',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Tech Talk: AI in Campus Life',
                    date: '22 Apr • 3:00 PM',
                    venue: 'Auditorium A',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Project Showcase',
                    date: '29 Apr • 11:00 AM',
                    venue: 'Innovation Lab',
                  ),
                  const SizedBox(height: 12),
                  ActionButton(
                    label: 'Edit / Cancel',
                    icon: Icons.edit_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Club Management',
                    subtitle: 'Update branding, messaging, and club details.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSE Club',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Logo, cover image, and description editor placeholders are ready for the connected form.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Empty State Preview',
                    subtitle: 'Useful when no moderation items are waiting.',
                  ),
                  const SizedBox(height: 12),
                  const EmptyState(
                    title: 'No pending executive tasks',
                    message: 'Everything looks up to date. New posts, events, or reports will appear here.',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Loading State Preview',
                    subtitle: 'Reusable skeletons for future async data.',
                  ),
                  const SizedBox(height: 12),
                  const LoadingSkeleton(height: 96),
                  const SizedBox(height: 12),
                  const LoadingSkeleton(height: 96),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ModalDialog(
          title: title,
          message: message,
          primaryLabel: 'Close',
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(),
          icon: Icons.info_outline,
        );
      },
    );
  }
}
