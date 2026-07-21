import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/unified_feed_item.dart';
import '../providers/post_interaction_provider.dart';
import 'comments_bottom_sheet.dart';
import 'reaction_picker.dart';
import 'package:go_router/go_router.dart';
import 'post_actions_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../events/providers/events_provider.dart';
import '../../../models/event.dart' show RsvpStatus;

/// Event card: full-bleed cover with a live countdown/status badge, organizer
/// and venue, a real RSVP-count-driven "going" strip, and Join/Interested
/// actions wired to the existing RSVP RPCs. Participant avatars are not
/// rendered here — there is no attendee-profile query backing individual
/// faces, so this shows the real live count instead of fabricated photos.
class EventCard extends ConsumerStatefulWidget {
  final UnifiedFeedItem item;
  final bool showActions;

  const EventCard({super.key, required this.item, this.showActions = false});

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard> with SingleTickerProviderStateMixin {
  final _reactionAnchorKey = GlobalKey();
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

  String _countdownLabel(DateTime eventDate) {
    final now = DateTime.now();
    if (eventDate.isBefore(now)) return 'Happened';
    final diff = eventDate.difference(now);
    if (diff.inDays > 0) return 'In ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return 'In ${diff.inMinutes}m';
    return 'Starting now';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final reactionState = ref.watch(postReactionNotifierProvider(item.id));
    final commentCount = ref.watch(postCommentCountProvider(item.id)).valueOrNull ?? item.commentCount;
    final myRsvpAsync = ref.watch(myRsvpProvider(item.id));
    final liveCountAsync = ref.watch(eventRsvpCountProvider(item.id));
    final myStatus = myRsvpAsync.valueOrNull?.status;
    final rsvpCount = liveCountAsync.valueOrNull ?? item.rsvpCount ?? 0;
    final isGoing = myStatus == RsvpStatus.confirmed;
    final isInterested = myStatus == RsvpStatus.interested;
    final isPast = item.eventDate != null && item.eventDate!.isBefore(DateTime.now());

    return GestureDetector(
      onTap: () => context.push('/events/${item.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverWithBadges(
              item: item,
              isPast: isPast,
              countdownLabel: item.eventDate != null ? _countdownLabel(item.eventDate!) : null,
              showMenu: widget.showActions,
              onMenuTap: () => showPostActions(context, postId: item.id),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 14, color: AppColors.textTertiaryDark),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item.clubName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 12.5),
                        ),
                      ),
                      if (item.venue != null && item.venue!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.place_rounded, size: 14, color: AppColors.textTertiaryDark),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.venue!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.description!,
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  _RsvpStrip(
                    rsvpCount: rsvpCount,
                    capacity: item.capacity,
                    isGoing: isGoing,
                    isInterested: isInterested,
                    isPast: isPast,
                    onGoing: () {
                      if (isGoing) {
                        ref.read(rsvpNotifierProvider.notifier).cancelRsvp(item.id);
                      } else {
                        ref.read(rsvpNotifierProvider.notifier).updateRsvp(item.id, RsvpStatus.confirmed);
                      }
                    },
                    onInterested: () {
                      if (isInterested) {
                        ref.read(rsvpNotifierProvider.notifier).cancelRsvp(item.id);
                      } else {
                        ref.read(rsvpNotifierProvider.notifier).updateRsvp(item.id, RsvpStatus.interested);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    key: _reactionAnchorKey,
                    children: [
                      _ActionIcon(
                        icon: reactionState.activeReaction == 'favorite' ? Icons.favorite : Icons.favorite_border,
                        isActive: reactionState.activeReaction == 'favorite',
                        color: const Color(0xFFFF4757),
                        count: reactionState.counts['favorite'] ?? item.favoriteCount,
                        bounceAnimation: reactionState.activeReaction == 'favorite' ? _bounceAnimation : null,
                        onTap: () => _onReactionTap('favorite'),
                        onLongPress: _onLongPress,
                      ),
                      const SizedBox(width: 14),
                      _ActionIcon(
                        icon: Icons.mode_comment_outlined,
                        count: commentCount,
                        onTap: _openComments,
                      ),
                      const SizedBox(width: 14),
                      _ActionIcon(
                        icon: Icons.share_outlined,
                        onTap: () => showShareSheet(context, title: item.title, id: item.id, type: 'events'),
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
}

class _CoverWithBadges extends StatelessWidget {
  final UnifiedFeedItem item;
  final bool isPast;
  final String? countdownLabel;
  final bool showMenu;
  final VoidCallback onMenuTap;

  const _CoverWithBadges({
    required this.item,
    required this.isPast,
    required this.countdownLabel,
    required this.showMenu,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: item.mediaAssetUrl != null && item.mediaAssetUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.mediaAssetUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.accent.withValues(alpha: 0.08)),
                  errorWidget: (_, _, _) => _fallbackCover(),
                )
              : _fallbackCover(),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_rounded, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('EVENT', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              ],
            ),
          ),
        ),
        if (countdownLabel != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isPast ? Icons.history_rounded : Icons.schedule_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(countdownLabel!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        if (item.eventDate != null)
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(
              DateFormat('EEE, MMM d · h:mm a').format(item.eventDate!),
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        if (showMenu)
          Positioned(
            top: 8,
            right: item.eventDate != null || countdownLabel != null ? 90 : 8,
            child: GestureDetector(
              onTap: onMenuTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallbackCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent.withValues(alpha: 0.35), AppColors.surfaceDark],
        ),
      ),
      child: const Center(child: Icon(Icons.event_rounded, size: 44, color: Colors.white24)),
    );
  }
}

class _RsvpStrip extends StatelessWidget {
  final int rsvpCount;
  final int? capacity;
  final bool isGoing;
  final bool isInterested;
  final bool isPast;
  final VoidCallback onGoing;
  final VoidCallback onInterested;

  const _RsvpStrip({
    required this.rsvpCount,
    required this.capacity,
    required this.isGoing,
    required this.isInterested,
    required this.isPast,
    required this.onGoing,
    required this.onInterested,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Real live count rendered as a stacked-icon motif — no fabricated
        // attendee avatars, since no per-attendee profile query backs this.
        SizedBox(
          width: 40,
          height: 22,
          child: Stack(
            children: List.generate(3, (i) => Positioned(
                  left: i * 12,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.18 + i * 0.08),
                      border: Border.all(color: AppColors.surfaceDark, width: 1.5),
                    ),
                    child: const Icon(Icons.person, size: 11, color: AppColors.primary),
                  ),
                )),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            capacity != null ? '$rsvpCount / $capacity going' : '$rsvpCount going',
            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        if (!isPast) ...[
          _PillButton(
            label: 'Interested',
            icon: Icons.star_rounded,
            isActive: isInterested,
            activeColor: const Color(0xFFFFD93D),
            onTap: onInterested,
          ),
          const SizedBox(width: 6),
          _PillButton(
            label: isGoing ? 'Going' : 'Join',
            icon: isGoing ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
            isActive: isGoing,
            activeColor: AppColors.primary,
            filled: true,
            onTap: onGoing,
          ),
        ],
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final bool filled;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = isActive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? (filled ? activeColor : activeColor.withValues(alpha: 0.15)) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(9),
          border: active && !filled ? Border.all(color: activeColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? (filled ? Colors.white : activeColor) : AppColors.textSecondaryDark),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? (filled ? Colors.white : activeColor) : AppColors.textSecondaryDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final int? count;
  final bool isActive;
  final Color? color;
  final Animation<double>? bounceAnimation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ActionIcon({
    required this.icon,
    this.count,
    this.isActive = false,
    this.color,
    this.bounceAnimation,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = isActive ? (color ?? AppColors.primary) : AppColors.textSecondaryDark;
    final iconWidget = Icon(icon, size: 19, color: resolvedColor);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          bounceAnimation != null ? ScaleTransition(scale: bounceAnimation!, child: iconWidget) : iconWidget,
          if (count != null) ...[
            const SizedBox(width: 5),
            Text('$count', style: TextStyle(color: resolvedColor, fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}
