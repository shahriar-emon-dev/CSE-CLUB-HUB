import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class EventCardWidget extends StatelessWidget {
  const EventCardWidget({
    required this.title,
    required this.date,
    required this.venue,
    this.onGoing,
    this.onInterested,
    super.key,
  });

  final String title;
  final String date;
  final String venue;
  final VoidCallback? onGoing;
  final VoidCallback? onInterested;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              venue,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: onInterested, child: const Text('Interested')),
                FilledButton(onPressed: onGoing, child: const Text('Going')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
