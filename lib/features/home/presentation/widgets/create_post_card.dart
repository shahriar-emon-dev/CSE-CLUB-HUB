import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'avatar_widget.dart';

// ==========================================
// CREATE POST CARD WIDGET
// ==========================================

class CreatePostCard extends StatelessWidget {
  const CreatePostCard({
    required this.displayName,
    required this.onCreatePressed,
    this.onImagePressed,
    this.avatarUrl,
    super.key,
  });

  final String displayName;
  final String? avatarUrl;
  final VoidCallback onCreatePressed;
  final VoidCallback? onImagePressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fieldColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6);
    final borderColor = isDark ? AppColors.darkInputBorder : AppColors.inputBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AvatarWidget(
            fallbackLabel: displayName.characters.first.toUpperCase(),
            imageUrl: avatarUrl,
            size: 46,
            backgroundColor: AppColors.cta,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onCreatePressed,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Write something...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onImagePressed ?? onCreatePressed,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF4E7DA),
            ),
            icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.cta),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onCreatePressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text(
              'Post',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
