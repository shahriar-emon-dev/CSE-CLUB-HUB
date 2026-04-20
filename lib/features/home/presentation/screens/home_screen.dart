import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/club_card_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/main_bottom_nav.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/create_post_card.dart';
import '../widgets/live_home_feed_section.dart';
import '../widgets/upcoming_events_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final role = authState.role;
    final requestedExecutive = authState.profile?.roleRequest ?? false;
    final profile = authState.profile;

    final roleLabel = switch (role) {
      AppUserRole.admin => 'Admin',
      AppUserRole.executive => 'Executive',
      AppUserRole.student => 'Student',
    };

    final displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : user?.email?.split('@').first ?? 'Student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CSE Club Hub'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(
                    title: 'Welcome back, $displayName',
                    subtitle: 'Role: $roleLabel • stay on top of your club activity.',
                    trailing: const RoleBadge(
                      label: 'Live',
                      icon: Icons.bolt,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientMiddle,
                          AppColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'CSE Club Hub',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Your feed, events, clubs, and admin tools in one polished workspace.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.dashboard_customize_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 500 ? 3 : 2;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: columns,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: columns == 2 ? 2.1 : 1.7,
                              children: const [
                                _MiniStat(label: 'Clubs', value: '6'),
                                _MiniStat(label: 'Events', value: '24'),
                                _MiniStat(label: 'Posts', value: '128'),
                                _MovingHighlightCard(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (requestedExecutive && role == AppUserRole.student)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: const Text(
                        'Executive request is pending admin approval.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  if (requestedExecutive && role == AppUserRole.student)
                    const SizedBox(height: 16),
                  const UpcomingEventsSection(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  const SectionHeader(
                    title: 'Your Profile',
                    subtitle: 'A compact summary of your student identity.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          label: 'Batch',
                          value: profile?.batch ?? '—',
                          icon: Icons.class_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          label: 'Section',
                          value: profile?.section ?? '—',
                          icon: Icons.segment,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SectionHeader(
                    title: 'Featured Feed',
                    subtitle: 'A few recent club updates to keep the home screen lively.',
                  ),
                  const SizedBox(height: 12),
                  CreatePostCard(
                    displayName: displayName,
                    onCreatePressed: () {
                      _showCreatePostComposer(context);
                    },
                    onImagePressed: () {
                      _showCreatePostComposer(context, openImageHelp: true);
                    },
                  ),
                  const SizedBox(height: 12),
                  const LiveHomeFeedSection(),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Recommended Clubs',
                    subtitle: 'Follow clubs to personalize your feed.',
                  ),
                  const SizedBox(height: 12),
                  ClubCardWidget(
                    name: 'Machine Learning Club',
                    description: 'AI, data science, and deep learning community.',
                    isFollowing: true,
                    onTap: _noop,
                  ),
                  const SizedBox(height: 12),
                  ClubCardWidget(
                    name: 'Cyber Security Club',
                    description: 'Security, ethical hacking, and cryptography.',
                    onTap: _noop,
                  ),
                  const SizedBox(height: 16),
                  const EmptyState(
                    title: 'No more updates right now',
                    message: 'New posts, events, and notifications will appear here as clubs publish them.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(
        activeRoute: AppRoutes.home,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovingHighlightCard extends StatefulWidget {
  const _MovingHighlightCard();

  @override
  State<_MovingHighlightCard> createState() => _MovingHighlightCardState();
}

class _MovingHighlightCardState extends State<_MovingHighlightCard> {
  final SupabaseClient _client = Supabase.instance.client;

  Timer? _ticker;
  Timer? _refreshTicker;
  int _activeIndex = 0;
  bool _isLoading = true;

  List<({String title, String subtitle, IconData icon, String route})> _highlights = const [
    (
      title: 'Loading updates',
      subtitle: 'Pulling upcoming and trending highlights...',
      icon: Icons.bolt_outlined,
      route: AppRoutes.events,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHighlights();

    _ticker = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _activeIndex = (_activeIndex + 1) % _highlights.length;
      });
    });

    _refreshTicker = Timer.periodic(const Duration(seconds: 45), (_) {
      _loadHighlights(isSilentRefresh: true);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _refreshTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadHighlights({bool isSilentRefresh = false}) async {
    if (!isSilentRefresh && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);

    try {
      final upcomingEvent = await _client
          .from('events')
          .select('title,event_datetime,venue')
          .eq('is_cancelled', false)
          .gte('event_datetime', now.toIso8601String())
          .order('event_datetime', ascending: true)
          .limit(1)
          .maybeSingle();

      final postsTodayResponse = await _client
          .from('posts')
          .select('id')
          .eq('is_deleted', false)
          .gte('created_at', startOfDay.toIso8601String())
          .count(CountOption.exact);

      final upcomingEventsResponse = await _client
          .from('events')
          .select('id')
          .eq('is_cancelled', false)
          .gte('event_datetime', now.toIso8601String())
          .count(CountOption.exact);

      final rsvpsResponse = await _client
          .from('rsvps')
          .select('id')
          .count(CountOption.exact);

      final postsToday = postsTodayResponse.count;
      final upcomingEvents = upcomingEventsResponse.count;
      final rsvpCount = rsvpsResponse.count;

      final highlights = <({String title, String subtitle, IconData icon, String route})>[];

      if (upcomingEvent != null) {
        final eventTitle = (upcomingEvent['title']?.toString().trim().isNotEmpty ?? false)
            ? upcomingEvent['title'].toString().trim()
            : 'Upcoming Event';
        final eventTime = _formatEventTime(upcomingEvent['event_datetime']?.toString());
        final venue = upcomingEvent['venue']?.toString().trim() ?? '';

        highlights.add((
          title: eventTitle,
          subtitle: venue.isEmpty ? eventTime : '$eventTime - $venue',
          icon: Icons.event_available_outlined,
          route: AppRoutes.events,
        ));
      }

      highlights.add((
        title: '$postsToday posts today',
        subtitle: 'Fresh updates are flowing in your feed',
        icon: Icons.campaign_outlined,
        route: AppRoutes.search,
      ));

      highlights.add((
        title: '$upcomingEvents upcoming events',
        subtitle: '$rsvpCount total RSVPs across clubs',
        icon: Icons.trending_up_outlined,
        route: AppRoutes.calendar,
      ));

      if (!mounted) return;

      setState(() {
        _highlights = highlights;
        _activeIndex = _activeIndex % _highlights.length;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _highlights = const [
          (
            title: 'Live insights unavailable',
            subtitle: 'Showing rotating card. Data will retry automatically.',
            icon: Icons.wifi_off_outlined,
            route: AppRoutes.events,
          ),
        ];
        _activeIndex = 0;
        _isLoading = false;
      });
    }
  }

  String _formatEventTime(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return 'Soon';
    final parsed = DateTime.tryParse(rawIso)?.toLocal();
    if (parsed == null) return 'Soon';

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final item = _highlights[_activeIndex];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(item.route),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'What\'s Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.12, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey(item.title),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              Row(
                children: List.generate(_highlights.length, (index) {
                  final isActive = _activeIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 4),
                    width: isActive ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _noop() {}

Future<void> _showCreatePostComposer(
  BuildContext context, {
  bool openImageHelp = false,
}) async {
  final textController = TextEditingController();
  final imageController = TextEditingController();
  final previewUrls = <String>[];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compose your club update with text and optional image URLs.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: textController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Write something...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(
                      hintText: openImageHelp
                          ? 'Paste image URL for preview'
                          : 'Optional image URL',
                      suffixIcon: IconButton(
                        onPressed: () {
                          final value = imageController.text.trim();
                          if (value.isEmpty) return;
                          setModalState(() => previewUrls.add(value));
                          imageController.clear();
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (previewUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: previewUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              previewUrls[index],
                              width: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 140,
                                color: AppColors.surfaceSoft,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Post draft saved locally. Submit integration can be connected to the posts API.'),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cta,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Post'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

