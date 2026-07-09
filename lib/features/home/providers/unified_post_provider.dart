import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/club_post.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/unified_feed_item.dart';
import 'home_feed_provider.dart';
import '../repositories/posts_repository.dart';

final unifiedCommentsProvider = FutureProvider.family<List<ClubPostComment>, String>((ref, entityId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:comments:$entityId';
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

  final repository = ref.read(postsRepositoryProvider);
  return repository.getComments(entityId);
});

class UnifiedPostActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final PostsRepository _repository;

  UnifiedPostActionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addComment(String entityId, UnifiedFeedItemType type, String content) async {
    if (state.isLoading) return;
    if (content.trim().isEmpty) {
      state = AsyncValue.error(Exception("Comment cannot be empty"), StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    try {
      await _repository.addComment(entityId, type, content);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteComment(String commentId) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteComment(commentId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleReaction(String entityId, String reactionType) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      await _repository.toggleReaction(entityId, reactionType);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final unifiedPostActionsNotifierProvider =
    StateNotifierProvider<UnifiedPostActionsNotifier, AsyncValue<void>>((ref) {
      final repo = ref.watch(postsRepositoryProvider);
      return UnifiedPostActionsNotifier(repo);
    });
