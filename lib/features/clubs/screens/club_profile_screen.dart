
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
                    _buildHeaderInfo(club),
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

  Widget _buildHeaderInfo(dynamic club) {
    // Safely extract categories to prevent cast errors
    final List<String> safeCategories = (club.categories as List<dynamic>?)?.whereType<String>().toList() ?? [];

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
              // Following Status Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text('Following', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
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
                    Text(
                      _formatDate(post.createdAt),
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)
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
              IconButton(icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryDark), onPressed: () {}),
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
