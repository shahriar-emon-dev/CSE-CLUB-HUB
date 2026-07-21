import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/club_executive.dart';
import '../../clubs/providers/clubs_provider.dart';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
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
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showPromoteModal,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Promote Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: const Color(0xFF412D00),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search leadership by name, club name, or role...',
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
                  (e.clubName ?? e.clubId).toLowerCase().contains(_searchQuery)
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
            flex: 2,
            child: Text(
              exec.clubName ?? 'Club: ${exec.clubId.substring(0, 8)}...',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.tertiary),
                tooltip: 'Edit Position or Change Club',
                onPressed: () => _showEditExecutiveModal(exec),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                tooltip: 'Revoke Executive Privileges',
                onPressed: () => _confirmRevokeExecutive(exec),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditExecutiveModal(ClubExecutive exec) {
    final positionController = TextEditingController(text: exec.roleTitle);
    String selectedClubId = exec.clubId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D100A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Executive Position', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) {
            final clubsAsync = ref.watch(clubsProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Managing: ${exec.fullName}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                const SizedBox(height: 16),
                const Text('Assigned Club', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                const SizedBox(height: 8),
                clubsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading clubs: $err', style: const TextStyle(color: AppColors.error)),
                  data: (clubs) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedClubId,
                      dropdownColor: const Color(0xFF2A170F),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainerDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedClubId = val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('Position Title', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: positionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceContainerDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: const Color(0xFF412D00)),
            onPressed: () async {
              final newPos = positionController.text.trim();
              if (newPos.isEmpty) return;
              try {
                if (selectedClubId != exec.clubId) {
                  await ref.read(adminActionProvider.notifier).revokeExecutive(exec.userId, exec.clubId);
                  await ref.read(adminActionProvider.notifier).promoteToExecutive(exec.userId, selectedClubId, newPos);
                } else {
                  await ref.read(adminActionProvider.notifier).updateExecutivePosition(exec.userId, exec.clubId, newPos);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Executive details updated!'), backgroundColor: AppColors.primary),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating details: $e'), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
                await ref.read(adminActionProvider.notifier).revokeExecutive(exec.userId, exec.clubId);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Executive role revoked successfully.'), backgroundColor: AppColors.primary),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error revoking role: $e'), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Revoke Role'),
          ),
        ],
      ),
    );
  }

  void _showPromoteModal() {
    String? selectedClubId;
    String? selectedUserId;
    final positionController = TextEditingController(text: 'President');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13131F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Consumer(
          builder: (context, ref, child) {
            final clubsAsync = ref.watch(adminClubsProvider);
            final usersAsync = ref.watch(paginatedUsersProvider);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Promote Student to Executive', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Select Club', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                const SizedBox(height: 8),
                clubsAsync.when(
                  loading: () => const LinearProgressIndicator(color: AppColors.tertiary),
                  error: (err, st) => Text('Error loading clubs: $err', style: const TextStyle(color: AppColors.error)),
                  data: (clubs) {
                    return DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainerDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      hint: const Text('Choose a club...', style: TextStyle(color: AppColors.textSecondaryDark)),
                      items: clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => selectedClubId = val,
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('Select Student', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                const SizedBox(height: 8),
                usersAsync.when(
                  loading: () => const LinearProgressIndicator(color: AppColors.tertiary),
                  error: (err, st) => Text('Error loading users: $err', style: const TextStyle(color: AppColors.error)),
                  data: (users) {
                    return DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainerDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      hint: const Text('Choose a student...', style: TextStyle(color: AppColors.textSecondaryDark)),
                      items: users.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.fullName} (${u.email})'))).toList(),
                      onChanged: (val) => selectedUserId = val,
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('Executive Position Title', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: positionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceContainerDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      foregroundColor: const Color(0xFF412D00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (selectedClubId == null || selectedUserId == null || positionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all fields')));
                        return;
                      }
                      try {
                        await ref.read(adminActionProvider.notifier).promoteToExecutive(
                              selectedUserId!,
                              selectedClubId!,
                              positionController.text.trim(),
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Student successfully promoted to Executive!'), backgroundColor: AppColors.primary),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error promoting student: $e'), backgroundColor: AppColors.error));
                        }
                      }
                    },
                    child: const Text('Promote to Executive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
