import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/club_card_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/event_card_widget.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/post_card_widget.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
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
                    title: 'Search Hub',
                    subtitle: 'Search posts, clubs, events, and people in one place.',
                    trailing: RoleBadge(
                      label: 'Search',
                      icon: Icons.search,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: 'Search all content',
                    hintText: 'Search posts, clubs, events, users...',
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Clubs', 'Events', 'Posts', 'People']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: _selectedCategory == value,
                            onSelected: (_) => setState(() => _selectedCategory = value),
                            selectedColor: AppColors.cta.withValues(alpha: 0.12),
                            labelStyle: TextStyle(
                              color: _selectedCategory == value ? AppColors.cta : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Top results',
                    subtitle: 'Representative cards for the current search experience.',
                  ),
                  const SizedBox(height: 12),
                  const ClubCardWidget(
                    name: 'Machine Learning Club',
                    description: 'AI, data science, and deep learning community.',
                    onTap: _noop,
                  ),
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'Search Result',
                    club: 'Machine Learning Club',
                    content: 'Neural network study jam this Saturday.',
                    timestamp: '1d ago',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Flutter UI Bootcamp',
                    date: 'Apr 20, 2026 - 3:00 PM',
                    venue: 'SMUCT Lab 2',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'People matches',
                    subtitle: 'Useful when no search category is selected.',
                  ),
                  const SizedBox(height: 12),
                  const EmptyState(
                    title: 'No exact person matches yet',
                    message: 'Search by name, student ID, or email to find members across the club network.',
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

void _noop() {}
