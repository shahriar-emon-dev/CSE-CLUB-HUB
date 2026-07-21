import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/user_profile.dart';
import '../../notifications/screens/notifications_screen.dart';

/// Floating, frosted header for the home feed: greeting + avatar, unread
/// notification badge (backed by the real notificationsProvider, not a
/// static dot), a tappable search affordance, and a quick-create action for
/// executives/admins.
class HomeHeader extends ConsumerWidget {
  final UserProfile? profile;
  final bool canManagePosts;
  final bool isAdmin;
  final bool isExecutive;
  final VoidCallback onCreateTap;

  const HomeHeader({
    super.key,
    required this.profile,
    required this.canManagePosts,
    required this.isAdmin,
    required this.isExecutive,
    required this.onCreateTap,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;
    final firstName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim().split(' ').first
        : 'there';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 20, right: 20, bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.bgDark.withValues(alpha: 0.72),
            border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.profile),
                    child: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: AppColors.surfaceDark,
                          child: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                              ? CachedNetworkImage(imageUrl: profile!.avatarUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.person, color: AppColors.textSecondaryDark, size: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          firstName,
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (canManagePosts) ...[
                    _HeaderIconButton(
                      icon: Icons.add_rounded,
                      filled: true,
                      onTap: onCreateTap,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _HeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                    badgeCount: unreadCount,
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.push(AppRoutes.search),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.textTertiaryDark, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Search clubs, events, people…',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final int badgeCount;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, color: filled ? Colors.white : AppColors.textSecondaryDark, size: 22),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.bgDark, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
