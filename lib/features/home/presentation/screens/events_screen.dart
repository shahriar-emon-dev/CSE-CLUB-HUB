import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/event_card_widget.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'Upcoming';

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
        title: const Text('Events'),
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
                    title: 'Upcoming Events',
                    subtitle: 'Track club activities and RSVP in one place.',
                    trailing: RoleBadge(
                      label: 'Calendar',
                      icon: Icons.event_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 2 : 1;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 3.6 : 2.0,
                        children: const [
                          StatsCard(label: 'Upcoming', value: '12', icon: Icons.event_available_outlined),
                          StatsCard(label: 'Registered', value: '3', icon: Icons.check_circle_outline),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: 'Search events',
                    hintText: 'Find events by title or venue',
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Upcoming', 'Today', 'This Week', 'Past']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: _selectedFilter == value,
                            onSelected: (_) => setState(() => _selectedFilter = value),
                            selectedColor: AppColors.cta.withValues(alpha: 0.12),
                            labelStyle: TextStyle(
                              color: _selectedFilter == value ? AppColors.cta : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Featured events',
                    subtitle: 'A clean event timeline with RSVP-ready cards.',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Flutter UI Bootcamp',
                    date: 'Apr 20, 2026 - 3:00 PM',
                    venue: 'SMUCT Lab 2',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Cyber Security Talk',
                    date: 'Apr 24, 2026 - 11:00 AM',
                    venue: 'Auditorium',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Project Showcase Day',
                    date: 'May 02, 2026 - 1:00 PM',
                    venue: 'Innovation Hall',
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Open Calendar View',
                    icon: Icons.calendar_month_outlined,
                    isPrimary: true,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'No-data state',
                    subtitle: 'Displayed when no events match the current filter.',
                  ),
                  const SizedBox(height: 12),
                  const EmptyState(
                    title: 'No events available',
                    message: 'Try another filter or search query. New events will appear as clubs publish them.',
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
