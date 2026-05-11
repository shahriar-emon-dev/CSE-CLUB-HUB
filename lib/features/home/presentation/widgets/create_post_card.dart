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
    final fieldColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6);

    return Row(
      children: [
        AvatarWidget(
          fallbackLabel: displayName.characters.first.toUpperCase(),
          imageUrl: avatarUrl,
          size: 40,
          backgroundColor: AppColors.cta,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: onCreatePressed,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'What\'s on your mind?',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onImagePressed ?? onCreatePressed,
          icon: Icon(Icons.photo_library_outlined,
              color: Colors.green.shade600, size: 22),
        ),
      ],
    );
  }
}
