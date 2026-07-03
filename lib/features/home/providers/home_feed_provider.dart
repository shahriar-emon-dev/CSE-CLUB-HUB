import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/unified_feed_item.dart';

final homeFeedProvider = FutureProvider<List<UnifiedFeedItem>>((ref) async {
  final channelName = 'public:home_feed:${DateTime.now().millisecondsSinceEpoch}';
  
  // Listen for changes on club_posts
  final channel1 = SupabaseConfig.client.channel('${channelName}_posts')
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_posts',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  // Listen for changes on events
  final channel2 = SupabaseConfig.client.channel('${channelName}_events')
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();
      
  // Listen for reactions
  final channel3 = SupabaseConfig.client.channel('${channelName}_reactions')
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_post_reactions',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel1);
    SupabaseConfig.client.removeChannel(channel2);
    SupabaseConfig.client.removeChannel(channel3);
  });

  // Fetch the unified feed view
  final data = await SupabaseConfig.client
      .from('unified_feed_timeline')
      .select()
      .order('created_at', ascending: false);

  final feed = (data as List).map((e) => UnifiedFeedItem.fromJson(e)).toList();
  
  // Sort to keep pinned items at the top
  feed.sort((a, b) {
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    return b.createdAt.compareTo(a.createdAt);
  });

  return feed;
});
