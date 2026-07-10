import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/user_profile.dart';

class UserDashboardView extends ConsumerWidget {
  final UserProfile profile;
  final int followedClubsCount;
  final int rsvpsCount;

  const UserDashboardView({
    super.key,
    required this.profile,
    this.followedClubsCount = 3,
    this.rsvpsCount = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_customize, color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STUDENT DASHBOARD',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Welcome back, ${profile.fullName.split(" ").first}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 14, color: AppColors.textSecondaryDark),
                    SizedBox(width: 6),
                    Text('REGULAR STUDENT', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),

          // 4 Interaction Metrics
          const Text('My Campus Activity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.2,
            children: [
              _buildMetricBox('Events Attended', rsvpsCount.toString(), Icons.event_available, const Color(0xFF4CAF50), 'Upcoming & completed'),
              _buildMetricBox('Clubs Followed', followedClubsCount.toString(), Icons.hub, const Color(0xFF2196F3), 'Receiving notifications'),
              _buildMetricBox('Posts Saved', '12', Icons.bookmark_added, const Color(0xFFFF9800), 'Bookmarked feed posts'),
              _buildMetricBox('Comments Made', '28', Icons.forum, const Color(0xFF9C27B0), 'Active discussions'),
            ],
          ),
          const SizedBox(height: 28),

          // 6 Quick Actions
          const Text('Quick Student Actions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionItem(
                context,
                icon: Icons.explore,
                label: 'Explore Events',
                color: AppColors.primary,
                onTap: () => context.go(AppRoutes.events),
              ),
              _buildActionItem(
                context,
                icon: Icons.group_work,
                label: 'Browse Clubs',
                color: const Color(0xFF00BCD4),
                onTap: () => context.go(AppRoutes.clubs),
              ),
              _buildActionItem(
                context,
                icon: Icons.history,
                label: 'My RSVP History',
                color: const Color(0xFF4CAF50),
                onTap: () => context.go(AppRoutes.events),
              ),
              _buildActionItem(
                context,
                icon: Icons.person_outline,
                label: 'Edit Profile',
                color: const Color(0xFFFF9800),
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              _buildActionItem(
                context,
                icon: Icons.notifications_active_outlined,
                label: 'Notification Preferences',
                color: const Color(0xFF9C27B0),
                onTap: () => context.push(AppRoutes.notifications),
              ),
              _buildActionItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Account Settings',
                color: const Color(0xFFE91E63),
                onTap: () => context.push(AppRoutes.editProfile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
