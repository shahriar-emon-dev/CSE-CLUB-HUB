import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../models/unified_feed_item.dart';
import '../providers/post_interaction_provider.dart';
import 'comments_bottom_sheet.dart';
import 'reaction_picker.dart';
import 'package:go_router/go_router.dart';
import 'post_actions_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../events/providers/events_provider.dart';
import '../../../models/event.dart' show RsvpStatus, EventRsvp;

class EventCard extends ConsumerStatefulWidget {
  final UnifiedFeedItem item;
  final bool showActions;

  const EventCard({
    super.key,
    required this.item,
    this.showActions = false,
  });

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard>
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
      onTap: () => context.push('/events/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (item.clubId != null) context.push('/clubs/${item.clubId}');
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: item.clubLogoUrl != null && item.clubLogoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item.clubLogoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Icon(Icons.event, color: AppColors.accent, size: 20),
                                  errorWidget: (_, __, ___) => const Icon(Icons.event, color: AppColors.accent, size: 20),
                                )
                              : const Icon(Icons.event, color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.clubName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeago.format(item.createdAt),
                                style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Event badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event, size: 12, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text('Event', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (widget.showActions)
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryDark, size: 20),
                    onPressed: () => showPostActions(context, postId: item.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 8),

            // Description
            if (item.description != null && item.description!.isNotEmpty) ...[
              Text(
                item.description!,
                style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 15, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
            ],

            // Media
            if (item.mediaAssetUrl != null && item.mediaAssetUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.mediaAssetUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Event details
            if (item.eventDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: AppColors.accent.withValues(alpha: 0.8)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(item.eventDate!),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (item.venue != null && item.venue!.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppColors.accent.withValues(alpha: 0.8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.venue!,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Interaction Bar
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Column(
                children: [
                  // RSVP Action Bar
                  _buildRsvpBar(context, ref, item),
                  const SizedBox(height: 12),
                  Row(
                    key: _reactionAnchorKey,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Like
                          _ReactionButton(
                            icon: Icons.favorite,
                            outlinedIcon: Icons.favorite_border,
                            count: reactionState.counts['favorite'] ?? item.favoriteCount,
                            isActive: reactionState.activeReaction == 'favorite',
                            activeColor: const Color(0xFFFF4757),
                            bounceAnimation: reactionState.activeReaction == 'favorite' ? _bounceAnimation : null,
                            onTap: () => _onReactionTap('favorite'),
                            onLongPress: _onLongPress,
                          ),
                          const SizedBox(width: 6),

                          // Comment
                          _InteractionButton(
                            icon: Icons.chat_bubble_outline,
                            count: item.commentCount,
                            onTap: _openComments,
                          ),
                          const SizedBox(width: 6),

                          // Share
                          _InteractionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () => showShareSheet(
                              context,
                              title: item.title,
                              id: item.id,
                              type: 'events',
                            ),
                          ),
                        ],
                      ),
                      if (item.capacity != null)
                        Row(
                          children: [
                            const Icon(Icons.people, color: AppColors.textSecondaryDark, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${item.rsvpCount ?? 0}/${item.capacity}',
                              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                            ),
                          ],
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

  Widget _buildRsvpBar(BuildContext context, WidgetRef ref, UnifiedFeedItem item) {
    final myRsvpAsync = ref.watch(myRsvpProvider(item.id));
    final liveCountAsync = ref.watch(eventRsvpCountProvider(item.id));
    final myStatus = myRsvpAsync.valueOrNull?.status;
    final rsvpCount = liveCountAsync.valueOrNull ?? item.rsvpCount ?? 0;
    final isGoing = myStatus == RsvpStatus.confirmed;
    final isInterested = myStatus == RsvpStatus.interested;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGoing
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$rsvpCount ${rsvpCount == 1 ? 'person' : 'people'} going',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (item.capacity != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${(item.capacity! - rsvpCount).clamp(0, 99999)} seats remaining',
                          style: TextStyle(
                            color: (item.capacity! - rsvpCount) <= 5 ? AppColors.error : AppColors.textTertiaryDark,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Interested button
          InkWell(
            onTap: () {
              if (isInterested) {
                ref.read(rsvpNotifierProvider.notifier).cancelRsvp(item.id);
              } else {
                ref.read(rsvpNotifierProvider.notifier).updateRsvp(item.id, RsvpStatus.interested);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isInterested ? const Color(0xFFFFD93D).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isInterested ? const Color(0xFFFFD93D) : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 14, color: isInterested ? const Color(0xFFFFD93D) : AppColors.textSecondaryDark),
                  const SizedBox(width: 4),
                  Text(
                    'Interested',
                    style: TextStyle(
                      color: isInterested ? const Color(0xFFFFD93D) : AppColors.textSecondaryDark,
                      fontSize: 12,
                      fontWeight: isInterested ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Going button
          InkWell(
            onTap: () {
              if (isGoing) {
                ref.read(rsvpNotifierProvider.notifier).cancelRsvp(item.id);
              } else {
                ref.read(rsvpNotifierProvider.notifier).updateRsvp(item.id, RsvpStatus.confirmed);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isGoing ? AppColors.primary : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isGoing ? Icons.check_circle : Icons.check_circle_outline,
                    size: 14,
                    color: isGoing ? const Color(0xFF1D100A) : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isGoing ? 'Going' : 'Join',
                    style: TextStyle(
                      color: isGoing ? const Color(0xFF1D100A) : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reaction button with animated bounce
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
                    child: Icon(isActive ? icon : outlinedIcon, color: isActive ? activeColor : AppColors.textSecondaryDark, size: 20),
                  )
                : Icon(isActive ? icon : outlinedIcon, color: isActive ? activeColor : AppColors.textSecondaryDark, size: 20),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: isActive ? activeColor : AppColors.textSecondaryDark,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
