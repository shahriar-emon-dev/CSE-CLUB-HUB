import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'avatar_widget.dart';
import 'post_image_grid.dart';
import 'reaction_bar.dart';

// ==========================================
// FEED POST CARD WIDGET
// ==========================================

class PostCard extends StatelessWidget {
  const PostCard({
    required this.clubName,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.timestamp,
    required this.likeCount,
    required this.fireCount,
    required this.applauseCount,
    required this.commentCount,
    this.clubLogoUrl,
    this.authorAvatarUrl,
    this.imageUrls = const [],
    this.isPinned = false,
    this.onLike,
    this.onComment,
    this.onShare,
    super.key,
  });

  final String clubName;
  final String authorName;
  final String authorRole;
  final String content;
  final String timestamp;
  final int likeCount;
  final int fireCount;
  final int applauseCount;
  final int commentCount;
  final String? clubLogoUrl;
  final String? authorAvatarUrl;
  final List<String> imageUrls;
  final bool isPinned;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkInputBorder : AppColors.inputBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF111827);
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cta.withValues(alpha: 0.12)
                    : const Color(0xFFF4E7DA),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.push_pin_outlined, color: AppColors.cta, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Pinned post',
                    style: TextStyle(
                      color: AppColors.cta,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Author Header ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AvatarWidget(
                      fallbackLabel: authorName.isNotEmpty
                          ? authorName.characters.first.toUpperCase()
                          : '?',
                      imageUrl: authorAvatarUrl ?? clubLogoUrl,
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clubName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$authorName · $authorRole · $timestamp',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_horiz, color: textSecondary, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Post Content ──
                Text(
                  content,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                if (imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  PostImageGrid(imageUrls: imageUrls),
                ],
                const SizedBox(height: 8),
                Divider(height: 1, color: borderColor),
                ReactionBar(
                  likeCount: likeCount,
                  fireCount: fireCount,
                  applauseCount: applauseCount,
                  commentCount: commentCount,
                  onLike: onLike,
                  onComment: onComment,
                  onShare: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
