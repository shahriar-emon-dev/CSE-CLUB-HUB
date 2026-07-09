import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/supabase_config.dart';
import '../providers/home_feed_provider.dart';
import 'delete_confirmation_dialog.dart';

import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_posts_provider.dart';

Future<void> showPostActions(
  BuildContext context, {
  required String postId,
  bool isPinned = false,
  String? currentContent,
  String? clubId,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => PostActionsBottomSheet(
      postId: postId,
      isPinned: isPinned,
      currentContent: currentContent,
      clubId: clubId,
    ),
  );
}

class PostActionsBottomSheet extends ConsumerWidget {
  final String postId;
  final bool isPinned;
  final String? currentContent;
  final String? clubId;

  const PostActionsBottomSheet({
    super.key,
    required this.postId,
    this.isPinned = false,
    this.currentContent,
    this.clubId,
  });

  Future<void> _togglePin(BuildContext context, WidgetRef ref) async {
    context.pop();
    try {
      await SupabaseConfig.client
          .from('club_posts')
          .update({'is_pinned': !isPinned})
          .eq('id', postId);
      ref.invalidate(homeFeedProvider);
      if (clubId != null) ref.invalidate(clubPostsProvider(clubId!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPinned ? 'Post unpinned' : 'Post pinned to top'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pin/unpin post: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _editPost(BuildContext context, WidgetRef ref) async {
    context.pop();
    final ctrl = TextEditingController(text: currentContent ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        title: const Text('Edit Post Content', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0D0D14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseConfig.client
                    .from('club_posts')
                    .update({'content': ctrl.text.trim()})
                    .eq('id', postId);
                ref.invalidate(homeFeedProvider);
                if (clubId != null) ref.invalidate(clubPostsProvider(clubId!));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post updated successfully'), backgroundColor: AppColors.primary),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update post: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(BuildContext context, WidgetRef ref) async {
    context.pop();
    final deleted = await showDeleteConfirmation(context);
    if (deleted != true || !context.mounted) return;

    try {
      await SupabaseConfig.client.from('club_posts').delete().eq('id', postId);
      ref.invalidate(homeFeedProvider);
      ref.invalidate(unifiedFeedItemProvider(postId));
      if (clubId != null) ref.invalidate(clubPostsProvider(clubId!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully'), backgroundColor: AppColors.primary),
        );
        if (GoRouter.of(context).canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _reportPost(BuildContext context, WidgetRef ref) async {
    context.pop();
    try {
      await SupabaseConfig.client.from('content_reports').insert({
        'reporter_id': SupabaseConfig.currentUserId,
        'content_type': 'post',
        'post_id': postId,
        'reason': 'User reported post from feed',
        'status': 'pending',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted to moderation queue.'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not report post: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isAuthorized = profile != null && (profile.isSuperAdmin || profile.isAdmin || profile.isExecutive);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(48),
          ),
          border: const Border(top: BorderSide(color: Color(0x33FFFFFF))),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, -12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Post Actions',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 4),
                  Text('Manage this broadcast post', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isAuthorized) ...[
              _buildActionItem(
                context: context,
                icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                title: isPinned ? 'Unpin Post' : 'Pin to Top',
                color: AppColors.primary,
                onTap: () => _togglePin(context, ref),
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                context: context,
                icon: Icons.edit,
                title: 'Edit Content',
                color: Colors.white,
                onTap: () => _editPost(context, ref),
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                context: context,
                icon: Icons.delete,
                title: 'Delete Post',
                color: AppColors.error,
                isError: true,
                onTap: () => _deletePost(context, ref),
              ),
            ] else ...[
              _buildActionItem(
                context: context,
                icon: Icons.report_problem,
                title: 'Report Post',
                color: AppColors.warning,
                onTap: () => _reportPost(context, ref),
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isError = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isError ? AppColors.error.withValues(alpha: 0.05) : AppColors.surfaceContainerHighDark,
            borderRadius: BorderRadius.circular(12),
            border: isError ? Border.all(color: AppColors.error.withValues(alpha: 0.1)) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(color: isError ? AppColors.error : Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
