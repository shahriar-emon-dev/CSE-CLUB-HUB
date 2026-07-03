import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/event.dart';

// All published events
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final data = await SupabaseConfig.client
      .from('event_list_view')
      .select()
      .eq('is_published', true)
      .order('event_date', ascending: true);
      
  return (data as List).map((e) => Event.fromJson(e)).toList();
});

// Club specific events
final clubEventsProvider = FutureProvider.family<List<Event>, String>((ref, clubId) async {
  final data = await SupabaseConfig.client
      .from('event_list_view')
      .select()
      .eq('organizing_club_id', clubId)
      .eq('is_published', true)
      .order('event_date', ascending: true);
      
  return (data as List).map((e) => Event.fromJson(e)).toList();
});

// Single event detail
final eventDetailProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final data = await SupabaseConfig.client
      .from('event_list_view')
      .select()
      .eq('id', eventId);
  return data.isNotEmpty ? Event.fromJson(data.first) : null;
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
  EventRsvpNotifier() : super(const AsyncValue.data(null));

  Future<void> updateRsvp(String eventId, RsvpStatus rsvpStatus) async {
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId!;
      // First check if RSVP exists
      final existing = await SupabaseConfig.client
          .from('event_rsvps')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Update
        await SupabaseConfig.client.from('event_rsvps').update({
          'status': rsvpStatus.value,
        }).eq('id', existing['id']);
      } else {
        // Insert
        await SupabaseConfig.client.from('event_rsvps').insert({
          'event_id': eventId,
          'user_id': userId,
          'status': rsvpStatus.value,
        });
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelRsvp(String eventId) async {
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId!;
      await SupabaseConfig.client
          .from('event_rsvps')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final rsvpNotifierProvider =
    StateNotifierProvider<EventRsvpNotifier, AsyncValue<void>>(
  (_) => EventRsvpNotifier(),
);

// Event creation actions
class EventNotifier extends StateNotifier<AsyncValue<void>> {
  EventNotifier() : super(const AsyncValue.data(null));

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
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Not logged in. Please sign in again.');

      final data = await SupabaseConfig.client.from('events').insert({
        'title': title,
        'description': description,
        'category': category,
        'venue': venue,
        'event_date': eventDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'cover_image_url': coverImageUrl,
        'capacity': capacity,
        'organizing_club_id': organizingClubId,
        'is_published': true, // Auto-publish for now
        'created_by': userId,
      }).select('id').single();

      state = const AsyncValue.data(null);
      return data['id'] as String;
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
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Not logged in. Please sign in again.');

      final updates = <String, dynamic>{
        'title': title,
        'description': description,
        'category': category,
        'venue': venue,
        'event_date': eventDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'capacity': capacity,
        // ignore: use_null_aware_elements
        if (organizingClubId != null) 'organizing_club_id': organizingClubId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;

      await SupabaseConfig.client.from('events').update(updates).eq('id', eventId).select('id').single();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelEvent(String eventId) async {
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Not logged in. Please sign in again.');

      await SupabaseConfig.client.from('events').update({
        'is_cancelled': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', eventId).select('id').single();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final eventNotifierProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<void>>(
  (_) => EventNotifier(),
);
