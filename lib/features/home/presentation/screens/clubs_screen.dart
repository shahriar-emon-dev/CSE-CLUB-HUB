import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/club_card_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';
import '../widgets/confirm_action_dialog.dart';

class _ClubUiItem {
  const _ClubUiItem({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}

const _clubUiItems = [
  _ClubUiItem(
    name: 'Machine Learning Club',
    description: 'AI, data science, and deep learning community.',
  ),
  _ClubUiItem(
    name: 'Competitive Programming Club',
    description: 'Algorithms, contests, and problem solving.',
  ),
  _ClubUiItem(
    name: 'IoT & Robotics Club',
    description: 'Embedded systems and automation projects.',
  ),
  _ClubUiItem(
    name: 'Web Development Club',
    description: 'Frontend, backend, and full-stack engineering.',
  ),
  _ClubUiItem(
    name: 'Software Development Club',
    description: 'Application design and product engineering.',
  ),
  _ClubUiItem(
    name: 'Cyber Security Club',
    description: 'Security, ethical hacking, and cryptography.',
  ),
];

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  late final Set<int> _followedClubIndexes;
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _followedClubIndexes = <int>{};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(int index) async {
    if (_followedClubIndexes.contains(index)) {
      final shouldUnfollow = await showConfirmActionDialog(
        context,
        title: 'Unfollow this club?',
        message: 'You will no longer see this club in your personalized feed.',
        confirmLabel: 'Unfollow',
        isDestructive: true,
      );

      if (shouldUnfollow != true) return;
    }

    setState(() {
      if (_followedClubIndexes.contains(index)) {
        _followedClubIndexes.remove(index);
      } else {
        _followedClubIndexes.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleClubs = _clubUiItems.asMap().entries.where((entry) {
      final matchesFilter = _selectedFilter == 'All' ||
          entry.value.name.contains(_selectedFilter) ||
          entry.value.description.contains(_selectedFilter);
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          entry.value.name.toLowerCase().contains(query) ||
          entry.value.description.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clubs'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppHeader(
                    title: 'Explore Clubs',
                    subtitle: 'Follow clubs to personalize your feed and event suggestions.',
                    trailing: RoleBadge(
                      label: 'Browse',
                      icon: Icons.groups_2_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 3 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns == 2 ? 1.8 : 1.5,
                        children: const [
                          StatsCard(label: 'Clubs', value: '6', icon: Icons.groups_2_outlined),
                          StatsCard(label: 'Following', value: '2', icon: Icons.favorite_border),
                          StatsCard(label: 'Events', value: '24', icon: Icons.event_outlined),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: 'Search clubs',
                    hintText: 'Type a club name or description',
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _FilterChips(
                    selectedValue: _selectedFilter,
                    onSelected: (value) => setState(() => _selectedFilter = value),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Popular clubs',
                    subtitle: 'Discover student communities worth following.',
                  ),
                  const SizedBox(height: 12),
                  if (visibleClubs.isEmpty)
                    const EmptyState(
                      title: 'No clubs matched your filters',
                      message: 'Try a broader search or switch the filter back to All.',
                    )
                  else
                    ...visibleClubs.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClubCardWidget(
                          name: entry.value.name,
                          description: entry.value.description,
                          isFollowing: _followedClubIndexes.contains(entry.key),
                          onTap: () => context.push(AppRoutes.clubProfile),
                          onFollowToggle: () => _toggleFollow(entry.key),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'No-data state',
                    subtitle: 'Useful when a user has not followed any club yet.',
                  ),
                  const SizedBox(height: 12),
                  const EmptyState(
                    title: 'You are not following more clubs yet',
                    message: 'Follow a few clubs to unlock a tailored feed and event suggestions.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedValue,
    required this.onSelected,
  });

  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'ML', 'Web', 'IoT', 'Security'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters
          .map(
            (value) => ChoiceChip(
              label: Text(value),
              selected: selectedValue == value,
              onSelected: (_) => onSelected(value),
              selectedColor: AppColors.cta.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: selectedValue == value ? AppColors.cta : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          .toList(),
    );
  }
}
