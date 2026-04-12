import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/club_card_widget.dart';

// ==========================================
// GLOBAL CONSTANTS AND CONFIGURATION
// ==========================================

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
    description: 'AI, Data Science, and Deep Learning community.',
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

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  late final Set<int> _followedClubIndexes;

  @override
  void initState() {
    super.initState();
    _followedClubIndexes = <int>{};
  }

  void _toggleFollow(int index) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Clubs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(
            title: 'Explore Clubs',
            subtitle: 'Follow clubs to personalize your feed.',
          ),
          const SizedBox(height: 16),
          ..._clubUiItems.asMap().entries.map(
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
        ],
      ),
    );
  }
}
