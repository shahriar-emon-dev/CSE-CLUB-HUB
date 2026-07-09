import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../features/admin/screens/create_club_screen.dart';
import '../../../models/club.dart';
import '../../../models/notice.dart';

import '../../../models/unified_feed_item.dart';
import '../../../features/home/providers/home_feed_provider.dart';
import '../../../features/notices/screens/notices_screen.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/clubs/providers/clubs_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/post_card.dart';
import '../widgets/event_card.dart';
import '../widgets/pinned_post_card.dart';

/// Main dashboard screen for the CSE Club Hub application.
/// 
/// This screen displays the unified feed (posts and events), active notices,
/// and quick actions based on the user's role (Admin, Executive, or Student).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  bool _showFollowing = true;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showAdminCreationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Create & Publish', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFF2E3192), shape: BoxShape.circle),
                    child: const Icon(Icons.hub, color: Colors.white, size: 20),
                  ),
                  title: const Text('New Club Space', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Create a new organization', style: TextStyle(color: AppColors.textSecondaryDark)),
                  onTap: () {
                    context.pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateClubScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFF007A8A), shape: BoxShape.circle),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 20),
                  ),
                  title: const Text('Publish Broadcast Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Share an update or notice', style: TextStyle(color: AppColors.textSecondaryDark)),
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.createPost);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFF912A34), shape: BoxShape.circle),
                    child: const Icon(Icons.event, color: Colors.white, size: 20),
                  ),
                  title: const Text('Schedule New Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Plan an upcoming session', style: TextStyle(color: AppColors.textSecondaryDark)),
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.createEvent);
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(homeFeedProvider);
    final noticesAsync = ref.watch(noticesProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final clubsAsync = ref.watch(clubsProvider);
    final followedClubsAsync = ref.watch(followedClubsProvider);

    final bool isLoading = feedAsync.isLoading || noticesAsync.isLoading || profileAsync.isLoading || clubsAsync.isLoading;
    final bool hasData = (feedAsync.valueOrNull?.isNotEmpty ?? false) ||
        (noticesAsync.valueOrNull?.isNotEmpty ?? false);
    
    final profile = profileAsync.valueOrNull;
    final bool isAdmin = profile?.isAdmin == true;
    final bool isExecutive = profile?.isExecutive == true;
    final bool canManagePosts = isAdmin || isExecutive;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14).withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text('ClubHub', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          if (canManagePosts)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () {
                if (isAdmin) {
                  _showAdminCreationModal(context);
                } else if (isExecutive) {
                  context.push(AppRoutes.createPost);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
            onPressed: () => context.push(AppRoutes.search),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: AppColors.textSecondaryDark),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              Positioned(
                top: 12, right: 12,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0D0D14), width: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withValues(alpha: 0.05), height: 1),
        ),
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (!hasData)
            _buildEmptyState()
          else
            _buildFeedState(
              feedAsync.valueOrNull ?? [],
              noticesAsync.valueOrNull ?? [],
              canManagePosts,
              clubsAsync.valueOrNull ?? [],
              followedClubsAsync.valueOrNull ?? [],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Abstract Center Visual
            SizedBox(
              width: 280, height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Glow
                  Container(
                    width: 280, height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 80)],
                    ),
                  ),
                  // Orbital System
                  RotationTransition(
                    turns: _animCtrl,
                    child: Container(
                      width: 280, height: 280,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 1.0, end: 0.0).animate(_animCtrl),
                    child: Container(
                      width: 210, height: 210,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5)),
                    ),
                  ),
                  // Central Graphic
                  Transform.rotate(
                    angle: 12 * 3.14159 / 180,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131F).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                    colors: [AppColors.primary.withValues(alpha: 0.2), Colors.transparent],
                                  ),
                                ),
                              ),
                              Icon(Icons.auto_awesome, size: 64, color: AppColors.primary.withValues(alpha: 0.8)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Floating Nodes
                  Positioned(top: 40, right: 40, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 10)]))),
                  Positioned(bottom: 80, left: 16, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle))),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text('Quiet in the Hub', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            const Text(
              "No posts yet — follow a club to get started and see what's happening in the CSE department.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 12,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              onPressed: () => context.push(AppRoutes.search),
              child: const Text('Explore Clubs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedState(List<UnifiedFeedItem> feed, List<Notice> notices, bool canManagePosts, List<Club> clubs, List<String> followedIds) {
    // Filter clubs to show in horizontal list
    final List<Club> displayClubs = _showFollowing 
        ? clubs.where((c) => followedIds.contains(c.id)).toList()
        : clubs;

    // Dynamically extract unique categories from available clubs
    final Set<String> categorySet = {'All'};
    for (var club in clubs) {
      categorySet.addAll(club.categories);
    }
    final List<String> filters = categorySet.toList()..sort((a, b) => a == 'All' ? -1 : (b == 'All' ? 1 : a.compareTo(b)));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: const SizedBox(height: 24)),
        
        // Discovery Controls
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segmented Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showFollowing = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: _showFollowing ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Following',
                            style: TextStyle(
                              color: _showFollowing ? const Color(0xFF571F00) : AppColors.textSecondaryDark,
                              fontWeight: _showFollowing ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showFollowing = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: !_showFollowing ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'All Clubs',
                            style: TextStyle(
                              color: !_showFollowing ? const Color(0xFF571F00) : AppColors.textSecondaryDark,
                              fontWeight: !_showFollowing ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedFilter == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filters[index],
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF571F00) : AppColors.textSecondaryDark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Followed Clubs Horizontal Scroll
        if (displayClubs.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: displayClubs.map((club) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildClubStory(club, 1.0),
                  );
                }).toList(),
              ),
            ),
          ),
        
        // Pinned Post
        if (notices.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: PinnedPostCard(notice: notices.first, showActions: canManagePosts),
            ),
          ),

        // Regular Posts (mixing events and blogs via unified feed)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = feed[index];
              if (item.type == UnifiedFeedItemType.event) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: EventCard(
                    item: item,
                    showActions: canManagePosts,
                  ),
                );
              } else if (item.type == UnifiedFeedItemType.post) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: PostCard(
                    item: item,
                    showActions: canManagePosts,
                  ),
                );
              }
              return null;
            },
            childCount: feed.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildClubStory(Club club, double opacity) {
    Color color = AppColors.primary;
    if (club.colorHex != null) {
      try {
        final hexCode = club.colorHex!.replaceAll('#', '');
        color = Color(int.parse('FF$hexCode', radix: 16));
      } catch (_) {}
    }

    IconData icon = Icons.group;
    if (club.iconName == 'psychology') {
      icon = Icons.psychology;
    } else if (club.iconName == 'terminal') {
      icon = Icons.terminal;
    } else if (club.iconName == 'memory') {
      icon = Icons.memory;
    } else if (club.iconName == 'brush') {
      icon = Icons.brush;
    } else if (club.iconName == 'developer_board') {
      icon = Icons.developer_board;
    } else if (club.iconName == 'admin_panel_settings') {
      icon = Icons.admin_panel_settings;
    }

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: () => context.go('/clubs/${club.slug}'),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF13131F),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    topRight: Radius.circular(2),
                    bottomLeft: Radius.circular(2),
                  ),
                ),
                child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: club.logoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(icon, color: color, size: 30),
                        errorWidget: (context, url, error) => Icon(icon, color: color, size: 30),
                      )
                    : Icon(icon, color: color, size: 30),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 64,
              child: Text(
                club.name, 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }




}
