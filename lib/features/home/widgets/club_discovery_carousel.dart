import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/club.dart';
import '../../clubs/providers/clubs_provider.dart';

/// Horizontal carousel of glassmorphism club cards: logo, name, live member
/// count, and a follow-state pill wired to the real follow/unfollow RPC.
class ClubDiscoveryCarousel extends ConsumerWidget {
  final List<Club> clubs;
  final List<String> followedIds;

  const ClubDiscoveryCarousel({super.key, required this.clubs, required this.followedIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (clubs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: clubs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final club = clubs[index];
          final isFollowing = followedIds.contains(club.id);
          return _ClubGlassCard(club: club, isFollowing: isFollowing);
        },
      ),
    );
  }
}

class _ClubGlassCard extends ConsumerWidget {
  final Club club;
  final bool isFollowing;

  const _ClubGlassCard({required this.club, required this.isFollowing});

  Color _accentColor() {
    if (club.colorHex == null) return AppColors.primary;
    try {
      return Color(int.parse('FF${club.colorHex!.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _accentColor();
    final followState = ref.watch(followClubNotifierProvider);

    return GestureDetector(
      onTap: () => context.go('/clubs/${club.slug}'),
      child: Container(
        width: 148,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withValues(alpha: 0.22), AppColors.surfaceDark],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(color: Colors.white.withValues(alpha: 0.02)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(imageUrl: club.logoUrl!, fit: BoxFit.cover)
                        : Icon(Icons.groups_rounded, color: accent, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    club.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${club.memberCount} member${club.memberCount == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: followState.isLoading
                        ? null
                        : () => ref.read(followClubNotifierProvider.notifier).toggleMembership(club.id, isFollowing),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isFollowing ? Colors.white.withValues(alpha: 0.08) : accent,
                        borderRadius: BorderRadius.circular(8),
                        border: isFollowing ? Border.all(color: Colors.white.withValues(alpha: 0.15)) : null,
                      ),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: isFollowing ? Colors.white.withValues(alpha: 0.8) : Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
}
