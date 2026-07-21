import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/club.dart';
import '../../../models/club_post.dart';
import '../../clubs/providers/clubs_provider.dart';
import '../../events/providers/events_provider.dart';

class ExecutiveClubStats {
  final Club club;
  final int totalEvents;
  final int upcomingEvents;
  final int totalPosts;
  final int totalAttendees;
  final double engagementRate;
  final int pendingRsvps;

  const ExecutiveClubStats({
    required this.club,
    required this.totalEvents,
    required this.upcomingEvents,
    required this.totalPosts,
    required this.totalAttendees,
    required this.engagementRate,
    required this.pendingRsvps,
  });
}

/// Resolves the club a user actively executes from the authoritative
/// club_executives table, rather than trusting profiles.managed_club_id —
/// the two columns can drift, since club_executives is what the
/// assign/revoke executive RPCs actually write to.
final myExecutiveClubIdProvider = FutureProvider.family<String?, String>((ref, userId) async {
  final data = await SupabaseConfig.client
      .from('club_executives_view')
      .select('club_id, is_active')
      .eq('user_id', userId);

  final rows = (data as List).cast<Map<String, dynamic>>();
  final active = rows.where((r) => r['is_active'] == true);
  final row = active.isNotEmpty ? active.first : (rows.isNotEmpty ? rows.first : null);
  return row?['club_id'] as String?;
});

/// Live club-management stats for an executive's dashboard, built entirely
/// from data the app already has confirmed read access to (club_list_view,
/// club_post_view, events, event_rsvps) — no hardcoded numbers.
final executiveClubStatsProvider = FutureProvider.family<ExecutiveClubStats?, String>((ref, clubId) async {
  final client = SupabaseConfig.client;

  final clubFuture = ref.read(clubsRepositoryProvider).getClubByIdOrSlug(clubId);
  final eventsFuture = ref.read(eventsRepositoryProvider).getClubEvents(clubId);
  final postsFuture = client.from('club_post_view').select().eq('club_id', clubId);

  final club = await clubFuture;
  if (club == null) return null;

  final events = await eventsFuture;
  final postsData = await postsFuture;
  final posts = (postsData as List).map((e) => ClubPost.fromJson(e as Map<String, dynamic>)).toList();

  final eventIds = events.map((e) => e.id).toList();
  int pendingRsvps = 0;
  if (eventIds.isNotEmpty) {
    final pendingData = await client
        .from('event_rsvps')
        .select('id')
        .inFilter('event_id', eventIds)
        .eq('status', 'waitlisted');
    pendingRsvps = (pendingData as List).length;
  }

  final now = DateTime.now();
  final totalAttendees = events.fold<int>(0, (sum, e) => sum + (e.rsvpCount ?? 0));
  final totalEngagement = posts.fold<int>(0, (sum, p) => sum + p.favoriteCount + p.fireCount + p.handCount + p.commentCount);
  final engagementRate = (posts.isNotEmpty && club.memberCount > 0)
      ? ((totalEngagement / (posts.length * club.memberCount)) * 100).clamp(0.0, 100.0)
      : 0.0;

  return ExecutiveClubStats(
    club: club,
    totalEvents: events.length,
    upcomingEvents: events.where((e) => e.eventDate.isAfter(now)).length,
    totalPosts: posts.length,
    totalAttendees: totalAttendees,
    engagementRate: engagementRate,
    pendingRsvps: pendingRsvps,
  );
});
