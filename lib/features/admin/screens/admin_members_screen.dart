import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import '../../clubs/providers/clubs_provider.dart';
import '../../../models/user_profile.dart';
import '../widgets/member_detail_modal.dart';

class AdminMembersScreen extends ConsumerWidget {
  const AdminMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(adminActionProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e'), backgroundColor: AppColors.error),
          );
        },
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Member role updated successfully.'), backgroundColor: AppColors.primary),
            );
          }
        },
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: 32),
          _buildBentoStats(context, ref),
          const SizedBox(height: 32),
          _buildMembersTable(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('SYSTEM ADMINISTRATION', style: TextStyle(color: AppColors.tertiary, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Member Management', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.5)),
          ],
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Row(
            children: [
              Expanded(
                child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 16),
                onChanged: (value) {
                  ref.read(memberSearchQueryProvider.notifier).state = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Search by name or ID...',
                  hintStyle: TextStyle(color: AppColors.textSecondaryDark),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondaryDark),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF362720),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const Icon(Icons.filter_list, color: AppColors.tertiary),
            ),
          ],
        ),
        ),
      ],
    );
  }

  Widget _buildBentoStats(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(memberStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
      error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      data: (stats) {
        return GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildStatBox('Total Members', stats.totalMembers.toString(), Colors.white, AppColors.tertiary),
            _buildStatBox('Active Now', stats.activeNow.toString(), AppColors.secondary, null),
            _buildStatBox('Executives', stats.executives.toString(), AppColors.primaryContainer, AppColors.primaryContainer),
            _buildStatBox('Pending Sync', stats.pendingSync.toString(), AppColors.tertiary.withValues(alpha: 0.6), null),
          ],
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, Color valueColor, Color? borderColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F).withValues(alpha: 0.8),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            left: BorderSide(color: borderColor ?? Colors.white.withValues(alpha: 0.05), width: borderColor != null ? 4 : 1),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label.toUpperCase(), style: TextStyle(color: AppColors.textSecondaryDark.withValues(alpha: 0.6), fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(color: valueColor, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    ).wrapWithBlur(20, 16);
  }

  Widget _buildMembersTable(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(paginatedUsersProvider);
    final isActionLoading = ref.watch(adminActionProvider).isLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, 850),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13131F).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.1), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(color: const Color(0xFF261812).withValues(alpha: 0.5)),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Member Info', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Student ID', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Role Status', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Administrative Actions', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  usersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
                    ),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Center(child: Text('Failed to load users: $e', style: const TextStyle(color: AppColors.error))),
                    ),
                    data: (users) {
                      if (users.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Center(child: Text('No users found.', style: TextStyle(color: AppColors.textSecondaryDark))),
                        );
                      }
                      return Column(
                        children: users.asMap().entries.map((entry) {
                          final index = entry.key;
                          final user = entry.value;
                          return _buildTableRow(
                            context: context,
                            user: user,
                            ref: ref,
                            isActionLoading: isActionLoading,
                            showBorder: index != users.length - 1,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF261812).withValues(alpha: 0.3),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Showing top results', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.textSecondaryDark, size: 20), onPressed: () {}),
                            _buildPageButton('1', true),
                            _buildPageButton('2', false),
                            _buildPageButton('3', false),
                            IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark, size: 20), onPressed: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).wrapWithBlur(20, 24);
  }

  Widget _buildPageButton(String text, bool isSelected) {
    return Container(
      width: 32, height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.tertiary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: isSelected ? const Color(0xFF412D00) : AppColors.textSecondaryDark, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildTableRow({
    required BuildContext context,
    required UserProfile user,
    required WidgetRef ref,
    required bool isActionLoading,
    bool showBorder = true,
  }) {
    final isExecutive = user.isExecutive || user.isAdmin || user.isSuperAdmin;
    final avatarUrl = user.avatarUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.fullName)}&background=1d100a&color=e9c176';

    return InkWell(
      onTap: () => MemberDetailModal.show(context, user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          border: showBorder ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))) : null,
        ),
        child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Hero(
                  tag: 'admin_avatar_${user.id}',
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover),
                      border: isExecutive ? Border.all(color: AppColors.primaryContainer, width: 2) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text('${user.department ?? "CSE"} • Batch ${user.batch ?? "N/A"}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text(user.email, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(user.studentId ?? 'N/A', style: TextStyle(color: AppColors.tertiary.withValues(alpha: 0.8), fontSize: 14, fontFamily: 'monospace')),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isExecutive ? AppColors.primaryContainer.withValues(alpha: 0.2) : AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isExecutive ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.secondary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  isExecutive ? 'EXECUTIVE MEMBER' : 'STANDARD STUDENT',
                  style: TextStyle(
                    color: isExecutive ? AppColors.primaryContainer : AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: isActionLoading
                      ? null
                      : () {
                          if (isExecutive) {
                            _showRevokeConfirmDialog(context, ref, user);
                          } else {
                            _showPromotionDialog(context, ref, user.id);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExecutive ? AppColors.error.withValues(alpha: 0.2) : AppColors.tertiary,
                    foregroundColor: isExecutive ? AppColors.error : const Color(0xFF412D00),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: isExecutive ? 0 : 8,
                    shadowColor: isExecutive ? Colors.transparent : AppColors.tertiary.withValues(alpha: 0.2),
                    side: isExecutive ? BorderSide(color: AppColors.error.withValues(alpha: 0.2)) : BorderSide.none,
                  ),
                  child: Text(isExecutive ? 'Revoke Executive' : 'Promote to Executive', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondaryDark),
                  color: const Color(0xFF1D100A),
                  onSelected: (action) {
                    if (action == 'suspend') {
                      _showSuspendConfirmDialog(context, ref, user);
                    } else if (action == 'delete') {
                      _showDeleteConfirmDialog(context, ref, user);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'suspend',
                      child: Row(
                        children: const [
                          Icon(Icons.block, color: AppColors.warning, size: 18),
                          SizedBox(width: 8),
                          Text('Suspend / Activate Account', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_forever, color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text('Delete Account Forever', style: TextStyle(color: AppColors.error, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showPromotionDialog(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => _PromotionDialog(userId: userId, parentRef: ref),
    );
  }

  void _showRevokeConfirmDialog(BuildContext context, WidgetRef ref, UserProfile user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        title: const Text('Revoke Executive Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to demote ${user.fullName} back to regular student status? They will lose all administrative write access immediately.', style: const TextStyle(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(adminActionProvider.notifier).revokeExecutive(user.id);
              Navigator.pop(ctx);
            },
            child: const Text('Revoke Executive Status'),
          ),
        ],
      ),
    );
  }

  void _showSuspendConfirmDialog(BuildContext context, WidgetRef ref, UserProfile user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        title: const Text('Suspend / Activate Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Do you want to toggle account suspension for ${user.fullName} (${user.email})? A suspended account cannot log in or post anywhere.', style: const TextStyle(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: const Color(0xFF1D100A)),
            onPressed: () {
              ref.read(userManagementActionProvider.notifier).suspendUser(user.id, 'admin_action');
              Navigator.pop(ctx);
            },
            child: const Text('Suspend Account'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, foregroundColor: const Color(0xFF1D100A)),
            onPressed: () {
              ref.read(userManagementActionProvider.notifier).activateUser(user.id);
              Navigator.pop(ctx);
            },
            child: const Text('Activate Account'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, UserProfile user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        title: const Text('Permanently Delete Account?', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        content: Text('CAUTION: Are you sure you want to completely erase the account for ${user.fullName} (${user.email})? This action cannot be undone and deletes profile records.', style: const TextStyle(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(userManagementActionProvider.notifier).deleteUserAccount(user.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}

class _PromotionDialog extends ConsumerStatefulWidget {
  final String userId;
  final WidgetRef parentRef;
  const _PromotionDialog({required this.userId, required this.parentRef});

  @override
  ConsumerState<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends ConsumerState<_PromotionDialog> {
  String? selectedClubId;
  final _roleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(clubsProvider); // Make sure to import clubs_provider.dart
    return AlertDialog(
      backgroundColor: const Color(0xFF13131F),
      title: const Text('Promote to Executive', style: TextStyle(color: Colors.white)),
      content: clubsAsync.when(
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.tertiary))),
        error: (e, st) => Text('Error loading clubs: $e', style: const TextStyle(color: AppColors.error)),
        data: (clubs) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedClubId,
                dropdownColor: const Color(0xFF261812),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Select Club',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: const Color(0xFF0D0D14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => selectedClubId = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _roleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Role Title (e.g. President)',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: const Color(0xFF0D0D14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: const Color(0xFF412D00)),
          onPressed: () {
            if (selectedClubId != null && _roleController.text.isNotEmpty) {
              widget.parentRef.read(adminActionProvider.notifier).promoteToExecutive(widget.userId, selectedClubId!, _roleController.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Confirm Promotion'),
        ),
      ],
    );
  }
}

extension _BlurExtension on Widget {
  Widget wrapWithBlur(double sigma, [double radius = 24.0]) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: this,
      ),
    );
  }
}
