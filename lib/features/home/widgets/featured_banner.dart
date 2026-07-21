import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/club.dart';
import '../../../models/notice.dart';
import '../../../models/unified_feed_item.dart';

class _FeaturedSlide {
  final String kicker;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeaturedSlide({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Auto-advancing highlight carousel: nearest upcoming event, the most
/// followed club, the latest pinned announcement, and the newest club —
/// all derived from data already loaded by the feed screen, no extra
/// Supabase reads.
class FeaturedBanner extends StatefulWidget {
  final List<UnifiedFeedItem> feed;
  final List<Club> clubs;
  final List<Notice> notices;

  const FeaturedBanner({super.key, required this.feed, required this.clubs, required this.notices});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      final slides = _buildSlides();
      if (slides.isEmpty) return;
      final next = (_page + 1) % slides.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<_FeaturedSlide> _buildSlides() {
    final slides = <_FeaturedSlide>[];

    final upcoming = widget.feed
        .where((f) => f.type == UnifiedFeedItemType.event && f.eventDate != null && f.eventDate!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));
    if (upcoming.isNotEmpty) {
      final e = upcoming.first;
      slides.add(_FeaturedSlide(
        kicker: 'UPCOMING EVENT',
        title: e.title,
        subtitle: DateFormat('EEE, MMM d · h:mm a').format(e.eventDate!),
        icon: Icons.event_available_rounded,
        color: AppColors.accent,
        onTap: () => context.push('/events/${e.id}'),
      ));
    }

    if (widget.clubs.isNotEmpty) {
      final trending = [...widget.clubs]..sort((a, b) => b.memberCount.compareTo(a.memberCount));
      final t = trending.first;
      if (t.memberCount > 0) {
        slides.add(_FeaturedSlide(
          kicker: 'TRENDING CLUB',
          title: t.name,
          subtitle: '${t.memberCount} member${t.memberCount == 1 ? '' : 's'} · ${t.focusArea}',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.warning,
          onTap: () => context.go('/clubs/${t.slug}'),
        ));
      }
    }

    if (widget.notices.isNotEmpty) {
      final n = widget.notices.first;
      slides.add(_FeaturedSlide(
        kicker: 'PINNED ANNOUNCEMENT',
        title: n.title,
        subtitle: n.body,
        icon: Icons.campaign_rounded,
        color: AppColors.primary,
        onTap: () => context.push(AppRoutes.notices),
      ));
    }

    if (widget.clubs.isNotEmpty) {
      final newest = [...widget.clubs]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final nw = newest.first;
      slides.add(_FeaturedSlide(
        kicker: 'NEW ON CLUBHUB',
        title: nw.name,
        subtitle: 'Just launched · ${nw.focusArea}',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.success,
        onTap: () => context.go('/clubs/${nw.slug}'),
      ));
    }

    return slides;
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides();
    if (slides.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _FeaturedCard(slide: slide),
              );
            },
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(slides.length, (i) {
                final isActive = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final _FeaturedSlide slide;
  const _FeaturedCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: slide.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [slide.color.withValues(alpha: 0.28), AppColors.surfaceDark],
          ),
          border: Border.all(color: slide.color.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(slide.icon, size: 120, color: slide.color.withValues(alpha: 0.12)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(slide.icon, size: 14, color: slide.color),
                    const SizedBox(width: 6),
                    Text(
                      slide.kicker,
                      style: TextStyle(color: slide.color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  slide.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  slide.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
