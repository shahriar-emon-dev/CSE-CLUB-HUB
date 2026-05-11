import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/club_card_widget.dart';
import '../../../../shared/widgets/main_bottom_nav.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/create_post_card.dart';
import '../widgets/live_home_feed_section.dart';
import '../widgets/upcoming_events_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _refreshToken = 0;

  Future<void> _refreshHome() async {
    if (!mounted) return;
    setState(() => _refreshToken++);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final role = authState.role;
    final requestedExecutive = authState.profile?.roleRequest ?? false;
    final profile = authState.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : user?.email?.split('@').first ?? 'Student';

    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final dividerColor = isDark ? AppColors.darkInputBorder : const Color(0xFFDDDFE2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'CSE Club Hub',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.cta,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          _AppBarCircleButton(
            icon: Icons.search,
            onTap: () => context.push(AppRoutes.search),
            isDark: isDark,
          ),
          _AppBarCircleButton(
            icon: Icons.notifications_outlined,
            onTap: () => context.push(AppRoutes.notifications),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.cta,
        onRefresh: _refreshHome,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header + Quick Actions ──
                  Container(
                    color: cardColor,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Good to see you, $displayName',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Catch updates, events, and announcements from your clubs.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (role == AppUserRole.executive ||
                            role == AppUserRole.admin)
                          CreatePostCard(
                            displayName: displayName,
                            onCreatePressed: () => _showCreatePostComposer(
                              context,
                              onSuccess: _refreshHome,
                            ),
                            onImagePressed: () => _showCreatePostComposer(
                              context,
                              openImageHelp: true,
                              onSuccess: _refreshHome,
                            ),
                          ),
                        const SizedBox(height: 12),
                        _QuickActionRow(
                          role: role,
                          onCreatePost: () => _showCreatePostComposer(
                            context,
                            onSuccess: _refreshHome,
                          ),
                          onCreateEvent: () => _showCreateEventSheet(
                            context,
                            onSuccess: _refreshHome,
                          ),
                          onBrowseClubs: () => context.push(AppRoutes.clubs),
                          onViewEvents: () => context.push(AppRoutes.events),
                          onSavedPosts: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saved posts will be available soon.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor),

                  // ── Quick Stats Strip ──
                  Container(
                    color: cardColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: const [
                        _CompactStat(
                            label: 'Clubs', table: 'clubs', filter: null,
                            icon: Icons.groups_2_outlined),
                        SizedBox(width: 8),
                        _CompactStat(
                            label: 'Events', table: 'events',
                            filter: 'is_cancelled',
                            icon: Icons.event_outlined),
                        SizedBox(width: 8),
                        _CompactStat(
                            label: 'Posts', table: 'posts',
                            filter: 'is_deleted',
                            icon: Icons.article_outlined),
                      ],
                    ),
                  ),
                  _feedDivider(bgColor),

                  // ── Pending Executive Request Notice ──
                  if (requestedExecutive && role == AppUserRole.student) ...[
                    Container(
                      color: cardColor,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded,
                              color: AppColors.cta, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your executive request is pending admin approval.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _feedDivider(bgColor),
                  ],

                  // ── Upcoming Events (compact) ──
                  Container(
                    color: cardColor,
                    padding: const EdgeInsets.only(top: 14, bottom: 14),
                    child: UpcomingEventsSection(
                      key: ValueKey('upcoming-events-$_refreshToken'),
                    ),
                  ),
                  _feedDivider(bgColor),

                  // ── Live Feed ──
                  Container(
                    color: cardColor,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: LiveHomeFeedSection(
                      key: ValueKey('home-feed-$_refreshToken'),
                    ),
                  ),



                  // ── End of Feed ──
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 32,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'You\'re all caught up',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  static Widget _feedDivider(Color bgColor) {
    return Container(height: 8, color: bgColor);
  }
}

// ── AppBar circle icon button (Facebook-style) ──
class _AppBarCircleButton extends StatelessWidget {
  const _AppBarCircleButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isDark ? AppColors.darkSurfaceSoft : const Color(0xFFE4E6EB),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 22,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.role,
    required this.onCreatePost,
    required this.onCreateEvent,
    required this.onBrowseClubs,
    required this.onViewEvents,
    required this.onSavedPosts,
  });

  final AppUserRole? role;
  final VoidCallback onCreatePost;
  final VoidCallback onCreateEvent;
  final VoidCallback onBrowseClubs;
  final VoidCallback onViewEvents;
  final VoidCallback onSavedPosts;

  @override
  Widget build(BuildContext context) {
    final isCreator =
        role == AppUserRole.executive || role == AppUserRole.admin;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isCreator)
          _QuickActionChip(
            icon: Icons.edit_outlined,
            label: 'Create Post',
            onTap: onCreatePost,
          ),
        if (isCreator)
          _QuickActionChip(
            icon: Icons.event_available_outlined,
            label: 'Create Event',
            onTap: onCreateEvent,
          ),
        _QuickActionChip(
          icon: Icons.groups_outlined,
          label: 'Browse Clubs',
          onTap: onBrowseClubs,
        ),
        _QuickActionChip(
          icon: Icons.calendar_month_outlined,
          label: 'View Events',
          onTap: onViewEvents,
        ),
        _QuickActionChip(
          icon: Icons.bookmark_outline,
          label: 'Saved Posts',
          onTap: onSavedPosts,
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF3F4F6);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.cta),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact stat chip for the stats strip ──
class _CompactStat extends StatefulWidget {
  const _CompactStat({
    required this.label,
    required this.table,
    required this.filter,
    required this.icon,
  });
  final String label;
  final String table;
  final String? filter;
  final IconData icon;

