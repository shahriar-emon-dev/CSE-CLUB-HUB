import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/events_provider.dart';
import '../../../models/event.dart';

enum EventFilterTab { all, upcoming, today, past, myHistory }

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

Future<void> showInteractiveCalendarModal(
  BuildContext context, {
  required DateTime initialDate,
  required Set<DateTime> eventDates,
  required Function(DateTime) onDateSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _CalendarModalContent(
      initialDate: initialDate,
      eventDates: eventDates,
      onDateSelected: onDateSelected,
    ),
  );
}

class _CalendarModalContent extends StatefulWidget {
  final DateTime initialDate;
  final Set<DateTime> eventDates;
  final Function(DateTime) onDateSelected;

  const _CalendarModalContent({
    required this.initialDate,
    required this.eventDates,
    required this.onDateSelected,
  });

  @override
  State<_CalendarModalContent> createState() => _CalendarModalContentState();
}

class _CalendarModalContentState extends State<_CalendarModalContent> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final weekdayOffset = (firstDayOfMonth.weekday % 7);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: const Border(top: BorderSide(color: Color(0x33FFFFFF))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(now.year, now.month, 1);
                        _selectedDate = DateTime(now.year, now.month, now.day);
                      });
                      widget.onDateSelected(_selectedDate);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((d) => 
              SizedBox(
                width: 38,
                child: Center(
                  child: Text(d, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: weekdayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < weekdayOffset) {
                return const SizedBox.shrink();
              }
              final dayNum = index - weekdayOffset + 1;
              final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
              final isSelected = cellDate.year == _selectedDate.year && cellDate.month == _selectedDate.month && cellDate.day == _selectedDate.day;
              final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
              final hasEvent = widget.eventDates.any((e) => e.year == cellDate.year && e.month == cellDate.month && e.day == cellDate.day);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = cellDate);
                  widget.onDateSelected(cellDate);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : (isToday ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF1D100A) : Colors.white,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      if (hasEvent) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1D100A) : const Color(0xFFFF6A00),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  final ScrollController _dateStripController = ScrollController();
  EventFilterTab _selectedTab = EventFilterTab.all;
  bool _sortNewestFirst = true;
  DateTime? _filterByDate;

  @override
  void dispose() {
    _dateStripController.dispose();
    super.dispose();
  }

  List<DateTime> _getRollingWeek(DateTime anchor) {
    return List.generate(7, (index) => anchor.subtract(const Duration(days: 3)).add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isExecutiveOrAdmin = profileAsync.valueOrNull?.isExecutive == true || profileAsync.valueOrNull?.isAdmin == true;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      floatingActionButton: isExecutiveOrAdmin
          ? FloatingActionButton(
              onPressed: () => context.go('/events/create'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Color(0xFF571F00)),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterTabsRow(),
                    const SizedBox(height: 20),
                    _buildAgendaHeader(),
                    const SizedBox(height: 16),
                    if (_filterByDate != null) _buildFilterDateBanner(),
                    _buildAgendaList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.hub, color: AppColors.primary, size: 28),
              SizedBox(width: 8),
              Text('ClubHub', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            ],
          ),
          IconButton(icon: const Icon(Icons.notifications, color: AppColors.textSecondaryDark), onPressed: () => context.push(AppRoutes.notifications)),
        ],
      ),
    ).wrapWithBlur(20);
  }

  Widget _buildFilterTabsRow() {
    final tabs = [
      ('All', EventFilterTab.all),
      ('Upcoming', EventFilterTab.upcoming),
      ('Today', EventFilterTab.today),
      ('Past', EventFilterTab.past),
      ('My History', EventFilterTab.myHistory),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab.$2 && _filterByDate == null;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = tab.$2;
                  if (tab.$2 == EventFilterTab.today) {
                    final now = DateTime.now();
                    _filterByDate = DateTime(now.year, now.month, now.day);
                  } else {
                    _filterByDate = null;
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  tab.$1,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF1D100A) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgendaHeader() {
    final eventsAsync = ref.watch(eventsProvider);
    final allEvents = eventsAsync.valueOrNull ?? [];
    final eventDates = allEvents.map((e) => DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day)).toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Events Agenda',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _sortNewestFirst = !_sortNewestFirst;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sort, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _sortNewestFirst ? 'Newest' : 'Oldest',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                showInteractiveCalendarModal(
                  context,
                  initialDate: _filterByDate ?? DateTime.now(),
                  eventDates: eventDates,
                  onDateSelected: (date) {
                    setState(() {
                      _filterByDate = date;
                      ref.read(selectedDateProvider.notifier).state = date;
                    });
                  },
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _filterByDate != null ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _filterByDate != null ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.calendar_month, color: AppColors.primary, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Calendar',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDateBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Showing events for ${DateFormat('MMM d, yyyy').format(_filterByDate!)}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          InkWell(
            onTap: () => setState(() => _filterByDate = null),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    final selectedDate = ref.watch(selectedDateProvider);
    final weekDates = _getRollingWeek(DateTime.now());
    final monthYearFormatter = DateFormat('MMMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('Scheduled Events', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            Text(monthYearFormatter.format(selectedDate), style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          controller: _dateStripController,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: weekDates.map((date) => _buildDateItem(date, selectedDate)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateItem(DateTime date, DateTime selectedDate) {
    final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
    final dayName = DateFormat('E').format(date);
    final dayNum = DateFormat('d').format(date);

    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).state = date;
        setState(() => _filterByDate = date);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6A00) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.15), blurRadius: 20)] : null,
        ),
        child: Column(
          children: [
            Text(
              dayName.toUpperCase(),
              style: TextStyle(
                color: isSelected ? const Color(0xFF571F00) : AppColors.textSecondaryDark,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNum,
              style: TextStyle(
                color: isSelected ? const Color(0xFF571F00) : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaList() {
    final eventsAsync = ref.watch(eventsProvider);
    final rsvpsAsync = ref.watch(myAllRsvpsProvider);

    return eventsAsync.when(
      data: (events) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final rsvps = rsvpsAsync.valueOrNull ?? {};

        List<Event> filteredEvents = events.where((e) {
          if (_filterByDate != null) {
            return e.eventDate.year == _filterByDate!.year &&
                   e.eventDate.month == _filterByDate!.month &&
                   e.eventDate.day == _filterByDate!.day;
          }
          switch (_selectedTab) {
            case EventFilterTab.all:
              return true;
            case EventFilterTab.upcoming:
              return e.eventDate.isAfter(today) || (e.eventDate.year == today.year && e.eventDate.month == today.month && e.eventDate.day == today.day);
            case EventFilterTab.today:
              return e.eventDate.year == today.year && e.eventDate.month == today.month && e.eventDate.day == today.day;
            case EventFilterTab.past:
              return e.eventDate.isBefore(today);
            case EventFilterTab.myHistory:
              final st = rsvps[e.id];
              return st == RsvpStatus.confirmed;
          }
        }).toList();

        // Sort
        filteredEvents.sort((a, b) {
          if (_sortNewestFirst) {
            return b.eventDate.compareTo(a.eventDate);
          } else {
            return a.eventDate.compareTo(b.eventDate);
          }
        });

        if (filteredEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _filterByDate != null
                        ? 'No events scheduled for ${DateFormat('MMM d, yyyy').format(_filterByDate!)}.'
                        : 'No events found in this category.',
                    style: const TextStyle(color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: filteredEvents.map((event) {
            final userStatus = rsvps[event.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildTicketCard(event: event, userStatus: userStatus),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: AppColors.primary))),
      error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
    );
  }

  Widget _buildTicketCard({required Event event, required RsvpStatus? userStatus}) {
    final isGoing = userStatus == RsvpStatus.confirmed;
    final isInterested = userStatus == RsvpStatus.interested;
    final isUpdating = ref.watch(rsvpNotifierProvider).isLoading;

    final dateStr = DateFormat('EEE, d MMM').format(event.eventDate);
    final startStr = DateFormat('HH:mm').format(event.eventDate);
    final endStr = event.endDate != null ? DateFormat('HH:mm').format(event.endDate!) : 'TBD';

    return GestureDetector(
      onTap: () => context.go('/events/${event.id}'),
      child: Stack(
        children: [
          ClipPath(
            clipper: TicketClipper(),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2B1C16), // surface-container
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Image Area
                    SizedBox(
                      width: 128,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (event.coverImageUrl != null)
                            ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      1, 0,
                              ]), // Grayscale filter manually applied (can use ImageFilter but this works)
                              child: Image.network(
                                event.coverImageUrl!, 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFF1D100A),
                                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
                                ),
                              ),
                            )
                          else
                            Container(color: AppColors.primary.withValues(alpha: 0.1)),
                        ],
                      ),
                    ),
                    
                    // Middle Content Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                    image: event.organizerAvatar != null ? DecorationImage(image: NetworkImage(event.organizerAvatar!), fit: BoxFit.cover) : null,
                                  ),
                                  child: event.organizerAvatar == null ? const Icon(Icons.group, size: 14, color: AppColors.primary) : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(event.organizerName ?? 'General', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildIconText(Icons.calendar_today, dateStr),
                                _buildIconText(Icons.schedule, '$startStr - $endStr'),
                                _buildIconText(Icons.location_on, event.venue ?? 'TBA'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group, color: AppColors.primary, size: 14),
                                  const SizedBox(width: 4),
                                  Text('${event.rsvpCount ?? 0} attending', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Dashed Perforation Line
                    CustomPaint(
                      size: const Size(1, double.infinity),
                      painter: DashedLinePainter(color: Colors.white.withValues(alpha: 0.1)),
                    ),

                    // Right Actions Area
                    Container(
                      width: 120,
                      color: const Color(0xFF261812).withValues(alpha: 0.5), // surface-container-low
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            icon: Icons.check_circle,
                            label: 'Going',
                            isActive: isGoing,
                            isPrimary: true,
                            onTap: isUpdating ? null : () => _handleRsvp(event.id, RsvpStatus.confirmed, isGoing),
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.star,
                            label: 'Interest',
                            isActive: isInterested,
                            isPrimary: false,
                            onTap: isUpdating ? null : () => _handleRsvp(event.id, RsvpStatus.interested, isInterested),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Hover overlay effect to restore color (can't easily do it natively without state, but we can just use an InkWell)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go('/events/${event.id}'),
                highlightColor: Colors.white.withValues(alpha: 0.05),
                splashColor: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondaryDark, size: 14),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isPrimary,
    required VoidCallback? onTap,
  }) {
    final bgColor = isActive 
        ? (isPrimary ? const Color(0xFFFF6A00) : AppColors.surfaceVariantDark.withValues(alpha: 0.3)) 
        : Colors.transparent;
    final fgColor = isActive
        ? (isPrimary ? const Color(0xFF571F00) : AppColors.textSecondaryDark)
        : AppColors.textSecondaryDark;
    final shadowColor = isActive && isPrimary ? const Color(0xFFFF6A00).withValues(alpha: 0.3) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: shadowColor != Colors.transparent ? [BoxShadow(color: shadowColor, blurRadius: 10)] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fgColor, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: fgColor, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRsvp(String eventId, RsvpStatus targetStatus, bool isCurrentlyActive) async {
    final notifier = ref.read(rsvpNotifierProvider.notifier);
    if (isCurrentlyActive) {
      await notifier.cancelRsvp(eventId);
    } else {
      await notifier.updateRsvp(eventId, targetStatus);
    }
    if (!mounted) return;
    ref.invalidate(myAllRsvpsProvider);
    ref.invalidate(eventsProvider); // To refresh counts
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    var max = size.height;
    var dashWidth = 8.0;
    var dashSpace = 4.0;
    double startY = 0;
    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    
    // Add semicircles on the sides to create the perforated ticket look
    final double holeRadius = 12.0;
    
    // Left hole (optional, but matching HTML CSS mask)
    path.addOval(Rect.fromCircle(center: Offset(0, size.height / 2), radius: holeRadius));
    
    // Right hole
    path.addOval(Rect.fromCircle(center: Offset(size.width, size.height / 2), radius: holeRadius));

    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

extension _BlurExtension on Widget {
  Widget wrapWithBlur(double sigma, [double radius = 16.0]) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: this,
      ),
    );
  }
}
