import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

// ==========================================
// GLOBAL CONSTANTS AND CONFIGURATION
// ==========================================

const _kEventCardHeight = 172.0;

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class UpcomingEventsSection extends StatefulWidget {
  const UpcomingEventsSection({super.key});

  @override
  State<UpcomingEventsSection> createState() => _UpcomingEventsSectionState();
}

class _UpcomingEventsSectionState extends State<UpcomingEventsSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(AppRoutes.events),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('events')
              .stream(primaryKey: const ['id'])
              .gt('event_datetime', nowIso)
              .order('event_datetime', ascending: true)
              .limit(10),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <Map<String, dynamic>>[];

            if (snapshot.connectionState == ConnectionState.waiting && rows.isEmpty) {
              return const _UpcomingEventsLoadingState();
            }

            if (rows.isEmpty) {
              return const _UpcomingEventsEmptyState();
            }

            return FutureBuilder<Map<String, _ClubMeta>>(
              future: _loadClubMeta(rows),
              builder: (context, clubSnapshot) {
                final clubMeta = clubSnapshot.data ?? const <String, _ClubMeta>{};
                final events = rows.map((row) => _UpcomingEvent.fromRow(row, clubMeta)).toList();

                if (events.isEmpty) {
                  return const _UpcomingEventsEmptyState();
                }

                if (events.length == 1) {
                  return SizedBox(
                    height: _kEventCardHeight,
                    child: _UpcomingEventCard(
                      event: events.first,
                      onRsvp: () => context.push(AppRoutes.events),
                    ),
                  );
                }

                if (_currentPage >= events.length) {
                  _currentPage = 0;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: _kEventCardHeight,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: events.length,
                        onPageChanged: (value) {
                          setState(() => _currentPage = value);
                        },
                        itemBuilder: (context, index) {
                          return _UpcomingEventCard(
                            event: events[index],
                            onRsvp: () => context.push(AppRoutes.events),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(events.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 18 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.cta : AppColors.inputBorder,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, _ClubMeta>> _loadClubMeta(List<Map<String, dynamic>> eventsRows) async {
    final ids = eventsRows
        .map((row) => row['club_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return const {};

    final response = await Supabase.instance.client
        .from('clubs')
        .select('id,name,logo_url')
        .inFilter('id', ids);

    final rows = response as List;

    final result = <String, _ClubMeta>{};

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;

      result[id] = _ClubMeta(
        name: row['name']?.toString() ?? 'Club',
        logoUrl: row['logo_url']?.toString(),
      );
    }

    return result;
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({
    required this.event,
    required this.onRsvp,
  });

  final _UpcomingEvent event;
  final VoidCallback onRsvp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceSoft,
                foregroundImage: event.clubLogoUrl != null && event.clubLogoUrl!.isNotEmpty
                    ? NetworkImage(event.clubLogoUrl!)
                    : null,
                child: event.clubLogoUrl == null || event.clubLogoUrl!.isEmpty
                    ? const Icon(Icons.groups_2_outlined, size: 16, color: AppColors.textSecondary)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.clubName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.formattedDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (event.venue.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onRsvp,
              child: const Text('RSVP'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventsLoadingState extends StatelessWidget {
  const _UpcomingEventsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kEventCardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _UpcomingEventsEmptyState extends StatelessWidget {
  const _UpcomingEventsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy_outlined, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'No upcoming events yet. Check back later!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingEvent {
  const _UpcomingEvent({
    required this.title,
    required this.clubName,
    required this.eventDateTime,
    required this.venue,
    this.clubLogoUrl,
  });

  final String title;
  final String clubName;
  final DateTime eventDateTime;
  final String venue;
  final String? clubLogoUrl;

  String get formattedDate => DateFormat('EEE, MMM d • h:mm a').format(eventDateTime.toLocal());

  static _UpcomingEvent fromRow(
    Map<String, dynamic> row,
    Map<String, _ClubMeta> clubMeta,
  ) {
    final clubId = row['club_id']?.toString();
    final club = clubId == null ? null : clubMeta[clubId];

    final eventDateTime = DateTime.tryParse(row['event_datetime']?.toString() ?? '') ?? DateTime.now();

    return _UpcomingEvent(
      title: row['title']?.toString() ?? 'Untitled Event',
      clubName: club?.name ?? 'Club',
      eventDateTime: eventDateTime,
      venue: row['venue']?.toString() ?? '',
      clubLogoUrl: club?.logoUrl,
    );
  }
}

class _ClubMeta {
  const _ClubMeta({required this.name, this.logoUrl});

  final String name;
  final String? logoUrl;
}
