import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

// ==========================================
// REACTION BAR WIDGET
// ==========================================

class ReactionBar extends StatelessWidget {
  const ReactionBar({
    required this.likeCount,
    required this.fireCount,
    required this.applauseCount,
    required this.commentCount,
    this.onLike,
    this.onComment,
    this.onShare,
    super.key,
  });

  final int likeCount;
  final int fireCount;
  final int applauseCount;
  final int commentCount;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ReactionItem(
          emoji: '❤️',
          count: likeCount,
          onTap: onLike,
        ),
        _ReactionItem(
          emoji: '🔥',
          count: fireCount,
          onTap: onLike,
        ),
        _ReactionItem(
          emoji: '👏',
          count: applauseCount,
          onTap: onLike,
        ),
        _ReactionItem(
          icon: Icons.chat_bubble_outline,
          count: commentCount,
          onTap: onComment,
        ),
        _ReactionItem(
          icon: Icons.share_outlined,
          onTap: onShare,
        ),
      ],
    );
  }
}

class _ReactionItem extends StatelessWidget {
  const _ReactionItem({
    this.emoji,
    this.icon,
    this.count,
    this.onTap,
  });

  final String? emoji;
  final IconData? icon;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null)
                Text(
                  emoji!,
                  style: const TextStyle(fontSize: 20),
                )
              else
                Icon(icon, color: AppColors.textSecondary, size: 22),
              if (count != null) ...[
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
