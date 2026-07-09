
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../models/event.dart';
import '../providers/clubs_provider.dart';
import '../providers/club_posts_provider.dart';
import '../../events/providers/events_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../home/widgets/post_actions_bottom_sheet.dart';

class ClubProfileScreen extends ConsumerStatefulWidget {
  final String clubId;
  const ClubProfileScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends ConsumerState<ClubProfileScreen> {
  // Tabs: Posts, Events
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(clubDetailProvider(widget.clubId));
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: clubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (club) {
          if (club == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/clubs');
            });
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, club),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExecutiveControlBar(context, ref, club),
                    _buildHeaderInfo(context, ref, club),
                    _buildBio(club),
                    _buildLeadership(club.id),
                    _buildTabs(),
                    _buildFeedContent(club.id),
                    const SizedBox(height: 100), // Bottom nav padding
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, dynamic club) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF13131F).withValues(alpha: 0.8),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          const Icon(Icons.hub, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('ClubHub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: AppColors.textSecondaryDark),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            club.coverImageUrl != null && club.coverImageUrl!.isNotEmpty
                ? Image.network(club.coverImageUrl!, fit: BoxFit.cover)
                : Container(color: const Color(0xFF13131F)),
            // Gradient Overlays
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF0D0D14),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            // Logo inside the bottom-left corner of the banner
            Positioned(
              bottom: 16,
              left: 20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(club.logoUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(
                          Icons.group,
                          color: AppColors.primary,
                          size: 40,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditClubModal(BuildContext context, WidgetRef ref, dynamic club) {
    showDialog(
      context: context,
      builder: (ctx) => _EditClubModalDialog(club: club),
    );
  }

  Widget _buildExecutiveControlBar(BuildContext context, WidgetRef ref, dynamic club) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final isAuthorized = profile.isSuperAdmin || profile.isAdmin || (profile.isExecutive && (profile.managedClubId == club.id || profile.clubId == club.id));
    if (!isAuthorized) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.tertiary.withValues(alpha: 0.15),
            const Color(0xFF1D100A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield, color: AppColors.tertiary, size: 20),
              SizedBox(width: 8),
              Text('EXECUTIVE CONTROL BAR', style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.createPost, extra: {'clubId': club.id}),
                icon: const Icon(Icons.post_add, size: 16),
                label: const Text('+ Create Post', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: const Color(0xFF412D00), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.createEvent, extra: {'clubId': club.id}),
                icon: const Icon(Icons.event_available, size: 16),
                label: const Text('+ Create Event', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, foregroundColor: const Color(0xFF1D100A), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              OutlinedButton.icon(
                onPressed: () => _openEditClubModal(context, ref, club),
                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                label: const Text('Edit Club Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.3)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  if (profile.isSuperAdmin) {
                    context.push(AppRoutes.adminExecutives);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact a Super Admin to modify executive roles for this club.')),
                    );
                  }
                },
                icon: const Icon(Icons.manage_accounts, size: 16, color: AppColors.tertiary),
                label: const Text('Manage Executives', style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.tertiary), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, WidgetRef ref, dynamic club) {
    // Safely extract categories to prevent cast errors
    final List<String> safeCategories = (club.categories as List<dynamic>?)?.whereType<String>().toList() ?? [];
    final followedList = ref.watch(followedClubsProvider).valueOrNull ?? [];
    final isFollowing = followedList.contains(club.id);
    final isFollowActionLoading = ref.watch(toggleClubMembershipProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      club.name?.toString().isNotEmpty == true ? club.name.toString() : 'Club Name Missing',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      safeCategories.isNotEmpty ? safeCategories.join(' • ') : 'CSE Club',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${club.memberCount ?? 0} members',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Dynamic Following / Follow Button
              InkWell(
                onTap: isFollowActionLoading
                    ? null
                    : () {
                        ref.read(toggleClubMembershipProvider.notifier).toggleMembership(club.id, isFollowing);
                      },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFollowing ? AppColors.primary.withValues(alpha: 0.1) : AppColors.tertiary,
                    borderRadius: BorderRadius.circular(20),
                    border: isFollowing ? Border.all(color: AppColors.primary) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFollowActionLoading) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                      ] else ...[
                        Icon(isFollowing ? Icons.check_circle : Icons.add_circle, color: isFollowing ? AppColors.primary : const Color(0xFF412D00), size: 16),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        isFollowing ? 'Following' : '+ Follow',
                        style: TextStyle(
                          color: isFollowing ? AppColors.primary : const Color(0xFF412D00),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBio(dynamic club) {
    if (club.description == null || club.description!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Text(
        club.description!,
        style: const TextStyle(
          color: Color(0xFFFDE4D0), // Light peach/orange tint
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildLeadership(String realClubId) {
    final leadershipAsync = ref.watch(clubExecutivesProvider(realClubId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text('Leadership', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 140,
          child: leadershipAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Center(child: Text('Failed to load', style: const TextStyle(color: Colors.red))),
            data: (leaders) {
              if (leaders.isEmpty) {
                return const Center(child: Text('No executives found', style: TextStyle(color: AppColors.textSecondaryDark)));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: leaders.length,
                separatorBuilder: (context, index) => const SizedBox(width: 24),
                itemBuilder: (context, index) {
                  final leader = leaders[index];
                  
                  return SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, Colors.blue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                            Container(
                              width: 76, height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceContainerDark,
                                border: Border.all(
                                  color: const Color(0xFF0D0D14),
                                  width: 2,
                                ),
                                image: leader.avatarUrl != null && leader.avatarUrl!.isNotEmpty ? DecorationImage(
                                  image: NetworkImage(leader.avatarUrl!),
                                  fit: BoxFit.cover,
                                ) : null,
                              ),
                              child: leader.avatarUrl == null || leader.avatarUrl!.isEmpty
                                  ? const Icon(Icons.person, color: AppColors.textSecondaryDark, size: 40)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          leader.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          leader.roleTitle,
                          style: const TextStyle(color: Color(0xFFFFB380), fontSize: 11, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1511), // dark warm brown
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton('Posts', 0),
            _buildTabButton('Events', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF571F00) : const Color(0xFFB39886),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedContent(String realClubId) {
    if (_selectedTabIndex == 1) {
      final eventsAsync = ref.watch(clubEventsProvider(realClubId));
      return eventsAsync.when(
        loading: () => const Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        )),
        error: (err, stack) => const Center(child: Text('Failed to load events', style: TextStyle(color: Colors.red))),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No events upcoming.', style: TextStyle(color: AppColors.textSecondaryDark)),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: events.map((event) => _buildEventCard(event)).toList(),
            ),
          );
        },
      );
    }
    
    final postsAsync = ref.watch(clubPostsProvider(realClubId));
    return postsAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColors.primary),
      )),
      error: (err, stack) => const Center(child: Text('Failed to load posts', style: TextStyle(color: Colors.red))),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No posts yet.', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: posts.map((post) {
              if (post.isPinned) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildPinnedPost(post),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildRegularPost(post),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(Event event) {
    final imageUrl = event.coverImageUrl ?? event.organizerAvatar;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 140,
                child: kIsWeb
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox())
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const SizedBox(),
                      ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (event.description != null && event.description!.isNotEmpty)
                  Text(
                    event.description!,
                    style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${event.eventDate.month}/${event.eventDate.day}/${event.eventDate.year}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedPost(dynamic post) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1C14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 24, left: 0,
            child: Container(width: 3, height: 20, color: AppColors.primary,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                color: AppColors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.push_pin, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('PINNED POST', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _formatDate(post.createdAt),
                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryDark),
                          onPressed: () => showPostActions(context, postId: post.id, isPinned: post.isPinned, currentContent: post.content, clubId: widget.clubId),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (post.content.isNotEmpty)
                  Text(
                    post.content,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                const SizedBox(height: 16),
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, color: AppColors.textSecondaryDark, size: 20),
                        const SizedBox(width: 8),
                        Text('${post.favoriteCount}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                        const SizedBox(width: 24),
                        const Icon(Icons.chat_bubble_outline, color: AppColors.textSecondaryDark, size: 20),
                        const SizedBox(width: 8),
                        Text('${post.commentCount}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                      ],
                    ),
                    const Icon(Icons.share, color: AppColors.textSecondaryDark, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildRegularPost(dynamic post) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1C14),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      image: post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty ? DecorationImage(
                        image: NetworkImage(post.authorAvatarUrl!),
                        fit: BoxFit.cover,
                      ) : null,
                    ),
                    child: post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty ? const Icon(Icons.person, color: AppColors.primary) : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(_formatDate(post.createdAt), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryDark),
                onPressed: () => showPostActions(context, postId: post.id, isPinned: post.isPinned, currentContent: post.content, clubId: widget.clubId),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.5),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border, color: Color(0xFFB39886), size: 20),
                  const SizedBox(width: 6),
                  Text('${post.favoriteCount}', style: const TextStyle(color: Color(0xFFB39886), fontSize: 14)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFFB39886), size: 20),
                  const SizedBox(width: 6),
                  Text('${post.commentCount}', style: const TextStyle(color: Color(0xFFB39886), fontSize: 14)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.share, color: Color(0xFFB39886), size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditClubModalDialog extends ConsumerStatefulWidget {
  final dynamic club;
  const _EditClubModalDialog({required this.club});

  @override
  ConsumerState<_EditClubModalDialog> createState() => _EditClubModalDialogState();
}

class _EditClubModalDialogState extends ConsumerState<_EditClubModalDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _categoriesCtrl;
  late TextEditingController _scheduleCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _logoCtrl;
  late TextEditingController _coverCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final club = widget.club;
    _nameCtrl = TextEditingController(text: club.name ?? '');
    _bioCtrl = TextEditingController(text: club.description ?? '');
    final List<String> cats = (club.categories as List<dynamic>?)?.whereType<String>().toList() ?? [];
    _categoriesCtrl = TextEditingController(text: cats.join(', '));
    _scheduleCtrl = TextEditingController(text: club.meetingSchedule ?? '');
    _locationCtrl = TextEditingController(text: club.location ?? '');
    _logoCtrl = TextEditingController(text: club.logoUrl ?? '');
    _coverCtrl = TextEditingController(text: club.coverImageUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _categoriesCtrl.dispose();
    _scheduleCtrl.dispose();
    _locationCtrl.dispose();
    _logoCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final cats = _categoriesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await ref.read(editClubNotifierProvider.notifier).updateClubProfile(
        widget.club.id,
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        categories: cats,
        meetingSchedule: _scheduleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        logoUrl: _logoCtrl.text.trim(),
        coverImageUrl: _coverCtrl.text.trim(),
      );
      ref.invalidate(clubDetailProvider(widget.club.id));
      ref.invalidate(clubsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club profile updated successfully.'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update club: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF13131F),
      title: const Text('Edit Club Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Club Name', _nameCtrl),
              const SizedBox(height: 12),
              _buildTextField('Bio / Description', _bioCtrl, maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField('Categories (comma separated)', _categoriesCtrl),
              const SizedBox(height: 12),
              _buildTextField('Meeting Schedule', _scheduleCtrl),
              const SizedBox(height: 12),
              _buildTextField('Location / Room', _locationCtrl),
              const SizedBox(height: 12),
              _buildTextField('Logo Image URL', _logoCtrl),
              const SizedBox(height: 12),
              _buildTextField('Cover Banner Image URL', _coverCtrl),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0D0D14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
        ),
      ],
    );
  }
}
