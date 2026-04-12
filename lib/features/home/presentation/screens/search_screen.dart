import 'package:flutter/material.dart';

import '../../../../shared/widgets/post_card_widget.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search posts, clubs, events, users...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          SizedBox(height: 16),
          PostCardWidget(
            author: 'Search Result',
            club: 'Machine Learning Club',
            content: 'Neural network study jam this Saturday.',
            timestamp: '1d ago',
          ),
        ],
      ),
    );
  }
}
