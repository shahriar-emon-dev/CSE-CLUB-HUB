import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(
            title: 'Admin Control Center',
            subtitle: 'Manage users, roles, moderation, and system health.',
          ),
          const SizedBox(height: 16),
          _tile(
            icon: Icons.manage_accounts,
            title: 'User Management',
            subtitle: 'Search users and adjust access roles securely.',
          ),
          _tile(
            icon: Icons.verified_user_outlined,
            title: 'Executive Role Requests',
            subtitle: 'Approve or reject pending executive access requests.',
          ),
          _tile(
            icon: Icons.report_gmailerrorred,
            title: 'Content Moderation',
            subtitle: 'Review and remove policy-violating posts or comments.',
          ),
          _tile(
            icon: Icons.analytics_outlined,
            title: 'Platform Insights',
            subtitle: 'Monitor users, posts, clubs, and event metrics.',
          ),
        ],
      ),
    );
  }

  // Purpose: Keeps admin action entries visually consistent and easy to scan.
  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
