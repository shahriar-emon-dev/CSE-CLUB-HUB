import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/main_bottom_nav.dart';
import '../../../../shared/widgets/post_card_widget.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';
import '../widgets/confirm_action_dialog.dart';

class ClubProfileScreen extends StatefulWidget {
  const ClubProfileScreen({super.key});

  @override
  State<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends State<ClubProfileScreen> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(
                    title: 'Web Development Club',
                    subtitle: 'Build modern web applications and collaborate on projects.',
                    trailing: const RoleBadge(
                      label: 'Featured',
                      icon: Icons.groups_2_outlined,
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
                        const Text(
                          'Club Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Stay updated with membership, events, and the latest club posts.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: StatsCard(
                                label: 'Members',
                                value: '316',
                                icon: Icons.groups_2_outlined,
                                accentColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatsCard(
                                label: 'Posts',
                                value: '48',
                                icon: Icons.post_add_outlined,
                                accentColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: _isFollowing ? 'Following' : 'Follow Club',
                    icon: _isFollowing ? Icons.check_circle_outline : Icons.add,
                    isPrimary: true,
                    onPressed: () async {
                      if (_isFollowing) {
                        final shouldUnfollow = await showConfirmActionDialog(
                          context,
                          title: 'Unfollow this club?',
                          message: 'You will stop receiving this club’s updates in your personalized feed.',
                          confirmLabel: 'Unfollow',
                          isDestructive: true,
                        );

                        if (shouldUnfollow != true) return;
                      }

                      setState(() => _isFollowing = !_isFollowing);
                    },
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Executive Members',
                    subtitle: 'A compact view of the club leadership structure.',
                  ),
                  const SizedBox(height: 12),
                  const EmptyState(
                    title: 'Leadership roster preview',
                    message: 'President, Vice President, Secretary, and executive members are shown here in the final data-connected version.',
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Recent Posts',
                    subtitle: 'Latest updates from the club timeline.',
                  ),
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'Club Executive',
                    club: 'Web Development Club',
                    content: 'Workshop on Flutter UI architecture this Friday at 3 PM.',
                    timestamp: '2h ago',
                  ),
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'Club Executive',
                    club: 'Web Development Club',
                    content: 'Git and GitHub collaboration clinic will start next Monday.',
                    timestamp: '6h ago',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Club Actions',
                    subtitle: 'The UI is ready for member actions and follow management.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unfollow confirmation keeps the UI safe for accidental taps without changing your existing logic.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(
        activeRoute: AppRoutes.clubs,
      ),
    );
  }
}
