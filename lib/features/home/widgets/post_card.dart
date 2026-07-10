import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../models/unified_feed_item.dart';
import '../providers/post_interaction_provider.dart';
import 'comments_bottom_sheet.dart';
import 'reaction_picker.dart';
import 'post_actions_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends ConsumerStatefulWidget {
  final UnifiedFeedItem item;
  final bool showActions;

  const PostCard({
    super.key,
    required this.item,
    this.showActions = false,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  final _reactionAnchorKey = GlobalKey();
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onReactionTap(String reactionType) {
    _bounceController.forward(from: 0);
    ref.read(postReactionNotifierProvider(widget.item.id).notifier).toggleReaction(reactionType);
  }

  void _onLongPress() {
    final reactionState = ref.read(postReactionNotifierProvider(widget.item.id));
    showReactionPicker(
      context,
      anchorKey: _reactionAnchorKey,
      currentReaction: reactionState.activeReaction,
      onReactionSelected: (type) => _onReactionTap(type),
    );
  }

  void _openComments() {
    showCommentsSheet(
      context,
      entityId: widget.item.id,
      type: widget.item.type,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reactionState = ref.watch(postReactionNotifierProvider(widget.item.id));
    final item = widget.item;

    return GestureDetector(
      onTap: () => context.push('/post/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            _buildHeader(item),
            const SizedBox(height: 14),

            // Content
            if (item.title.isNotEmpty && item.type == UnifiedFeedItemType.event)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),

            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  item.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Media
            if (item.mediaAssetUrl != null && item.mediaAssetUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.mediaAssetUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(),
                  ),
                ),
              ),

            // Interaction Bar
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: _buildInteractionBar(item, reactionState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UnifiedFeedItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (item.clubId != null) {
                context.push('/clubs/${item.clubId}');
              }
            },
            child: Row(
              children: [
                // Club Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.clubLogoUrl != null && item.clubLogoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.clubLogoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Icon(Icons.people, color: AppColors.primary, size: 20),
                          errorWidget: (_, __, ___) => const Icon(Icons.people, color: AppColors.primary, size: 20),
                        )
                      : const Icon(Icons.people, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.clubName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            item.authorName,
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            ' · ',
                            style: TextStyle(
                              color: AppColors.textTertiaryDark,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            timeago.format(item.createdAt),
                            style: const TextStyle(
                              color: AppColors.textTertiaryDark,
                              fontSize: 12,
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
        ),
        if (widget.showActions)
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryDark, size: 20),
            onPressed: () => showPostActions(context, postId: widget.item.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildInteractionBar(UnifiedFeedItem item, PostReactionState reactionState) {
    // Use optimistic counts if available, otherwise fall back to feed item data
    final counts = reactionState.counts;
    final hasAnyCounts = counts.values.any((v) => v > 0);
    final favCount = hasAnyCounts ? (counts['favorite'] ?? 0) : item.favoriteCount;
    final fireCount = hasAnyCounts ? (counts['fire'] ?? 0) : item.fireCount;
    final handCount = hasAnyCounts ? (counts['pan_tool'] ?? 0) : item.handCount;
    final activeReaction = reactionState.activeReaction;

    return Row(
      key: _reactionAnchorKey,
      children: [
        // Like Button
        _ReactionButton(
          icon: Icons.favorite,
          outlinedIcon: Icons.favorite_border,
          count: favCount,
          isActive: activeReaction == 'favorite',
          activeColor: const Color(0xFFFF4757),
          bounceAnimation: activeReaction == 'favorite' ? _bounceAnimation : null,
          onTap: () => _onReactionTap('favorite'),
          onLongPress: _onLongPress,
        ),
        const SizedBox(width: 6),

        // Comment Button
        _InteractionButton(
          icon: Icons.chat_bubble_outline,
          count: item.commentCount,
          onTap: _openComments,
        ),
        const SizedBox(width: 6),

        // Share Button
        _InteractionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () => showShareSheet(
            context,
            title: item.title,
            id: item.id,
            type: item.type == UnifiedFeedItemType.event ? 'events' : 'post',
          ),
        ),
        const SizedBox(width: 6),

        if (item.type == UnifiedFeedItemType.post) ...[
          // Fire Button
          _ReactionButton(
            icon: Icons.local_fire_department,
            outlinedIcon: Icons.local_fire_department_outlined,
            count: fireCount,
            isActive: activeReaction == 'fire',
            activeColor: const Color(0xFFFF6B35),
            bounceAnimation: activeReaction == 'fire' ? _bounceAnimation : null,
            onTap: () => _onReactionTap('fire'),
            onLongPress: _onLongPress,
          ),
          const SizedBox(width: 6),

          // Clap Button
          _ReactionButton(
            icon: Icons.front_hand,
            outlinedIcon: Icons.front_hand_outlined,
            count: handCount,
            isActive: activeReaction == 'pan_tool',
            activeColor: const Color(0xFFFFD93D),
            bounceAnimation: activeReaction == 'pan_tool' ? _bounceAnimation : null,
            onTap: () => _onReactionTap('pan_tool'),
            onLongPress: _onLongPress,
          ),
        ],
      ],
    );
  }
}

/// Individual reaction button with animated icon and counter
class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final Animation<double>? bounceAnimation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ReactionButton({
    required this.icon,
    required this.outlinedIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    this.bounceAnimation,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            bounceAnimation != null
                ? ScaleTransition(
                    scale: bounceAnimation!,
                    child: Icon(
                      isActive ? icon : outlinedIcon,
                      color: isActive ? activeColor : AppColors.textSecondaryDark,
                      size: 20,
                    ),
                  )
                : Icon(
                    isActive ? icon : outlinedIcon,
                    color: isActive ? activeColor : AppColors.textSecondaryDark,
                    size: 20,
                  ),
            const SizedBox(width: 4),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: count, end: count),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) => Text(
                value.toString(),
                style: TextStyle(
                  color: isActive ? activeColor : AppColors.textSecondaryDark,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple interaction button (comment, share)
class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final String? label;
  final VoidCallback? onTap;

  const _InteractionButton({
    required this.icon,
    this.count,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondaryDark, size: 20),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 13,
                ),
              ),
            ] else if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
