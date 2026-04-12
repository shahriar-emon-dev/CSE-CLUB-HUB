import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/post_card_widget.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

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
      appBar: AppBar(title: const Text('Club Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(
            title: 'Web Development Club',
            subtitle: 'Build modern web applications and collaborate on projects.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              setState(() => _isFollowing = !_isFollowing);
            },
            icon: Icon(_isFollowing ? Icons.check : Icons.add),
            label: Text(_isFollowing ? 'Following' : 'Follow Club'),
          ),
          SizedBox(height: 16),
          const Text(
            'Executive Members',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('President, Vice President, Secretary, Executive Members'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Posts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const PostCardWidget(
            author: 'Club Executive',
            club: 'Web Development Club',
            content: 'Workshop on Flutter UI architecture this Friday at 3 PM.',
            timestamp: '2h ago',
          ),
        ],
      ),
    );
  }
}
