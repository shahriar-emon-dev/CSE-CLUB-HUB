
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

import '../providers/clubs_provider.dart';
import '../../../../models/club.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClubsDiscoveryScreen extends ConsumerWidget {
  const ClubsDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider);
    final followedClubsAsync = ref.watch(followedClubsProvider);


    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    clubsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (err, stack) => Center(child: Text('Error loading clubs: $err')),
                      data: (clubs) {
                        if (clubs.isEmpty) {
                          return const Center(child: Text('No clubs available.', style: TextStyle(color: AppColors.textSecondaryDark)));
                        }
                        final followedIds = followedClubsAsync.valueOrNull ?? [];
                        return _buildClubsGrid(clubs, followedIds, ref);
                      },
                    ),
                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.hub, color: AppColors.primary, size: 28),
              SizedBox(width: 8),
              Text('ClubHub', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.search, color: AppColors.textSecondaryDark), onPressed: () {}),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.notifications, color: AppColors.textSecondaryDark), onPressed: () {}),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Discover Clubs', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        SizedBox(height: 8),
        Text('Find your community and explore specialized creative collectives within the CSE ecosystem.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.5)),
      ],
    );
  }

  Widget _buildClubsGrid(List<Club> clubs, List<String> followedIds, WidgetRef ref) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 300, // Fixed height prevents overflow on narrow screens
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: clubs.length,
      itemBuilder: (context, index) {
        final club = clubs[index];
        final isFollowing = followedIds.contains(club.id);
        return _buildClubCard(
          context: context,
          ref: ref,
          club: club,
          isFollowing: isFollowing,
          isExecutive: false,
        );
      },
    );
  }

  Widget _buildClubCard({
    required BuildContext context,
    required WidgetRef ref,
    required Club club,
    required bool isFollowing,
    bool isExecutive = false,
  }) {
    // Parse color or fallback to primary
    Color cardColor = AppColors.primary;
    if (club.colorHex != null) {
      try {
        final hexCode = club.colorHex!.replaceAll('#', '');
        cardColor = Color(int.parse('FF$hexCode', radix: 16));
      } catch (_) {}
    }

    final isActionLoading = ref.watch(followClubNotifierProvider).isLoading;

    return GestureDetector(
      onTap: () => context.go('/clubs/${club.slug}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardColor.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Banner & Avatar)
            SizedBox(
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner Image
                  Positioned.fill(
                    child: club.coverImageUrl != null && club.coverImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: club.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: cardColor.withValues(alpha: 0.1)),
                            errorWidget: (context, url, error) => Container(color: cardColor.withValues(alpha: 0.1)),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cardColor.withValues(alpha: 0.4),
                                  cardColor.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                  ),
                  
                  // Gradient Overlay for Banner
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1A1A24).withValues(alpha: 0.8),
                            const Color(0xFF1A1A24),
                          ],
                          stops: const [0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Avatar Overlapping Banner
                  Positioned(
                    left: 16,
                    bottom: -20,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A36),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1A1A24), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: club.logoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Icon(Icons.groups, color: cardColor),
                                errorWidget: (context, url, error) => Icon(Icons.groups, color: cardColor),
                              )
                            : Icon(Icons.groups, color: cardColor, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Section (Text & Button)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      club.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Bio
                    Text(
                      club.description ?? 'A CSE ClubHub Community',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Members Metric
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, color: cardColor.withValues(alpha: 0.7), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${club.memberCount} members',
                          style: TextStyle(
                            color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: isFollowing
                          ? OutlinedButton(
                              onPressed: isActionLoading ? null : () async {
                                await ref.read(followClubNotifierProvider.notifier).unfollow(club.id);
                                ref.invalidate(followedClubsProvider);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: cardColor.withValues(alpha: 0.5)),
                                foregroundColor: cardColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Following', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            )
                          : ElevatedButton(
                              onPressed: isActionLoading ? null : () async {
                                await ref.read(followClubNotifierProvider.notifier).follow(club.id);
                                ref.invalidate(followedClubsProvider);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cardColor,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
