import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/unified_feed_item.dart';
import '../providers/unified_post_provider.dart';
import 'post_actions_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends ConsumerWidget {
  final UnifiedFeedItem item;
  final bool showActions;

  const PostCard({
    super.key,
    required this.item,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/post/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              GestureDetector(
                onTap: () {
                  if (item.clubId != null) {
                    context.push('/clubs/${item.clubId}');
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: item.clubLogoUrl != null && item.clubLogoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: item.clubLogoUrl!, 
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Icon(Icons.people, color: AppColors.secondary),
                                errorWidget: (context, url, error) => const Icon(Icons.people, color: AppColors.secondary),
                              ),
                            )
                          : const Icon(Icons.people, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.clubName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        Row(
                          children: [
                            Text(item.authorName, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            const Text(' • ', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            Text(DateFormat('MMM d').format(item.createdAt), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showActions)
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryDark),
                  onPressed: () => showPostActions(context, postId: item.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (item.title.isNotEmpty) ...[
            Text(item.title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
          if (item.description != null && item.description!.isNotEmpty) ...[
            Text(item.description!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
          ],
          if (item.mediaAssetUrl != null && item.mediaAssetUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.mediaAssetUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(color: AppColors.surfaceContainerHighDark),
          const SizedBox(height: 8),
          Row(
            children: [
              if (item.type == UnifiedFeedItemType.post) ...[
                _buildInteraction(
                  Icons.favorite_border,
                  item.favoriteCount.toString(),
                  onTap: () => ref.read(unifiedPostActionsNotifierProvider.notifier).toggleReaction(item.id, 'favorite'),
                ),
                const SizedBox(width: 16),
              ],
              _buildInteraction(
                Icons.chat_bubble_outline,
                item.commentCount.toString(),
                onTap: () => context.push('/post/${item.id}'),
              ),
              if (item.type == UnifiedFeedItemType.post) ...[
                const SizedBox(width: 16),
                _buildInteraction(
                  Icons.local_fire_department_outlined,
                  item.fireCount.toString(),
                  onTap: () => ref.read(unifiedPostActionsNotifierProvider.notifier).toggleReaction(item.id, 'fire'),
                ),
                const SizedBox(width: 16),
                _buildInteraction(
                  Icons.front_hand_outlined,
                  item.handCount.toString(),
                  onTap: () => ref.read(unifiedPostActionsNotifierProvider.notifier).toggleReaction(item.id, 'pan_tool'),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInteraction(IconData icon, String count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondaryDark, size: 18),
            const SizedBox(width: 4),
            Text(count, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
