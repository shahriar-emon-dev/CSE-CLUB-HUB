import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class PostCardWidget extends StatelessWidget {
  const PostCardWidget({
    required this.author,
    required this.club,
    required this.content,
    required this.timestamp,
    this.onLike,
    this.onComment,
    super.key,
  });

  final String author;
  final String club;
  final String content;
  final String timestamp;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.surfaceSoft,
                  child: Text(author.characters.first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$club - $timestamp',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onLike,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Like'),
                ),
                TextButton.icon(
                  onPressed: onComment,
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: const Text('Comment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
