import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/event_card_widget.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppHeader(
            title: 'Upcoming Events',
            subtitle: 'Track club activities and RSVP in one place.',
          ),
          SizedBox(height: 16),
          EventCardWidget(
            title: 'Flutter UI Bootcamp',
            date: 'Apr 20, 2026 - 3:00 PM',
            venue: 'SMUCT Lab 2',
          ),
          SizedBox(height: 12),
          EventCardWidget(
            title: 'Cyber Security Talk',
            date: 'Apr 24, 2026 - 11:00 AM',
            venue: 'Auditorium',
          ),
        ],
      ),
    );
  }
}
