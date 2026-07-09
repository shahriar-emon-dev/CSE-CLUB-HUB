import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/event.dart';
import '../../events/screens/create_event_screen.dart';
import '../providers/admin_providers.dart';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminEventsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Campus Event Moderation',
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review, cancel, or remove upcoming and past club events across campus nodes.',
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const CreateEventScreen()));
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: const Color(0xFF412D00),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search events by title, organizer, or location...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
                prefixIcon: const Icon(Icons.search, color: AppColors.tertiary),
                filled: true,
                fillColor: AppColors.surfaceContainerDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            eventsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(64),
                child: CircularProgressIndicator(color: AppColors.tertiary),
              )),
              error: (err, st) => Center(child: Text('Failed to load events: $err', style: const TextStyle(color: AppColors.error))),
              data: (events) {
                final filtered = events.where((e) =>
                  e.title.toLowerCase().contains(_searchQuery) ||
                  (e.organizerName ?? '').toLowerCase().contains(_searchQuery) ||
                  (e.venue ?? '').toLowerCase().contains(_searchQuery)
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64),
                      child: Text('No events found matching your filter.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1100 ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final event = filtered[index];
                        return _buildEventCard(event);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: event.isCancelled ? AppColors.error.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(color: event.isCancelled ? AppColors.error : Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: event.isCancelled ? TextDecoration.lineThrough : null),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (event.isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('CANCELLED', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_pin, color: AppColors.tertiary, size: 16),
                  const SizedBox(width: 6),
                  Text('By: ${event.organizerName}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.tertiary, size: 14),
                  const SizedBox(width: 6),
                  Text('${event.eventDate.month}/${event.eventDate.day}/${event.eventDate.year}', style: const TextStyle(color: AppColors.tertiary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.description ?? 'No description provided.',
                style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!event.isCancelled)
                TextButton.icon(
                  onPressed: () => _cancelOrDelete(event, isDelete: false),
                  icon: const Icon(Icons.cancel, color: AppColors.error, size: 18),
                  label: const Text('Cancel Event', style: TextStyle(color: AppColors.error)),
                ),
              IconButton(
                onPressed: () => _cancelOrDelete(event, isDelete: true),
                icon: const Icon(Icons.delete_forever, color: AppColors.textSecondaryDark, size: 22),
                tooltip: 'Permanently Delete Event',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _cancelOrDelete(Event event, {required bool isDelete}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D100A),
        title: Text(isDelete ? 'Delete Event?' : 'Cancel Event?'),
        content: Text(isDelete ? 'Are you sure you want to permanently delete "${event.title}"?' : 'Mark "${event.title}" as cancelled? Attendees will see the cancellation note.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Go Back', style: TextStyle(color: AppColors.textSecondaryDark))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).cancelOrDeleteEvent(event.id, isDelete: isDelete);
                ref.invalidate(adminEventsListProvider);
                ref.invalidate(dashboardStatsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(isDelete ? 'Delete Forever' : 'Confirm Cancel'),
          ),
        ],
      ),
    );
  }
}
