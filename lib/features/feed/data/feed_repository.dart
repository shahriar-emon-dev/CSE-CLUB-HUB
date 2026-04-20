import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// FEED REPOSITORY (DATA LAYER)
// ==========================================

class FeedRepository {
  FeedRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // Purpose: Retrieves home feed rows through a server-side RPC for stable,
  // paginated, and backward-compatible joins/counts.
  Future<List<Map<String, dynamic>>> getHomeFeed({
    int limit = 20,
    int offset = 0,
    String? mode,
  }) async {
    final response = await _client.rpc(
      'get_home_feed_v2',
      params: {
        'p_limit': limit,
        'p_offset': offset,
        'p_mode': mode,
      },
    );

    if (response is! List) return const [];

    return response.map<Map<String, dynamic>>((row) {
      final item = Map<String, dynamic>.from(row as Map);
      final mediaRaw = item['media_urls'];
      final media = mediaRaw is List
          ? mediaRaw.map((e) => e.toString()).toList()
          : <String>[];

      return {
        'post_id': item['post_id'],
        'content': item['content'],
        'created_at': item['created_at'],
        'club': {
          'id': item['club_id'],
          'name': item['club_name'],
          'logo_url': item['club_logo_url'],
        },
        'author': {
          'id': item['author_id'],
          'name': item['author_name'],
          'role': item['author_role'],
        },
        'media': media,
        'reactions_count': {
          'like': item['like_count'] ?? 0,
          'fire': item['fire_count'] ?? 0,
          'clap': item['clap_count'] ?? 0,
          'total':
              (item['like_count'] ?? 0) +
              (item['fire_count'] ?? 0) +
              (item['clap_count'] ?? 0),
        },
        'comment_count': item['comment_count'] ?? 0,
      };
    }).toList();
  }

  Future<int> getFollowedClubCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final response = await _client
        .from('user_club_follows')
        .select('club_id')
        .eq('user_id', user.id);

    final rows = response as List;
    return rows.length;
  }

  Future<String> getEffectiveFeedMode() async {
    final response = await _client.rpc('get_effective_feed_mode');
    return response?.toString() ?? 'global';
  }

  Future<String> setFeedPreference(String mode) async {
    final response = await _client.rpc(
      'set_feed_preference',
      params: {'p_mode': mode},
    );
    return response?.toString() ?? 'global';
  }
}
