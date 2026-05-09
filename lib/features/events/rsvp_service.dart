import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// GLOBAL CONSTANTS AND CONFIGURATION
// ==========================================

enum RsvpStatus {
  none,
  going,
  interested,
}

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class RsvpService {
  RsvpService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<RsvpStatus> setGoing(String eventId) async {
    await _ensureEventExists(eventId);
    await _client.rpc(
      'upsert_event_rsvp',
      params: {'p_event_id': eventId, 'p_status': 'going'},
    );
    return RsvpStatus.going;
  }

  Future<RsvpStatus> setInterested(String eventId) async {
    await _ensureEventExists(eventId);
    await _client.rpc(
      'upsert_event_rsvp',
      params: {'p_event_id': eventId, 'p_status': 'interested'},
    );
    return RsvpStatus.interested;
  }

  Future<RsvpStatus> cancelRsvp(String eventId) async {
    await _ensureEventExists(eventId);
    await _client.rpc('cancel_event_rsvp', params: {'p_event_id': eventId});
    return RsvpStatus.none;
  }

  Future<RsvpStatus> getCurrentStatus(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) return RsvpStatus.none;

    final row = await _client
        .from('rsvps')
        .select('status')
        .eq('event_id', eventId)
        .eq('user_id', user.id)
        .maybeSingle();

    final status = row?['status']?.toString();
    if (status == 'going') return RsvpStatus.going;
    if (status == 'interested') return RsvpStatus.interested;
    return RsvpStatus.none;
  }

  Future<void> deleteEventAndClearRsvps(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  Future<void> _ensureEventExists(String eventId) async {
    final event = await _client
        .from('events')
        .select('id, is_cancelled')
        .eq('id', eventId)
        .maybeSingle();

    if (event == null) {
      throw Exception('Event does not exist.');
    }

    if ((event['is_cancelled'] as bool?) ?? false) {
      throw Exception('Cannot RSVP to a cancelled event.');
    }
  }
}

