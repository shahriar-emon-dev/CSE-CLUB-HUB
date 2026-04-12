import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_header.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(
            title: 'Notifications',
            subtitle: 'Stay informed with posts, events, and reminders.',
          ),
          const SizedBox(height: 16),
          _buildNotificationTile(
            title: 'New post from Machine Learning Club',
            subtitle: 'AI workshop materials uploaded.',
            isUnread: true,
          ),
          _buildNotificationTile(
            title: 'Event reminder',
            subtitle: 'Flutter UI Bootcamp starts in 24 hours.',
            isUnread: true,
          ),
          _buildNotificationTile(
            title: 'Comment on your post',
            subtitle: 'A student reacted to your announcement.',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  // Purpose: Renders a single notification row with read/unread visual state.
  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool isUnread,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnread ? AppColors.cta : AppColors.surfaceSoft,
          child: Icon(
            Icons.notifications,
            color: isUnread ? Colors.white : AppColors.textSecondary,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isUnread
            ? const Icon(Icons.circle, size: 10, color: AppColors.cta)
            : null,
      ),
    );
  }
}
