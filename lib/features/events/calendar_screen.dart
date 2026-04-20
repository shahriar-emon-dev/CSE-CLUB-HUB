import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../shared/widgets/main_bottom_nav.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late final Stream<List<Map<String, dynamic>>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = _client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('is_cancelled', false)
        .order('event_datetime');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _eventsStream,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            final grouped = _groupEventsByDate(rows);
            final selectedEvents = _eventsForDay(grouped, _selectedDay);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: TableCalendar<Map<String, dynamic>>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2100, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                          calendarFormat: CalendarFormat.month,
                          eventLoader: (day) => _eventsForDay(grouped, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            markerDecoration: BoxDecoration(
                              color: AppColors.cta,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.cta,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors.cta.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Events on ${_dateLabel(_selectedDay)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (selectedEvents.isEmpty)
                              const Text(
                                'No events scheduled for this day.',
                                style: TextStyle(color: AppColors.textSecondary),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: selectedEvents.length,
                                separatorBuilder: (_, __) => const Divider(height: 16),
                                itemBuilder: (context, index) {
                                  final event = selectedEvents[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      event['title']?.toString() ?? 'Event',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      '${event['club']?['name']?.toString() ?? 'Club'} • ${event['venue']?.toString() ?? 'Venue TBA'}',
                                    ),
                                    trailing: Text(
                                      _timeLabel(event['event_datetime']?.toString()),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(activeRoute: AppRoutes.events),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupEventsByDate(List<Map<String, dynamic>> rows) {
    final grouped = <DateTime, List<Map<String, dynamic>>>{};

    for (final row in rows) {
      final dt = DateTime.tryParse(row['event_datetime']?.toString() ?? '');
      if (dt == null) continue;
      final key = DateTime(dt.year, dt.month, dt.day);
      final bucket = grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]);
      bucket.add(row);
    }

    return grouped;
  }

  List<Map<String, dynamic>> _eventsForDay(
    Map<DateTime, List<Map<String, dynamic>>> grouped,
    DateTime day,
  ) {
    return grouped[DateTime(day.year, day.month, day.day)] ?? const <Map<String, dynamic>>[];
  }

  String _dateLabel(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _timeLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
