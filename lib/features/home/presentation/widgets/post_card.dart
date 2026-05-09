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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF4E7DA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.push_pin_outlined, color: AppColors.cta, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pinned post',
                    style: TextStyle(
                      color: AppColors.cta,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarWidget(
                      fallbackLabel: authorName.isNotEmpty
                          ? authorName.characters.first.toUpperCase()
                          : '?',
                      imageUrl: authorAvatarUrl ?? clubLogoUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  clubName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timestamp,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.more_horiz,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$authorName  •  $authorRole',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    height: 1.45,
                  ),
                ),
                if (imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PostImageGrid(imageUrls: imageUrls),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.inputBorder),
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
