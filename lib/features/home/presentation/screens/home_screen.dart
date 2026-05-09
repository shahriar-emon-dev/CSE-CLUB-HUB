import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
      appBar: AppBar(
        title: const Text('CSE Club Hub'),
        surfaceTintColor: Colors.transparent,
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
                                _LiveMiniStat(label: 'Clubs', table: 'clubs', filter: null),
                                _LiveMiniStat(label: 'Events', table: 'events', filter: 'is_cancelled'),
                                _LiveMiniStat(label: 'Posts', table: 'posts', filter: 'is_deleted'),
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
                  if (role == AppUserRole.executive || role == AppUserRole.admin)
                    CreatePostCard(
                      displayName: displayName,
                      onCreatePressed: () {
                        _showCreatePostComposer(context);
                      },
                      onImagePressed: () {
                        _showCreatePostComposer(context, openImageHelp: true);
                      },
                    ),
                  if (role == AppUserRole.executive || role == AppUserRole.admin)
                    const SizedBox(height: 12),
                  const LiveHomeFeedSection(),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Recommended Clubs',
                    subtitle: 'Follow clubs to personalize your feed.',
                  ),
                  const SizedBox(height: 12),
                  const _LiveClubsList(),
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

class _LiveMiniStat extends StatefulWidget {
  const _LiveMiniStat({required this.label, required this.table, required this.filter});

  final String label;
  final String table;
  final String? filter; // Column name where false = active (e.g. 'is_deleted', 'is_cancelled')

  @override
  State<_LiveMiniStat> createState() => _LiveMiniStatState();
}

