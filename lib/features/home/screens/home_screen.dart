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
import '../widgets/post_card.dart';
import '../widgets/event_card.dart';
import '../widgets/pinned_post_card.dart';
import '../widgets/home_header.dart';
import '../widgets/feed_switcher.dart';
import '../widgets/club_discovery_carousel.dart';
import '../widgets/featured_banner.dart';
import '../widgets/feed_skeleton.dart';

/// Main dashboard screen for the CSE Club Hub application.
///
/// Displays the unified feed (posts and events), club discovery, featured
/// highlights, active notices, and quick actions based on the user's role.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final ScrollController _scrollController = ScrollController();
  bool _showFollowing = true;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 600;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(homeFeedProvider.notifier).loadMore();
    }
  }

  void _showAdminCreationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.hub, color: Colors.white, size: 20),
                  ),
                  title: const Text('New Club Space', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Create a new organization', style: TextStyle(color: AppColors.textSecondaryDark)),
                  onTap: () {
                    context.pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateClubScreen()));
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle),
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
                    decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(homeFeedProvider);
    final noticesAsync = ref.watch(noticesProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final clubsAsync = ref.watch(clubsProvider);
    final followedClubsAsync = ref.watch(followedClubsProvider);

    final bool isInitialLoading = feedState.isLoading || profileAsync.isLoading;
    final bool hasData = feedState.items.isNotEmpty || (noticesAsync.valueOrNull?.isNotEmpty ?? false);

    final profile = profileAsync.valueOrNull;
    final bool isAdmin = profile?.isAdmin == true;
    final bool isExecutive = profile?.isExecutive == true;
    final bool canManagePosts = isAdmin || isExecutive;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          HomeHeader(
            profile: profile,
            canManagePosts: canManagePosts,
            isAdmin: isAdmin,
            isExecutive: isExecutive,
            onCreateTap: () {
              if (isAdmin) {
                _showAdminCreationModal(context);
              } else if (isExecutive) {
                context.push(AppRoutes.createPost);
              }
            },
          ),
          Expanded(
            child: isInitialLoading
                ? const FeedSkeleton()
                : (feedState.error != null && feedState.items.isEmpty)
                    ? _buildErrorState()
                    : !hasData
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            backgroundColor: AppColors.surfaceDark,
                            onRefresh: () => ref.read(homeFeedProvider.notifier).refresh(),
                            child: _buildFeed(
                              feedState.items,
                              feedState.isLoadingMore,
                              noticesAsync.valueOrNull ?? [],
                              canManagePosts,
                              clubsAsync.valueOrNull ?? [],
                              followedClubsAsync.valueOrNull ?? [],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textTertiaryDark),
            const SizedBox(height: 20),
            const Text('Couldn\'t load your feed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => ref.read(homeFeedProvider.notifier).refresh(),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 80)],
                    ),
                  ),
                  RotationTransition(
                    turns: _animCtrl,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 1.0, end: 0.0).animate(_animCtrl),
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5)),
                    ),
                  ),
                  Transform.rotate(
                    angle: 12 * 3.14159 / 180,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.8),
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
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
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

  Widget _buildFeed(
    List<UnifiedFeedItem> feed,
    bool isLoadingMore,
    List<Notice> notices,
    bool canManagePosts,
    List<Club> clubs,
    List<String> followedIds,
  ) {
    final List<Club> displayClubs = _showFollowing ? clubs.where((c) => followedIds.contains(c.id)).toList() : clubs;

    final Set<String> categorySet = {'All'};
    for (final club in clubs) {
      categorySet.addAll(club.categories);
    }
    final filters = categorySet.toList()..sort((a, b) => a == 'All' ? -1 : (b == 'All' ? 1 : a.compareTo(b)));

    final List<UnifiedFeedItem> filteredFeed;
    if (_selectedFilter == 0 || _selectedFilter >= filters.length) {
      filteredFeed = feed;
    } else {
      final selectedCategory = filters[_selectedFilter];
      final clubsById = {for (final c in clubs) c.id: c};
      filteredFeed = feed.where((item) {
        final club = item.clubId != null ? clubsById[item.clubId] : null;
        return club != null && club.categories.contains(selectedCategory);
      }).toList();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: FeedSwitcherHeaderDelegate(
            child: FeedSwitcher(
              showFollowing: _showFollowing,
              onFollowingChanged: (v) => setState(() => _showFollowing = v),
              filters: filters,
              selectedFilter: _selectedFilter,
              onFilterChanged: (i) => setState(() => _selectedFilter = i),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (displayClubs.isNotEmpty)
          SliverToBoxAdapter(
            child: ClubDiscoveryCarousel(clubs: displayClubs, followedIds: followedIds),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FeaturedBanner(feed: feed, clubs: clubs, notices: notices),
          ),
        ),
        if (notices.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: PinnedPostCard(notice: notices.first, showActions: canManagePosts),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = filteredFeed[index];
              final card = item.type == UnifiedFeedItemType.event
                  ? EventCard(item: item, showActions: canManagePosts)
                  : PostCard(item: item, showActions: canManagePosts);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: card,
              );
            },
            childCount: filteredFeed.length,
          ),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
