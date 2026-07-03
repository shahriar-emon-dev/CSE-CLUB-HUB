import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/event.dart';
import '../providers/events_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_feed_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

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
                      _buildMainContent(event),
                      const SizedBox(height: 100), // padding for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
          onPressed: () {},
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

  Widget _buildMainContent(Event event) {
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
