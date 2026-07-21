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

/// Club-post card. Full-bleed media, a stats row driven entirely by live
/// reaction/comment providers (no fabricated view/share counters — this
/// entity has no backing columns for those), and a bookmark action wired to
/// the real `saved_posts` table.
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

class _PostCardState extends ConsumerState<PostCard> with SingleTickerProviderStateMixin {
  final _reactionAnchorKey = GlobalKey();
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
    showCommentsSheet(context, entityId: widget.item.id, type: widget.item.type);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final reactionState = ref.watch(postReactionNotifierProvider(item.id));
    final commentCount = ref.watch(postCommentCountProvider(item.id)).valueOrNull ?? item.commentCount;
    final isBookmarked = ref.watch(postBookmarkProvider(item.id)).valueOrNull ?? false;

    final counts = reactionState.counts;
    final hasLiveCounts = counts.values.any((v) => v > 0);
    final favCount = hasLiveCounts ? (counts['favorite'] ?? 0) : item.favoriteCount;
    final fireCount = hasLiveCounts ? (counts['fire'] ?? 0) : item.fireCount;
    final handCount = hasLiveCounts ? (counts['pan_tool'] ?? 0) : item.handCount;
    final totalReactions = favCount + fireCount + handCount;
    final activeReaction = reactionState.activeReaction;

    return GestureDetector(
      onTap: () => context.push('/post/${item.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _PostHeader(item: item, showActions: widget.showActions),
            ),
            if (item.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  item.title,
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.2),
                ),
              ),
            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  item.description!,
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14.5, height: 1.5),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (item.mediaAssetUrl != null && item.mediaAssetUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: item.mediaAssetUrl!,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.04)),
                  errorWidget: (context, url, error) => Container(color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totalReactions > 0 || commentCount > 0) ...[
                    _StatsRow(
                      favCount: favCount,
                      fireCount: fireCount,
                      handCount: handCount,
                      commentCount: commentCount,
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    key: _reactionAnchorKey,
                    children: [
                      _ActionButton(
                        icon: activeReaction != null ? _iconForReaction(activeReaction) : Icons.favorite_border,
                        isActive: activeReaction != null,
                        activeColor: activeReaction != null ? _colorForReaction(activeReaction) : null,
                        bounceAnimation: activeReaction != null ? _bounceAnimation : null,
                        label: 'Like',
                        onTap: () => _onReactionTap(activeReaction ?? 'favorite'),
                        onLongPress: _onLongPress,
                      ),
                      _ActionButton(icon: Icons.mode_comment_outlined, label: 'Comment', onTap: _openComments),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () => showShareSheet(context, title: item.title, id: item.id, type: 'post'),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref.read(bookmarkNotifierProvider.notifier).toggle(item.id, isBookmarked),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isBookmarked ? AppColors.primary : AppColors.textSecondaryDark,
                            size: 21,
                          ),
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
    );
  }

  IconData _iconForReaction(String type) {
    switch (type) {
      case 'fire':
        return Icons.local_fire_department;
      case 'pan_tool':
        return Icons.front_hand;
      default:
        return Icons.favorite;
    }
  }

  Color _colorForReaction(String type) {
    switch (type) {
      case 'fire':
        return const Color(0xFFFF6B35);
      case 'pan_tool':
        return const Color(0xFFFFD93D);
      default:
        return const Color(0xFFFF4757);
    }
  }
}

class _PostHeader extends StatelessWidget {
  final UnifiedFeedItem item;
  final bool showActions;

  const _PostHeader({required this.item, required this.showActions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (item.clubId != null) context.push('/clubs/${item.clubId}');
          },
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: item.clubLogoUrl != null && item.clubLogoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.clubLogoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
                        errorWidget: (_, _, _) => const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
                      )
                    : const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          item.clubName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Every club_posts row is created by an executive/admin
                      // (enforced by RLS), so this reflects a real, always-true
                      // "official club account" fact rather than a per-author lookup.
                      const Icon(Icons.verified_rounded, color: AppColors.info, size: 15),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${item.authorName} · ${timeago.format(item.createdAt)}',
                    style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        if (showActions)
          GestureDetector(
            onTap: () => showPostActions(context, postId: item.id),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.more_horiz_rounded, color: AppColors.textSecondaryDark, size: 20),
            ),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int favCount;
  final int fireCount;
  final int handCount;
  final int commentCount;

  const _StatsRow({required this.favCount, required this.fireCount, required this.handCount, required this.commentCount});

  @override
  Widget build(BuildContext context) {
    final total = favCount + fireCount + handCount;
    return Row(
      children: [
        if (total > 0) ...[
          _ReactionStack(favCount: favCount, fireCount: fireCount, handCount: handCount),
          const SizedBox(width: 6),
          Text('$total', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        ],
        const Spacer(),
        if (commentCount > 0)
          Text(
            '$commentCount comment${commentCount == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
      ],
    );
  }
}

class _ReactionStack extends StatelessWidget {
  final int favCount;
  final int fireCount;
  final int handCount;

  const _ReactionStack({required this.favCount, required this.fireCount, required this.handCount});

  @override
  Widget build(BuildContext context) {
    final active = <(IconData, Color)>[
      if (favCount > 0) (Icons.favorite, const Color(0xFFFF4757)),
      if (fireCount > 0) (Icons.local_fire_department, const Color(0xFFFF6B35)),
      if (handCount > 0) (Icons.front_hand, const Color(0xFFFFD93D)),
    ];
    return SizedBox(
      width: 16 + (active.length - 1) * 12,
      height: 18,
      child: Stack(
        children: [
          for (var i = 0; i < active.length; i++)
            Positioned(
              left: i * 12,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceDark),
                child: Icon(active[i].$1, size: 12, color: active[i].$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final Animation<double>? bounceAnimation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.bounceAnimation,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? (activeColor ?? AppColors.primary) : AppColors.textSecondaryDark;
    final iconWidget = Icon(icon, size: 19, color: color);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              bounceAnimation != null ? ScaleTransition(scale: bounceAnimation!, child: iconWidget) : iconWidget,
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
