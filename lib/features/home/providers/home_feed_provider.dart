import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/unified_feed_item.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/posts_repository.dart';

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepository();
});

final homeFeedProvider = FutureProvider<List<UnifiedFeedItem>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:home_feed';
  
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_posts',
          callback: (payload) {
            ref.invalidateSelf();
          })
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
          table: 'club_post_reactions',
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
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final repository = ref.read(postsRepositoryProvider);
  return repository.getTimelineFeed(limit: 30, offset: 0);
});

final unifiedFeedItemProvider = FutureProvider.family<UnifiedFeedItem, String>((ref, itemId) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) throw Exception('Unauthenticated');

  final channelName = 'public:unified_feed_item:$itemId';
  
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_posts',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: itemId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: itemId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_post_reactions',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'post_id', value: itemId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'entity_id', value: itemId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final repository = ref.read(postsRepositoryProvider);
  final item = await repository.getFeedItemById(itemId);
  if (item == null) throw Exception('Item not found');
  return item;
});
