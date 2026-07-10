import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../core/services/supabase_query_helper.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/event.dart';

class EventsRepository {
  final SupabaseClient _client;

  EventsRepository({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  /// Fetches all published events ordered by date with explicit column selection
  Future<List<Event>> getPublishedEvents() async {
    return SupabaseQueryHelper.runQuery('getPublishedEvents', () async {
      final data = await _client
          .from('event_list_view')
          .select()
          .eq('is_published', true)
          .order('event_date', ascending: true);
      return (data as List).map((e) => Event.fromJson(e)).toList();
    }, fallback: <Event>[]);
  }

  /// Fetches club-specific events
  Future<List<Event>> getClubEvents(String clubId) async {
    return SupabaseQueryHelper.runQuery('getClubEvents', () async {
      final data = await _client
          .from('event_list_view')
          .select()
          .eq('organizing_club_id', clubId)
          .eq('is_published', true)
          .order('event_date', ascending: true);
      return (data as List).map((e) => Event.fromJson(e)).toList();
    }, fallback: <Event>[]);
  }

  /// Fetches single event details by id
  Future<Event?> getEventById(String eventId) async {
    return SupabaseQueryHelper.runQuery('getEventById', () async {
      final data = await _client
          .from('event_list_view')
          .select()
          .eq('id', eventId);
      return data.isNotEmpty ? Event.fromJson(data.first) : null;
    }, fallback: null);
  }

  /// Updates or inserts an RSVP atomically using onConflict
  Future<void> updateRsvp(String eventId, RsvpStatus rsvpStatus) async {
    return SupabaseQueryHelper.runQuery('updateRsvp', () async {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Authentication required to RSVP.');

      await _client.from('event_rsvps').upsert({
        'event_id': eventId,
        'user_id': userId,
        'status': rsvpStatus.value,
        'registered_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'event_id, user_id');
      AppLogger.info('User $userId set RSVP to ${rsvpStatus.value} for event $eventId');
    });
  }

  /// Cancels/Deletes an RSVP
  Future<void> cancelRsvp(String eventId) async {
    return SupabaseQueryHelper.runQuery('cancelRsvp', () async {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Authentication required to cancel RSVP.');

      await _client
          .from('event_rsvps')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      AppLogger.info('User $userId cancelled RSVP for event $eventId');
    });
  }

  /// Creates a new event
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
    return SupabaseQueryHelper.runQuery('submitEvent', () async {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Not logged in. Please sign in again.');

      final data = await _client.from('events').insert({
        'title': title,
        'description': description,
        'category': category,
        'venue': venue,
        'event_date': eventDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'cover_image_url': coverImageUrl,
        'capacity': capacity,
        'organizing_club_id': organizingClubId,
        'is_published': true,
        'created_by': userId,
      }).select('id').single();

      AppLogger.info('Submitted event $title');
      return data['id'] as String;
    });
  }

  /// Updates existing event
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
    return SupabaseQueryHelper.runQuery('updateEvent', () async {
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
        'organizing_club_id': ?organizingClubId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;

      await _client.from('events').update(updates).eq('id', eventId).select('id').single();
      AppLogger.info('Updated event $eventId');
    });
  }

  /// Cancels an event
  Future<void> cancelEvent(String eventId) async {
    return SupabaseQueryHelper.runQuery('cancelEvent', () async {
      await _client.from('events').update({
        'is_cancelled': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', eventId);
      AppLogger.info('Cancelled event $eventId');
    });
  }
}
