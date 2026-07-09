import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/club_executive.dart';
import '../providers/admin_providers.dart';

class AdminExecutivesScreen extends ConsumerStatefulWidget {
  const AdminExecutivesScreen({super.key});

  @override
  ConsumerState<AdminExecutivesScreen> createState() => _AdminExecutivesScreenState();
}

class _AdminExecutivesScreenState extends ConsumerState<AdminExecutivesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final execsAsync = ref.watch(adminExecutivesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Executive Roster & Control',
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage campus club leadership, roles, and privileges across all department nodes.',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search leadership by name, club ID, or role...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
                prefixIcon: const Icon(Icons.search, color: AppColors.tertiary),
                filled: true,
                fillColor: AppColors.surfaceContainerDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            execsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(64),
                child: CircularProgressIndicator(color: AppColors.tertiary),
              )),
              error: (err, st) => Center(child: Text('Failed to load executives: $err', style: const TextStyle(color: AppColors.error))),
              data: (executives) {
                final filtered = executives.where((e) =>
                  e.fullName.toLowerCase().contains(_searchQuery) ||
                  e.roleTitle.toLowerCase().contains(_searchQuery) ||
                  e.clubId.toLowerCase().contains(_searchQuery)
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64),
                      child: Text('No club executives found matching criteria.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    itemBuilder: (context, index) {
                      final exec = filtered[index];
                      return _buildExecutiveRow(exec);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveRow(ClubExecutive exec) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.tertiary.withValues(alpha: 0.2),
            backgroundImage: exec.avatarUrl != null && exec.avatarUrl!.isNotEmpty ? NetworkImage(exec.avatarUrl!) : null,
            child: exec.avatarUrl == null || exec.avatarUrl!.isEmpty ? const Icon(Icons.person, color: AppColors.tertiary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exec.fullName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('User ID: ${exec.userId.substring(0, 8)}...', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(exec.roleTitle, style: const TextStyle(color: AppColors.tertiary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('Club: ${exec.clubId.substring(0, 8)}...', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
            tooltip: 'Revoke Executive Privileges',
            onPressed: () => _confirmRevokeExecutive(exec),
          ),
        ],
      ),
    );
  }

  void _confirmRevokeExecutive(ClubExecutive exec) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D100A),
        title: const Text('Revoke Executive Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to demote ${exec.fullName} (${exec.roleTitle}) to regular student status and remove them from club leadership?', style: const TextStyle(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).updateUserStatus(exec.userId, 'active');
                ref.invalidate(adminExecutivesListProvider);
                ref.invalidate(dashboardStatsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error revoking role: $e')));
                }
              }
            },
            child: const Text('Revoke Role'),
          ),
        ],
      ),
    );
  }
}
