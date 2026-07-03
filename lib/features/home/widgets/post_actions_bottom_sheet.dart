import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import 'delete_confirmation_dialog.dart';

Future<void> showPostActions(BuildContext context, {required String postId}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => PostActionsBottomSheet(postId: postId),
  );
}

class PostActionsBottomSheet extends StatelessWidget {
  final String postId;

  const PostActionsBottomSheet({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
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
            // Handle
            Container(
              width: 48, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Post Actions Menu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Manage your post in DevStudio', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Edit Action
            _buildActionItem(
              context: context,
              icon: Icons.edit,
              title: 'Edit Post',
              color: AppColors.primary,
              onTap: () {
                context.pop();
                // Navigate to edit screen if needed
              },
            ),
            const SizedBox(height: 12),

            // Delete Action
            _buildActionItem(
              context: context,
              icon: Icons.delete,
              title: 'Delete Post',
              color: AppColors.error,
              isError: true,
              onTap: () async {
                context.pop();
                final bool? deleted = await showDeleteConfirmation(context);
                if (deleted == true) {
                  // Perform delete and show snackbar or pop
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post deleted successfully'), backgroundColor: AppColors.primary),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),

            // Cancel Action
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 18, fontWeight: FontWeight.w500)),
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
                width: 40, height: 40,
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
