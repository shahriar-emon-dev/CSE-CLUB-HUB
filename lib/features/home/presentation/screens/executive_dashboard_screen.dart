import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class ExecutiveDashboardScreen extends StatelessWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Executive Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(
            title: 'Executive Workspace',
            subtitle: 'Manage posts, events, and club updates.',
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            title: 'Manage Posts',
            subtitle: 'Create, edit, pin, or remove your club posts.',
            icon: Icons.post_add,
          ),
          _buildActionCard(
            title: 'Manage Events',
            subtitle: 'Create and update club events with RSVP tracking.',
            icon: Icons.event,
          ),
          _buildActionCard(
            title: 'Manage Club Profile',
            subtitle: 'Update bio, cover image, and key club details.',
            icon: Icons.groups,
          ),
        ],
      ),
    );
  }

  // Purpose: Provides consistent action blocks for executive control areas.
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
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
