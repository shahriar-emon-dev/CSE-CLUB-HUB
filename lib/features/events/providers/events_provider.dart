import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/event.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/events_repository.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository();
});

// All published events
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:events';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_rsvps',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final repository = ref.read(eventsRepositoryProvider);
  return repository.getPublishedEvents();
});

// Club specific events
final clubEventsProvider = FutureProvider.family<List<Event>, String>((ref, clubId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:club_events:$clubId';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_rsvps',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final repository = ref.read(eventsRepositoryProvider);
  return repository.getClubEvents(clubId);
});

// Single event detail
final eventDetailProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;

  final channelName = 'public:event_detail:$eventId';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_rsvps',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final repository = ref.read(eventsRepositoryProvider);
  return repository.getEventById(eventId);
});

// User's RSVP status for an event
final myRsvpProvider = StreamProvider.family<EventRsvp?, String>((ref, eventId) {
  final userId = SupabaseConfig.currentUserId;
  if (userId == null) return Stream.value(null);
  return SupabaseConfig.client
      .from('event_rsvps')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) {
        final filtered = data.where((e) => e['event_id'] == eventId).toList();
        return filtered.isNotEmpty ? EventRsvp.fromJson(filtered.first) : null;
      });
});

// All RSVPs for the current user (Map of eventId to RsvpStatus)
final myAllRsvpsProvider = StreamProvider<Map<String, RsvpStatus>>((ref) {
  final userId = SupabaseConfig.currentUserId;
  if (userId == null) return Stream.value({});
  return SupabaseConfig.client
      .from('event_rsvps')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) {
        final Map<String, RsvpStatus> rsvpMap = {};
        for (var row in data) {
          final rsvp = EventRsvp.fromJson(row);
          rsvpMap[rsvp.eventId] = rsvp.status;
        }
        return rsvpMap;
      });
});

// Live RSVP count for a specific event
final eventRsvpCountProvider = StreamProvider.family<int, String>((ref, eventId) {
  return SupabaseConfig.client
      .from('event_rsvps')
      .stream(primaryKey: ['id'])
      .eq('event_id', eventId)
      .map((data) => data.where((e) => e['status'] == RsvpStatus.confirmed.value).length);
});

// RSVP actions
class EventRsvpNotifier extends StateNotifier<AsyncValue<void>> {
  final EventsRepository _repository;

  EventRsvpNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> updateRsvp(String eventId, RsvpStatus rsvpStatus) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRsvp(eventId, rsvpStatus);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelRsvp(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelRsvp(eventId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final rsvpNotifierProvider =
    StateNotifierProvider<EventRsvpNotifier, AsyncValue<void>>((ref) {
      final repo = ref.watch(eventsRepositoryProvider);
      return EventRsvpNotifier(repo);
    });

// Event creation actions
class EventNotifier extends StateNotifier<AsyncValue<void>> {
  final EventsRepository _repository;

  EventNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<String> submitEvent({
    required String title,
    String? description,
    required String category,
    String? venue,
    required DateTime eventDate,
    DateTime? endDate,
    String? coverImageUrl,
    int? capacity,
    String? organizingClubId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repository.submitEvent(
        title: title,
        description: description,
        category: category,
        venue: venue,
        eventDate: eventDate,
        endDate: endDate,
        coverImageUrl: coverImageUrl,
        capacity: capacity,
        organizingClubId: organizingClubId,
      );
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateEvent(String eventId, {
    required String title,
    String? description,
    required String category,
    String? venue,
    required DateTime eventDate,
    DateTime? endDate,
    String? coverImageUrl,
    int? capacity,
    String? organizingClubId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateEvent(
        eventId,
        title: title,
        description: description,
        category: category,
        venue: venue,
        eventDate: eventDate,
        endDate: endDate,
        coverImageUrl: coverImageUrl,
        capacity: capacity,
        organizingClubId: organizingClubId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelEvent(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelEvent(eventId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final eventNotifierProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<void>>((ref) {
      final repo = ref.watch(eventsRepositoryProvider);
      return EventNotifier(repo);
    });
