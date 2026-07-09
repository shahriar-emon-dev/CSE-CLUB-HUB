import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/event.dart';
import '../../../models/club_post.dart';
import '../providers/events_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_feed_provider.dart';
import '../../clubs/providers/club_posts_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    ref.read(clubPostActionsNotifierProvider.notifier).addComment(widget.eventId, text);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final commentsAsync = ref.watch(clubPostCommentsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
        data: (event) {
          if (event == null) return const Center(child: Text('Event not found.', style: TextStyle(color: Colors.white)));
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, event),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainContent(event, commentsAsync),
                      const SizedBox(height: 100), // padding for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: _buildStickyCommentInput(),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Event event) {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      backgroundColor: const Color(0xFF13131F).withValues(alpha: 0.8),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final profileAsync = ref.watch(currentProfileProvider);
            final user = profileAsync.valueOrNull;
            final canEdit = user != null && 
                (user.isAdmin || 
                 user.isSuperAdmin || 
                 user.id == event.createdBy ||
                 (user.isExecutive && user.managedClubId == event.organizingClubId));
            
            if (!canEdit) return const SizedBox.shrink();
            
            return IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => context.push('/events/${event.id}/edit'),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            Share.share('Check out "${event.title}" on CSE Club Hub!');
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (event.coverImageUrl != null || event.organizerAvatar != null)
              Image.network(
                event.coverImageUrl ?? event.organizerAvatar!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceContainerDark,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: AppColors.textSecondaryDark, size: 48),
                    ),
                  );
                },
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF0D0D14),
                    const Color(0xFF0D0D14).withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hub, color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(event.category.displayName, style: const TextStyle(color: AppColors.primary, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
                        ),
                        child: const Text('Featured', style: TextStyle(color: AppColors.tertiary, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      letterSpacing: -1,
                      shadows: [
                        Shadow(
                          color: Color(0x66FFB694),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(Event event, AsyncValue<List<ClubPostComment>> commentsAsync) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoGrid(event),
                const SizedBox(height: 32),
                _buildDescription(event),
                const SizedBox(height: 32),
                _buildReactionsBar(event),
                const SizedBox(height: 32),
                _buildCommentsSection(commentsAsync),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _buildRSVPCard(event),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoGrid(event),
        const SizedBox(height: 32),
        _buildDescription(event),
        const SizedBox(height: 32),
        _buildRSVPCard(event),
        const SizedBox(height: 32),
        _buildReactionsBar(event),
        const SizedBox(height: 32),
        _buildCommentsSection(commentsAsync),
      ],
    );
  }

  Widget _buildInfoGrid(Event event) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return Row(
      children: [
        Expanded(child: _buildInfoCell(Icons.calendar_today, 'DATE', dateFormatter.format(event.eventDate))),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCell(Icons.schedule, 'TIME', timeFormatter.format(event.eventDate))),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCell(Icons.location_on, 'VENUE', event.venue ?? 'TBA')),
      ],
    );
  }

  Widget _buildInfoCell(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    ).wrapWithBlur(20);
  }

  Widget _buildDescription(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About the Event', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          event.description ?? 'No description provided.',
          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.6),
        ),
      ],
    );
  }


  Widget _buildRSVPCard(Event event) {
    final rsvpAsync = ref.watch(myRsvpProvider(widget.eventId));
    final rsvpCountAsync = ref.watch(eventRsvpCountProvider(widget.eventId));
    
    final rsvpStatus = rsvpAsync.value?.status;
    final isGoing = rsvpStatus == RsvpStatus.confirmed;
    final isInterested = rsvpStatus == RsvpStatus.interested;
    final isUpdating = ref.watch(rsvpNotifierProvider).isLoading;
    
    // We can fallback to the static count from the event row if the stream hasn't loaded yet
    final liveRsvpCount = rsvpCountAsync.value ?? (event.rsvpCount ?? 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reservation', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // RSVP Buttons
          ElevatedButton(
            onPressed: isUpdating ? null : () => _handleRsvpToggle(isGoing, RsvpStatus.confirmed),
            style: ElevatedButton.styleFrom(
              backgroundColor: isGoing ? AppColors.primary : AppColors.surfaceDark,
              foregroundColor: isGoing ? const Color(0xFF571F00) : Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: isGoing ? 8 : 0,
              shadowColor: isGoing ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isGoing ? Icons.check_circle : Icons.check_circle_outline, size: 24),
                const SizedBox(width: 12),
                const Text('Going', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: isUpdating ? null : () => _handleRsvpToggle(isInterested, RsvpStatus.interested),
            style: OutlinedButton.styleFrom(
              foregroundColor: isInterested ? AppColors.secondary : Colors.white,
              side: BorderSide(color: isInterested ? AppColors.secondary : AppColors.textSecondaryDark, width: 1.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: isInterested ? AppColors.secondary.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isInterested ? Icons.star : Icons.star_border, size: 24),
                const SizedBox(width: 12),
                const Text('Interested', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),

          // Social Proof
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 40,
                child: Stack(
                  children: [
                    _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuAa7lyKeEwdh3YOSgCs3WukOJqCq7xxKbV2GepyUJiPqGLfh2D7o4WIs87soZXNwIVHzybfngNnxykLYNyPoYj4rKjLNdF9TLu5GE_GjTD2nREM2LKmNnxE7Eh1gkwW2SiHqtJd54W2rc0fpsZ7Ba4uS0tj6x9hNSX8fGiNwBUeW8Sh9XAqrlGcrk5wXc9m5Zv3muOkjjti1seAYGrRHRZx801z9n_R4qV3rnqGVbY_OdA3RgeoXzs7-8-1cJwvxdwdtnTu30h9Fw4', 0),
                    _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuCYZKgVDMyjUUzVMSipVwVrpiODDyLY9IlJiSGsLjhGS8V-UzY2f5rDqgpI91ysEvjXB3z9Xa9hiDCg2TrlyJwgpbjCVrvFZdGb_xTnlS4VhQIsK3GV0xRFtpZrrnYVqKdONglVzrj_Xz7zaeWgBVYG6fHe2eAel4iIn7nm5J-l0uXOMj8Da21b2Uj2gTMZyTbYvSn5iP1q0rySGFLxGNF-kQ_vAtleSxYJd8-qL5rW0gwrod0OsqEu_BULyoGNh8zNL9H5WbbetC0', 25),
                    _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuANW9iIMc2VvL2M6JW-VleNEnKdG_kCxjYDjDH8Fd9Z5zVqoFJ2qNijk5kDCI-T3X_kssWDsduX_2JOe_-j-VZTvXMcmSn4SLo7XKIJVWBgOg3xZ5Ry5kz0h_T3SVIAL_9PgSm2BmSHXmkPWQfJwdfiClkOOk5Wit4R7vWcsBEymJONYCAl26XbEZByjIcZLOzDalo64xYzbRjbKrtnyik0oFQvcBJqrf499r9DuYRkgsB4kOEpsOjMSmaLEIJF9cOQJDvPk3qnIAY', 50),
                    Positioned(
                      left: 75,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceDark,
                          border: Border.all(color: const Color(0xFF0D0D14), width: 2),
                        ),
                        child: Center(
                          child: Text('+${liveRsvpCount > 3 ? (liveRsvpCount - 3) : 0}', 
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '$liveRsvpCount students ',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: const [
                      TextSpan(text: 'are going', style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Invite your lab mates'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    ).wrapWithBlur(20);
  }

  Widget _buildAvatar(String url, double leftOffset) {
    return Positioned(
      left: leftOffset,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0D0D14), width: 2),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Future<void> _handleRsvpToggle(bool isCurrentlySelected, RsvpStatus status) async {
    final notifier = ref.read(rsvpNotifierProvider.notifier);
    if (isCurrentlySelected) {
      // Un-toggle
      await notifier.cancelRsvp(widget.eventId);
    } else {
      // Toggle
      await notifier.updateRsvp(widget.eventId, status);
    }
    if (!mounted) return;
    // Refresh to show updated counts and status
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(myRsvpProvider(widget.eventId));
    ref.invalidate(eventsProvider);
    ref.invalidate(homeFeedProvider);
    ref.invalidate(clubEventsProvider);
  }

  Widget _buildReactionsBar(Event event) {
    final reactionsAsync = ref.watch(itemReactionsProvider(widget.eventId));
    final favCount = reactionsAsync.value?['favorite'] ?? 0;
    final fireCount = reactionsAsync.value?['fire'] ?? 0;
    final handCount = reactionsAsync.value?['pan_tool'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildReactionButton(Icons.favorite, favCount, 'favorite'),
          _buildReactionButton(Icons.local_fire_department, fireCount, 'fire'),
          _buildReactionButton(Icons.pan_tool, handCount, 'pan_tool'),
        ],
      ),
    );
  }

  Widget _buildReactionButton(IconData icon, int count, String type) {
    return InkWell(
      onTap: () {
        ref.read(clubPostActionsNotifierProvider.notifier).toggleReaction(widget.eventId, type);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(AsyncValue<List<ClubPostComment>> commentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Community Discussion', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            commentsAsync.maybeWhen(
              data: (comments) => Text('${comments.length} comments', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
              orElse: () => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131F).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('No comments yet. Be the first to start the discussion!', style: TextStyle(color: AppColors.textSecondaryDark)),
              );
            }
            return Column(
              children: comments.map((comment) => _buildCommentItem(comment)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, st) => Text('Error loading comments', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  Widget _buildCommentItem(ClubPostComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: comment.authorAvatarUrl != null ? NetworkImage(comment.authorAvatarUrl!) : null,
            child: comment.authorAvatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName ?? 'Unknown', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (comment.isExecutive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('EXECUTIVE', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    const Spacer(),
                    Text(timeago.format(comment.createdAt), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(comment.content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCommentInput() {
    final isLoading = ref.watch(clubPostActionsNotifierProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: const Color(0xFF0D0D14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: isLoading ? null : _submitComment,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                      )
                    ],
                  ),
                  child: isLoading
                      ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _BlurExtension on Widget {
  Widget wrapWithBlur(double sigma) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(4),
        bottomRight: Radius.circular(24),
        bottomLeft: Radius.circular(4),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: this,
      ),
    );
  }
}
