import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../core/services/supabase_query_helper.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/club.dart';
import '../../../models/club_executive.dart';

class ClubsRepository {
  final SupabaseClient _client;

  ClubsRepository({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  /// Fetches all active clubs with explicit column selection
  Future<List<Club>> getClubs() async {
    return SupabaseQueryHelper.runQuery('getClubs', () async {
      final data = await _client
          .from('club_list_view')
          .select()
          .order('name', ascending: true);
      return (data as List).map((e) => Club.fromJson(e)).toList();
    }, fallback: <Club>[]);
  }

  /// Fetches a specific club by id or slug
  Future<Club?> getClubByIdOrSlug(String clubSlugOrId) async {
    return SupabaseQueryHelper.runQuery('getClubByIdOrSlug', () async {
      var data = await _client
          .from('club_list_view')
          .select()
          .eq('slug', clubSlugOrId);

      if (data.isEmpty) {
        data = await _client
            .from('club_list_view')
            .select()
            .eq('id', clubSlugOrId);
      }

      return data.isNotEmpty ? Club.fromJson(data.first) : null;
    }, fallback: null);
  }

  /// Fetches executives assigned to a club
  Future<List<ClubExecutive>> getClubExecutives(String clubId) async {
    return SupabaseQueryHelper.runQuery('getClubExecutives', () async {
      final response = await _client
          .from('club_executives_view')
          .select()
          .eq('club_id', clubId);

      return (response as List).map((e) => ClubExecutive.fromJson(e)).toList();
    }, fallback: <ClubExecutive>[]);
  }

  /// Toggles club membership atomically
  Future<void> toggleMembership(String clubId, bool isCurrentlyFollowing) async {
    return SupabaseQueryHelper.runQuery('toggleMembership', () async {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Authentication required to join or leave clubs.');

      if (isCurrentlyFollowing) {
        await _client
            .from('club_followers')
            .delete()
            .eq('club_id', clubId)
            .eq('user_id', userId);
        AppLogger.info('User $userId unfollowed club $clubId');
      } else {
        await _client.from('club_followers').upsert({
          'club_id': clubId,
          'user_id': userId,
        }, onConflict: 'club_id, user_id');
        AppLogger.info('User $userId followed club $clubId');
      }
    });
  }

  /// Updates club profile information securely
  Future<void> updateClubProfile(String clubId, {
    String? name,
    String? bio,
    List<String>? categories,
    String? meetingSchedule,
    String? location,
    String? logoUrl,
    String? coverImageUrl,
  }) async {
    return SupabaseQueryHelper.runQuery('updateClubProfile', () async {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (name != null) updates['name'] = name;
      if (bio != null) updates['description'] = bio;
      if (categories != null) updates['categories'] = categories;
      if (meetingSchedule != null) updates['meeting_schedule'] = meetingSchedule;
      if (location != null) updates['location'] = location;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;

      await _client
          .from('clubs')
          .update(updates)
          .eq('id', clubId);
      AppLogger.info('Updated profile for club $clubId');
    });
  }
}
