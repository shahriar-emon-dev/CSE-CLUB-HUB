import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_profile.dart';
import '../providers/admin_providers.dart';
import '../../clubs/providers/clubs_provider.dart';
import '../../auth/providers/auth_provider.dart';

class MemberDetailModal extends ConsumerStatefulWidget {
  final UserProfile user;

  const MemberDetailModal({super.key, required this.user});

  static void show(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          decoration: BoxDecoration(
            color: const Color(0xFF13131F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: MemberDetailModal(user: user),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<MemberDetailModal> createState() => _MemberDetailModalState();
}

class _MemberDetailModalState extends ConsumerState<MemberDetailModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runAction(String title, Future<void> Function() action) async {
    setState(() => _isLoadingAction = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title executed successfully.'), backgroundColor: AppColors.primary),
      );
      ref.invalidate(paginatedUsersProvider);
      ref.invalidate(adminExecutivesListProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Column(
      children: [
        // Header Bar
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2D),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.isExecutive
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: user.isExecutive ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            user.role.displayName.toUpperCase(),
                            style: TextStyle(
                              color: user.isExecutive ? AppColors.primary : AppColors.textSecondaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user.status == 'banned')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: const Text('BANNED', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        else if (user.status == 'verified' || user.isApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF4CAF50)),
                            ),
                            child: const Text('VERIFIED', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.email} • ID: ${user.studentId ?? "N/A"} • ${user.department ?? "CSE"} (Batch ${user.batch ?? "N/A"})',
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.textSecondaryDark, size: 24),
              ),
            ],
          ),
        ),

        // 13 Admin Action Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF151522),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_isLoadingAction)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  ),
                // 1. Promote to Executive
                _buildActionButton(
                  icon: Icons.workspace_premium,
                  label: 'Promote Executive',
                  color: AppColors.primary,
                  onTap: _showPromoteExecutiveDialog,
                ),
                // 2. Revoke Executive
                if (user.isExecutive) ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.remove_moderator,
                    label: 'Revoke Executive',
                    color: AppColors.warning,
                    onTap: () => _runAction('Revoke Executive', () async {
                      await ref.read(adminRepositoryProvider).revokeExecutive(user.id);
                    }),
                  ),
                ],
                const SizedBox(width: 8),
                // 3. Verify Account
                _buildActionButton(
                  icon: Icons.verified_user,
                  label: 'Verify Account',
                  color: const Color(0xFF4CAF50),
                  onTap: () => _runAction('Verify Account', () async {
                    await ref.read(adminRepositoryProvider).verifyUser(user.id);
                  }),
                ),
                const SizedBox(width: 8),
                // 4. Ban User / Suspend
                if (user.status != 'banned')
                  _buildActionButton(
                    icon: Icons.block,
                    label: 'Ban Account',
                    color: AppColors.error,
                    onTap: () => _runAction('Ban Account', () async {
                      await ref.read(adminRepositoryProvider).banUser(user.id, reason: 'Policy Violation');
                    }),
                  )
                // 5. Unban User
                else
                  _buildActionButton(
                    icon: Icons.lock_open,
                    label: 'Unban Account',
                    color: const Color(0xFF2196F3),
                    onTap: () => _runAction('Unban Account', () async {
                      await ref.read(adminRepositoryProvider).unbanUser(user.id);
                    }),
                  ),
                const SizedBox(width: 8),
                // 6. Reset Password
                _buildActionButton(
                  icon: Icons.lock_reset,
                  label: 'Reset Password',
                  color: const Color(0xFFFF9800),
                  onTap: () => _runAction('Reset Password', () async {
                    await ref.read(adminRepositoryProvider).resetUserPassword(user.email);
                  }),
                ),
                const SizedBox(width: 8),
                // 7. Change Role
                _buildActionButton(
                  icon: Icons.manage_accounts,
                  label: 'Set Role: Admin',
                  color: const Color(0xFF9C27B0),
                  onTap: () => _runAction('Change Role to Super Admin', () async {
                    await ref.read(adminRepositoryProvider).updateUserRole(user.id, 'super_admin');
                  }),
                ),
                const SizedBox(width: 8),
                // 8. Set Role: Student
                _buildActionButton(
                  icon: Icons.school,
                  label: 'Set Role: Student',
                  color: const Color(0xFF00BCD4),
                  onTap: () => _runAction('Change Role to Student', () async {
                    await ref.read(adminRepositoryProvider).updateUserRole(user.id, 'member');
                  }),
                ),
                const SizedBox(width: 8),
                // 9. Assign Club Membership
                _buildActionButton(
                  icon: Icons.group_add,
                  label: 'Assign Club',
                  color: const Color(0xFF8BC34A),
                  onTap: _showAssignClubDialog,
                ),
                const SizedBox(width: 8),
                // 10. Remove Club Membership
                _buildActionButton(
                  icon: Icons.group_remove,
                  label: 'Remove Club',
                  color: const Color(0xFFFF5722),
                  onTap: _showRemoveClubDialog,
                ),
                const SizedBox(width: 8),
                // 11. Copy Student ID
                _buildActionButton(
                  icon: Icons.copy,
                  label: 'Copy ID',
                  color: AppColors.textSecondaryDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ID copied: ${user.studentId ?? user.id}')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // 12. Copy Email
                _buildActionButton(
                  icon: Icons.email_outlined,
                  label: 'Copy Email',
                  color: AppColors.textSecondaryDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email copied: ${user.email}')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // 13. Delete Account Forever
                _buildActionButton(
                  icon: Icons.delete_forever,
                  label: 'Delete Forever',
                  color: AppColors.error,
                  onTap: () => _runAction('Delete Account', () async {
                    await ref.read(adminRepositoryProvider).deleteUserAccount(user.id);
                    if (context.mounted) Navigator.pop(context);
                  }),
                ),
              ],
            ),
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryDark,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Activity'),
            Tab(text: 'Clubs'),
            Tab(text: 'Reports / Moderation'),
          ],
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(user),
              _buildActivityTab(user),
              _buildClubsTab(user),
              _buildReportsTab(user),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoadingAction ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(UserProfile user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoGrid([
            ('Full Name', user.fullName),
            ('Student ID', user.studentId ?? 'Not Provided'),
            ('Department', user.department ?? 'Computer Science & Engineering'),
            ('Batch', user.batch ?? 'General'),
            ('Email Address', user.email),
            ('Phone Number', user.phone ?? 'Not Provided'),
            ('Role Status', user.role.displayName),
            ('Account Status', user.status.toUpperCase()),
            ('Joined Date', DateFormat('MMMM d, yyyy').format(user.joinedAt)),
            ('Last Updated', DateFormat('MMM d, yyyy - HH:mm').format(user.updatedAt)),
          ]),
          const SizedBox(height: 24),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const Text('Bio / About', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(user.bio!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<(String, String)> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 70,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.$1, style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(item.$2, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityTab(UserProfile user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Recent User Activity & Audit Logs', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('System activity stream tracked in real-time.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildClubsTab(UserProfile user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hub, size: 48, color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Club Memberships for ${user.fullName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(user.isExecutive ? 'Assigned Executive of ${user.managedClubId ?? "CSE Club"}' : 'Standard Member', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(UserProfile user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 48, color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Moderation & Content Reports', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('No pending moderation flags or disciplinary records for this user.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showPromoteExecutiveDialog() {
    String? selectedClubId = widget.user.managedClubId;
    if (selectedClubId != null && !selectedClubId.contains('-')) {
      selectedClubId = null;
    }
    final roleController = TextEditingController(text: 'Club Executive');

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final clubsAsync = ref.watch(clubsProvider);
          return AlertDialog(
            backgroundColor: const Color(0xFF13131F),
            title: Text('Promote ${widget.user.fullName} to Executive', style: const TextStyle(color: Colors.white, fontSize: 18)),
            content: clubsAsync.when(
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.tertiary))),
              error: (e, st) => Text('Error loading clubs: $e', style: const TextStyle(color: AppColors.error)),
              data: (clubs) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedClubId,
                        dropdownColor: const Color(0xFF1E1E2C),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Select Club',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true,
                          fillColor: const Color(0xFF0D0D14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => selectedClubId = val,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: roleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Role Title (e.g. President, GS)',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true,
                          fillColor: const Color(0xFF0D0D14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () {
                  if (selectedClubId != null && roleController.text.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    _runAction('Promote Executive', () async {
                      await ref.read(adminRepositoryProvider).promoteToExecutive(widget.user.id, selectedClubId!, roleController.text.trim());
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a club and enter a role title.')));
                  }
                },
                child: const Text('Confirm Promotion'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignClubDialog() {
    String? selectedClubId;
    final roleController = TextEditingController(text: 'Member');

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final clubsAsync = ref.watch(clubsProvider);
          return AlertDialog(
            backgroundColor: const Color(0xFF13131F),
            title: Text('Assign ${widget.user.fullName} to Club', style: const TextStyle(color: Colors.white, fontSize: 18)),
            content: clubsAsync.when(
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.tertiary))),
              error: (e, st) => Text('Error loading clubs: $e', style: const TextStyle(color: AppColors.error)),
              data: (clubs) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedClubId,
                        dropdownColor: const Color(0xFF1E1E2C),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Select Club',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true,
                          fillColor: const Color(0xFF0D0D14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => selectedClubId = val,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: roleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Membership Role (e.g. Member, Volunteer)',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true,
                          fillColor: const Color(0xFF0D0D14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BC34A), foregroundColor: Colors.white),
                onPressed: () {
                  if (selectedClubId != null && roleController.text.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    _runAction('Assign Club Membership', () async {
                      await ref.read(adminRepositoryProvider).assignClubMembership(widget.user.id, selectedClubId!, roleController.text.trim());
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a club.')));
                  }
                },
                child: const Text('Assign Membership'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRemoveClubDialog() {
    String? selectedClubId;

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final clubsAsync = ref.watch(clubsProvider);
          return AlertDialog(
            backgroundColor: const Color(0xFF13131F),
            title: Text('Remove ${widget.user.fullName} from Club', style: const TextStyle(color: Colors.white, fontSize: 18)),
            content: clubsAsync.when(
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.tertiary))),
              error: (e, st) => Text('Error loading clubs: $e', style: const TextStyle(color: AppColors.error)),
              data: (clubs) {
                return SingleChildScrollView(
                  child: DropdownButtonFormField<String>(
                    value: selectedClubId,
                    dropdownColor: const Color(0xFF1E1E2C),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Select Club to Remove From',
                      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                      filled: true,
                      fillColor: const Color(0xFF0D0D14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => selectedClubId = val,
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
                onPressed: () {
                  if (selectedClubId != null) {
                    Navigator.pop(ctx);
                    _runAction('Remove Club Membership', () async {
                      await ref.read(adminRepositoryProvider).removeClubMembership(widget.user.id, selectedClubId!);
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a club.')));
                  }
                },
                child: const Text('Remove Membership'),
              ),
            ],
          );
        },
      ),
    );
  }
}