class _LiveMiniStatState extends State<_LiveMiniStat> {
  int _count = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchCount();
  }

  Future<void> _fetchCount() async {
    try {
      var query = Supabase.instance.client
          .from(widget.table)
          .select('id');

      if (widget.filter != null) {
        query = query.eq(widget.filter!, false);
      }

      final response = await query.count(CountOption.exact);
      if (!mounted) return;
      setState(() {
        _count = response.count;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

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
          _loaded
              ? Text(
                  '$_count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            widget.label,
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

// _LiveClubsList: Fetches clubs from the database and displays them with follow/unfollow.
class _LiveClubsList extends StatefulWidget {
  const _LiveClubsList();

  @override
  State<_LiveClubsList> createState() => _LiveClubsListState();
}

class _LiveClubsListState extends State<_LiveClubsList> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _clubs = const [];
  Set<String> _followedClubIds = const {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      final user = _client.auth.currentUser;
      final clubsData = await _client
          .from('clubs')
          .select('id, name, description')
          .eq('is_active', true)
          .order('name')
          .limit(6);

      Set<String> followedIds = {};
      if (user != null) {
        final follows = await _client
            .from('user_club_follows')
            .select('club_id')
            .eq('user_id', user.id);
        followedIds = (follows as List)
            .map((row) => (row as Map)['club_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      }

      if (!mounted) return;
      setState(() {
        _clubs = List<Map<String, dynamic>>.from(clubsData as List);
        _followedClubIds = followedIds;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(String clubId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final isFollowing = _followedClubIds.contains(clubId);
    setState(() {
      if (isFollowing) {
        _followedClubIds = Set.from(_followedClubIds)..remove(clubId);
      } else {
        _followedClubIds = Set.from(_followedClubIds)..add(clubId);
      }
    });

    try {
      if (isFollowing) {
        await _client
            .from('user_club_follows')
            .delete()
            .eq('user_id', user.id)
            .eq('club_id', clubId);
      } else {
        await _client
            .from('user_club_follows')
            .insert({'user_id': user.id, 'club_id': clubId});
      }
    } catch (_) {
      // Revert on failure
      if (!mounted) return;
      setState(() {
        if (isFollowing) {
          _followedClubIds = Set.from(_followedClubIds)..add(clubId);
        } else {
          _followedClubIds = Set.from(_followedClubIds)..remove(clubId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clubs.isEmpty) {
      return const Text(
        'No clubs available yet.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: _clubs.map((club) {
        final clubId = club['id']?.toString() ?? '';
        final isFollowing = _followedClubIds.contains(clubId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClubCardWidget(
            name: club['name']?.toString() ?? 'Club',
            description: club['description']?.toString() ?? '',
            isFollowing: isFollowing,
            onTap: () => context.push(AppRoutes.clubProfile),
            onFollowToggle: () => _toggleFollow(clubId),
          ),
        );
      }).toList(),
    );
  }
}

Future<void> _showCreatePostComposer(
  BuildContext context, {
  bool openImageHelp = false,
}) async {
  final client = Supabase.instance.client;
  final imagePicker = ImagePicker();
  final textController = TextEditingController();
  final imageController = TextEditingController();
  final previewUrls = <String>[];
  final pickedImages = <XFile>[];
  bool isSubmitting = false;
  String? selectedClubId;
  List<Map<String, dynamic>> clubs = [];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      // Load clubs for the selector
      client
          .from('clubs')
          .select('id, name')
          .eq('is_active', true)
          .order('name')
          .then((data) {
        clubs = List<Map<String, dynamic>>.from(data as List);
      }).catchError((_) {});

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
                    'Compose your club update with text and optional images.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Club selector
                  if (clubs.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedClubId,
                      decoration: InputDecoration(
                        hintText: 'Select a club',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: clubs.map((club) {
                        return DropdownMenuItem<String>(
                          value: club['id']?.toString(),
                          child: Text(club['name']?.toString() ?? 'Club'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() => selectedClubId = value);
                      },
                    ),
                  if (clubs.isNotEmpty)
                    const SizedBox(height: 12),
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
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final images = await imagePicker.pickMultiImage(
                              imageQuality: 85,
                              maxWidth: 1400,
                            );
                            if (images.isEmpty) return;
                            setModalState(() {
                              pickedImages.addAll(images);
                            });
                          },
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      pickedImages.isEmpty
                          ? 'Upload photos'
                          : 'Uploaded ${pickedImages.length} photo(s)',
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
                  if (pickedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pickedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Image ${index + 1}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
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
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final content = textController.text.trim();
                              if (content.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Write something before posting.')),
                                );
                                return;
                              }

                              final user = client.auth.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Session expired. Please login again.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                final insertData = <String, dynamic>{
                                  'author_id': user.id,
                                  'content': content,
                                };
                                if (selectedClubId != null && selectedClubId!.isNotEmpty) {
                                  insertData['club_id'] = selectedClubId;
                                }

                                final insertedPost = await client
                                    .from('posts')
                                    .insert(insertData)
                                    .select('id')
                                    .single();

                                final postId = insertedPost['id'].toString();
                                final mediaUrls = <String>[];

                                for (final url in previewUrls) {
                                  final trimmed = url.trim();
                                  if (trimmed.isNotEmpty) {
                                    mediaUrls.add(trimmed);
                                  }
                                }

                                for (var i = 0; i < pickedImages.length; i++) {
                                  final image = pickedImages[i];
                                  final bytes = await image.readAsBytes();
                                  final extension = _detectImageExtension(image.path);
                                  final objectPath = '${user.id}/$postId/${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
                                  final contentType = _contentTypeForExtension(extension);

                                  await client.storage.from('post-media').uploadBinary(
                                        objectPath,
                                        bytes,
                                        fileOptions: FileOptions(
                                          upsert: false,
                                          contentType: contentType,
                                        ),
                                      );

                                  final publicUrl = client.storage.from('post-media').getPublicUrl(objectPath);
                                  mediaUrls.add(publicUrl);
                                }

                                if (mediaUrls.isNotEmpty) {
                                  final rows = mediaUrls
                                      .map((url) => {
                                            'post_id': postId,
                                            'media_url': url,
                                            'media_type': 'image',
                                          })
                                      .toList();

                                  await client.from('post_media').insert(rows);
                                }

                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Post published successfully.')),
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to publish post: $error')),
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cta,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isSubmitting ? 'Posting...' : 'Post'),
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

String _detectImageExtension(String path) {
  final normalized = path.toLowerCase();
  if (normalized.endsWith('.png')) return 'png';
  if (normalized.endsWith('.webp')) return 'webp';
  if (normalized.endsWith('.gif')) return 'gif';
  return 'jpg';
}

String _contentTypeForExtension(String extension) {
  switch (extension) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    default:
      return 'image/jpeg';
  }
}

