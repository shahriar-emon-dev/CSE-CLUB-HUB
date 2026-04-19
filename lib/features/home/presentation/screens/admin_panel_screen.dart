import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/event_card_widget.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/modal_dialog.dart';
import '../../../../shared/widgets/post_card_widget.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';
import '../../../../shared/widgets/user_row.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String _selectedRoleFilter = 'All';
  String _selectedDepartmentFilter = 'All';
  String _selectedClubFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    title: 'Admin Control Center',
                    subtitle: 'Manage users, moderation, and system health.',
                    trailing: const RoleBadge(
                      label: 'Super Admin',
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 560 ? 3 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns == 2 ? 1.7 : 1.5,
                        children: const [
                          StatsCard(label: 'Total users', value: '8.4K', icon: Icons.people_outline),
                          StatsCard(label: 'Executives', value: '126', icon: Icons.workspace_premium_outlined),
                          StatsCard(label: 'Total posts', value: '1.2K', icon: Icons.post_add_outlined),
                          StatsCard(label: 'Total events', value: '84', icon: Icons.event_outlined),
                          StatsCard(label: 'Active clubs', value: '24', icon: Icons.groups_2_outlined),
                          StatsCard(label: 'Audit logs', value: '3.1K', icon: Icons.receipt_long_outlined),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'User Management',
                    subtitle: 'Search users, assign clubs, and manage roles safely.',
                  ),
                  const SizedBox(height: 12),
                  const InputField(
                    label: 'Search users',
                    hintText: 'Name, email, or student ID',
                  ),
                  const SizedBox(height: 12),
                  _FilterRow(
                    label: 'Role',
                    options: const ['All', 'Student', 'Executive', 'Admin'],
                    selectedValue: _selectedRoleFilter,
                    onSelected: (value) => setState(() => _selectedRoleFilter = value),
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    label: 'Department',
                    options: const ['All', 'CSE', 'EEE', 'BBA', 'English', 'Law'],
                    selectedValue: _selectedDepartmentFilter,
                    onSelected: (value) => setState(() => _selectedDepartmentFilter = value),
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    label: 'Club',
                    options: const ['All', 'CSE Club', 'IoT Club', 'ML Club'],
                    selectedValue: _selectedClubFilter,
                    onSelected: (value) => setState(() => _selectedClubFilter = value),
                  ),
                  const SizedBox(height: 12),
                  const _UserManagementCard(
                    name: 'Rahim Uddin',
                    email: 'rahim@smuct.edu',
                    role: 'Student',
                    department: 'CSE',
                    studentId: '221-15-5234',
                  ),
                  const SizedBox(height: 12),
                  const _UserManagementCard(
                    name: 'Nusrat Jahan',
                    email: 'nusrat@smuct.ac.bd',
                    role: 'Executive',
                    department: 'EEE',
                    studentId: '221-12-1121',
                  ),
                  const SizedBox(height: 12),
                  const _UserManagementCard(
                    name: 'Admin User',
                    email: 'admin@smuct.edu',
                    role: 'Admin',
                    department: 'CSE',
                    studentId: 'SYS-001',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Content Moderation',
                    subtitle: 'Review posts and take action when needed.',
                  ),
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'ML Club',
                    club: 'Moderation Queue',
                    content: 'Workshop announcement: model deployment session this Sunday.',
                    timestamp: 'Needs review',
                  ),
                  const SizedBox(height: 12),
                  _ActionRow(
                    primaryLabel: 'Delete Post',
                    secondaryLabel: 'Flag Post',
                    onPrimaryPressed: () => _confirmAction(
                      context,
                      title: 'Delete post?',
                      message: 'This removes the content from the feed and moderation queue.',
                      danger: true,
                    ),
                    onSecondaryPressed: () => _confirmAction(
                      context,
                      title: 'Flag post?',
                      message: 'The post will be flagged for review and kept in audit history.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Event Management',
                    subtitle: 'Edit or delete events across clubs.',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'AI & Career Fair',
                    date: '21 May • 10:00 AM',
                    venue: 'Main Auditorium',
                  ),
                  const SizedBox(height: 12),
                  _ActionRow(
                    primaryLabel: 'Delete Event',
                    secondaryLabel: 'Edit Event',
                    onPrimaryPressed: () => _confirmAction(
                      context,
                      title: 'Delete event?',
                      message: 'The event will be removed from every club schedule.',
                      danger: true,
                    ),
                    onSecondaryPressed: () => _showInfo(context, 'Edit event UI is ready for connection to the event form.'),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Audit Logs',
                    subtitle: 'Track admin actions and system changes.',
                  ),
                  const SizedBox(height: 12),
                  _AuditLogTile(
                    title: 'Promoted user to Executive',
                    subtitle: 'Admin updated role permissions • 3 minutes ago',
                  ),
                  const SizedBox(height: 10),
                  _AuditLogTile(
                    title: 'Deleted flagged post',
                    subtitle: 'Admin removed a moderation queue item • 18 minutes ago',
                  ),
                  const SizedBox(height: 10),
                  _AuditLogTile(
                    title: 'Assigned user to club',
                    subtitle: 'User mapped to CSE Club • 1 hour ago',
                  ),
                  const SizedBox(height: 16),
                  const EmptyState(
                    title: 'No additional audit events',
                    message: 'Fresh admin activity will appear here once more actions are taken.',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Loading State Preview',
                    subtitle: 'Skeleton UI for future server-driven list loading.',
                  ),
                  const SizedBox(height: 12),
                  const LoadingSkeleton(height: 92),
                  const SizedBox(height: 12),
                  const LoadingSkeleton(height: 92),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    bool danger = false,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ModalDialog(
          title: title,
          message: message,
          primaryLabel: danger ? 'Delete' : 'Confirm',
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(),
          secondaryLabel: 'Cancel',
          onSecondaryPressed: () => Navigator.of(dialogContext).pop(),
          icon: danger ? Icons.delete_outline : Icons.info_outline,
        );
      },
    );
  }

  void _showInfo(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ModalDialog(
          title: 'Information',
          message: message,
          primaryLabel: 'Close',
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(),
          icon: Icons.info_outline,
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        ...options.map(
          (option) => ChoiceChip(
            label: Text(option),
            selected: selectedValue == option,
            onSelected: (_) => onSelected(option),
            selectedColor: AppColors.cta.withValues(alpha: 0.12),
            labelStyle: TextStyle(
              color: selectedValue == option ? AppColors.cta : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserManagementCard extends StatelessWidget {
  const _UserManagementCard({
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.studentId,
  });

  final String name;
  final String email;
  final String role;
  final String department;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserRow(
            name: name,
            email: email,
            roleLabel: role,
            department: '$department • $studentId',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              ActionButton(label: 'Promote to Executive', icon: Icons.upgrade_outlined),
              ActionButton(label: 'Revoke Executive', icon: Icons.do_disturb_on_outlined),
              ActionButton(label: 'Assign to Club', icon: Icons.groups_2_outlined),
              ActionButton(label: 'Delete User', icon: Icons.delete_outline),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ActionButton(
            label: primaryLabel,
            icon: Icons.delete_outline,
            isPrimary: true,
            onPressed: onPrimaryPressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ActionButton(
            label: secondaryLabel,
            icon: Icons.edit_outlined,
            onPressed: onSecondaryPressed,
          ),
        ),
      ],
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.history, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
