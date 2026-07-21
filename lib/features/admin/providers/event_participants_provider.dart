import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/event.dart';

/// One RSVP row joined with the participant's real profile data — backs the
/// admin "View Participants" table. No fabricated columns: every field maps
/// directly to event_rsvps or profiles.
class EventParticipant {
  final String rsvpId;
  final String userId;
  final String fullName;
  final String? studentId;
  final String? batch;
  final String? semester;
  final String? department;
  final String? avatarUrl;
  final String? email;
  final RsvpStatus status;
  final bool attended;
  final DateTime registeredAt;

  const EventParticipant({
    required this.rsvpId,
    required this.userId,
    required this.fullName,
    this.studentId,
    this.batch,
    this.semester,
    this.department,
    this.avatarUrl,
    this.email,
    required this.status,
    required this.attended,
    required this.registeredAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return EventParticipant(
      rsvpId: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: profile?['full_name'] as String? ?? 'Unknown',
      studentId: profile?['student_id'] as String?,
      batch: profile?['batch'] as String?,
      semester: profile?['semester'] as String?,
      department: profile?['department'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      email: profile?['email'] as String?,
      status: RsvpStatus.fromString(json['status'] as String? ?? 'confirmed'),
      attended: json['attended'] as bool? ?? false,
      registeredAt: DateTime.parse(json['registered_at'] as String).toLocal(),
    );
  }
}

final eventParticipantsProvider = FutureProvider.family<List<EventParticipant>, String>((ref, eventId) async {
  final channelName = 'public:event_participants:$eventId';
  final channel = SupabaseConfig.client
      .channel(channelName)
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'event_rsvps',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'event_id', value: eventId),
        callback: (payload) => ref.invalidateSelf(),
      )
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('event_rsvps')
      .select('id, user_id, status, attended, registered_at, profiles!user_id(full_name, student_id, batch, semester, department, avatar_url, email)')
      .eq('event_id', eventId)
      .order('registered_at', ascending: false);

  return (data as List).map((e) => EventParticipant.fromJson(e as Map<String, dynamic>)).toList();
});

class ParticipantActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ParticipantActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> setAttended(String rsvpId, String eventId, bool attended) async {
    try {
      await SupabaseConfig.client.from('event_rsvps').update({'attended': attended}).eq('id', rsvpId);
      _ref.invalidate(eventParticipantsProvider(eventId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final participantActionProvider = StateNotifierProvider<ParticipantActionNotifier, AsyncValue<void>>((ref) {
  return ParticipantActionNotifier(ref);
});
