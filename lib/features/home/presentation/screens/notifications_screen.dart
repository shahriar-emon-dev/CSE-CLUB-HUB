import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';
import '../widgets/confirm_action_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
                  const AppHeader(
                    title: 'Notifications',
                    subtitle: 'Stay informed with posts, events, and role updates.',
                    trailing: RoleBadge(
                      label: 'Inbox',
                      icon: Icons.notifications_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 2 : 1;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 3.6 : 2.0,
                        children: const [
                          StatsCard(label: 'Unread', value: '3', icon: Icons.mark_email_unread_outlined),
                          StatsCard(label: 'Total', value: '12', icon: Icons.notifications_none),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Unread', 'Read']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: _selectedFilter == value,
                            onSelected: (_) => setState(() => _selectedFilter = value),
                            selectedColor: AppColors.cta.withValues(alpha: 0.12),
                            labelStyle: TextStyle(
                              color: _selectedFilter == value ? AppColors.cta : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Latest notifications',
                    subtitle: 'Unread notifications stay visually distinct for quick scanning.',
                  ),
                  const SizedBox(height: 12),
                  _NotificationTile(
                    title: 'New post from Machine Learning Club',
                    subtitle: 'AI workshop materials uploaded.',
                    isUnread: true,
                  ),
                  _NotificationTile(
                    title: 'Event reminder',
                    subtitle: 'Flutter UI Bootcamp starts in 24 hours.',
                    isUnread: true,
                  ),
                  _NotificationTile(
                    title: 'Comment on your post',
                    subtitle: 'A student reacted to your announcement.',
                    isUnread: false,
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Clear All Notifications',
                    icon: Icons.delete_outline,
                    isPrimary: true,
                    onPressed: () async {
                      final shouldClear = await showConfirmActionDialog(
                        context,
                        title: 'Clear all notifications?',
                        message: 'This removes all notification cards from the UI list.',
                        confirmLabel: 'Clear All',
                        isDestructive: true,
                      );

                      if (shouldClear != true) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications UI cleared. Connect to backend when ready.')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Empty state preview',
                    subtitle: 'Shown when there are no unread messages left.',
                  ),
                  const SizedBox(height: 12),
                  const EmptyState(
                    title: 'You are all caught up',
                    message: 'When notifications are empty, this calm empty state keeps the screen useful.',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Loading state preview',
                    subtitle: 'Skeletons keep the inbox feeling responsive.',
                  ),
                  const SizedBox(height: 12),
                  const LoadingSkeleton(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.isUnread,
  });

  final String title;
  final String subtitle;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isUnread ? AppColors.cta : AppColors.surfaceSoft,
            child: Icon(
              Icons.notifications,
              color: isUnread ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread)
            const Icon(Icons.circle, size: 10, color: AppColors.cta),
        ],
      ),
    );
  }
}
