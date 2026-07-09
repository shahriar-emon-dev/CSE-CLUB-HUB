import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/club_post.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/unified_feed_item.dart';

final unifiedCommentsProvider = FutureProvider.family<List<ClubPostComment>, String>((ref, entityId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:comments:$entityId:${DateTime.now().millisecondsSinceEpoch}';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'entity_id', value: entityId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('comments')
      .select('*, profiles(full_name, avatar_url)')
      .eq('entity_id', entityId)
      .eq('is_deleted', false)
      .order('created_at', ascending: true);

  return (data as List).map((e) {
    final profile = e['profiles'] as Map<String, dynamic>?;
    final role = (profile?['role'] as String? ?? '').toLowerCase();
    return ClubPostComment(
      id: e['id'] as String,
      postId: e['entity_id'] as String,
      authorId: e['author_id'] as String,
      content: e['content'] as String,
      createdAt: DateTime.parse(e['created_at'] as String),
      authorName: profile?['full_name'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
      isExecutive: role.contains('executive') || role.contains('admin'),
    );
  }).toList();
});

class UnifiedPostActionsNotifier extends StateNotifier<AsyncValue<void>> {
  UnifiedPostActionsNotifier() : super(const AsyncValue.data(null));

  Future<void> addComment(String entityId, UnifiedFeedItemType type, String content) async {
    if (state.isLoading) return;
    if (content.trim().isEmpty) {
      state = AsyncValue.error(Exception("Comment cannot be empty"), StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");

      final entityType = type == UnifiedFeedItemType.event ? 'event' : 'club_post';

      await SupabaseConfig.client.from('comments').insert({
        'entity_type': entityType,
        'entity_id': entityId,
        'author_id': userId,
        'content': content,
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteComment(String commentId) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");

      await SupabaseConfig.client
          .from('comments')
          .update({'is_deleted': true})
          .eq('id', commentId)
          .eq('author_id', userId);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleReaction(String entityId, String reactionType) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");

      final existing = await SupabaseConfig.client
          .from('club_post_reactions')
          .select()
          .eq('post_id', entityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (existing['reaction_type'] == reactionType) {
          await SupabaseConfig.client
              .from('club_post_reactions')
              .delete()
              .eq('id', existing['id']);
        } else {
          await SupabaseConfig.client
              .from('club_post_reactions')
              .update({'reaction_type': reactionType})
              .eq('id', existing['id']);
        }
      } else {
        await SupabaseConfig.client.from('club_post_reactions').insert({
          'post_id': entityId,
          'user_id': userId,
          'reaction_type': reactionType,
        });
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final unifiedPostActionsNotifierProvider =
    StateNotifierProvider<UnifiedPostActionsNotifier, AsyncValue<void>>((_) => UnifiedPostActionsNotifier());