  @override
  State<_CompactStat> createState() => _CompactStatState();
}

class _CompactStatState extends State<_CompactStat> {
  int _count = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      var q = Supabase.instance.client.from(widget.table).select('id');
      if (widget.filter != null) q = q.eq(widget.filter!, false);
      final r = await q.count(CountOption.exact);
      if (!mounted) return;
      setState(() { _count = r.count; _loaded = true; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 18,
                color: AppColors.cta),
            const SizedBox(width: 8),
            _loaded
                ? Text(
                    '$_count',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  )
                : const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
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
  VoidCallback? onSuccess,
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
                      initialValue: selectedClubId,
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
                  if (clubs.isNotEmpty) const SizedBox(height: 12),
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
                                  const SnackBar(
                                      content: Text(
                                          'Write something before posting.')),
                                );
                                return;
                              }

                              final user = client.auth.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Session expired. Please login again.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                final insertData = <String, dynamic>{
                                  'author_id': user.id,
                                  'content': content,
                                };
                                if (selectedClubId != null &&
                                    selectedClubId!.isNotEmpty) {
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
                                  final extension =
                                      _detectImageExtension(image.path);
                                  final objectPath =
                                      '${user.id}/$postId/${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
                                  final contentType =
                                      _contentTypeForExtension(extension);

                                  await client.storage
                                      .from('post-media')
                                      .uploadBinary(
                                        objectPath,
                                        bytes,
                                        fileOptions: FileOptions(
                                          upsert: false,
                                          contentType: contentType,
                                        ),
                                      );

                                  final publicUrl = client.storage
                                      .from('post-media')
                                      .getPublicUrl(objectPath);
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
                                onSuccess?.call();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Post published successfully.')),
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to publish post: $error')),
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

class _EventClubOption {
  const _EventClubOption({required this.id, required this.name});

  final String id;
  final String name;
}

Future<void> _showCreateEventSheet(
  BuildContext context, {
  VoidCallback? onSuccess,
}) async {
  final client = Supabase.instance.client;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();

  try {
    final clubsResponse = await client
        .from('clubs')
        .select('id,name')
        .eq('is_active', true)
        .order('name', ascending: true);

    final clubs = (clubsResponse as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map((row) => _EventClubOption(
              id: row['id'].toString(),
              name: row['name']?.toString() ?? 'Club',
            ))
        .toList();

    if (!context.mounted) return;

    if (clubs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active clubs available for event creation.')),
      );
      return;
    }

    String selectedClubId = clubs.first.id;
    DateTime? selectedDateTime;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickDateTime() async {
              final now = DateTime.now();
              final pickedDate = await showDatePicker(
                context: sheetContext,
                firstDate: now,
                lastDate: DateTime(now.year + 5),
                initialDate: selectedDateTime ?? now,
              );

              if (!sheetContext.mounted || pickedDate == null) return;

              final pickedTime = await showTimePicker(
                context: sheetContext,
                initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? now),
              );

              if (!sheetContext.mounted || pickedTime == null) return;

              setSheetState(() {
                selectedDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            Future<void> submit() async {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final venue = venueController.text.trim();

              if (title.isEmpty ||
                  description.isEmpty ||
                  venue.isEmpty ||
                  selectedDateTime == null) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Fill all fields before creating the event.')),
                );
                return;
              }

              final currentUser = client.auth.currentUser;
              if (currentUser == null) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Session expired. Please login again.')),
                );
                return;
              }

              setSheetState(() => isSubmitting = true);

              try {
                await client.from('events').insert({
                  'title': title,
                  'description': description,
                  'event_datetime': selectedDateTime!.toUtc().toIso8601String(),
                  'venue': venue,
                  'club_id': selectedClubId,
                  'created_by': currentUser.id,
                });

                if (!sheetContext.mounted) return;

                Navigator.of(sheetContext).pop();
                onSuccess?.call();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Event created successfully.')),
                );
              } catch (error) {
                if (!sheetContext.mounted) return;

                setSheetState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text('Failed to create event: $error')),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter event title',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Write event description',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: venueController,
                      decoration: const InputDecoration(
                        labelText: 'Venue',
                        hintText: 'Enter event venue',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClubId,
                      decoration: const InputDecoration(labelText: 'Club'),
                      items: clubs
                          .map(
                            (club) => DropdownMenuItem<String>(
                              value: club.id,
                              child: Text(club.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedClubId = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isSubmitting ? null : pickDateTime,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        selectedDateTime == null
                            ? 'Select event date and time'
                            : 'Selected: ${selectedDateTime!.toLocal()}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSubmitting ? null : submit,
                            child: Text(isSubmitting ? 'Creating...' : 'Create Event'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to load clubs: $error')),
    );
  } finally {
    titleController.dispose();
    descriptionController.dispose();
    venueController.dispose();
  }
}
