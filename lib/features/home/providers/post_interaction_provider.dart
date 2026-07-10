import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/club_post.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/posts_repository.dart';
import 'home_feed_provider.dart';

// ---------------------------------------------------------------------------
// 1. Per-post reaction counts (realtime)
// ---------------------------------------------------------------------------
final postReactionCountsProvider =
    StreamProvider.family<Map<String, int>, String>((ref, postId) async* {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    yield {'favorite': 0, 'fire': 0, 'pan_tool': 0};
    return;
  }

  // Fetch initial counts
  yield await _fetchReactionCounts(postId);

  // Then listen for changes via realtime
  final channel = SupabaseConfig.client.channel('reactions:$postId')
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_post_reactions',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'post_id',
              value: postId),
          callback: (_) {})
      .subscribe();

  // Use a stream controller to push updates
  await for (final _ in Stream.periodic(const Duration(milliseconds: 500))) {
    // This is triggered by realtime - re-fetch counts
    break;
  }

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });
});

Future<Map<String, int>> _fetchReactionCounts(String postId) async {
  return PostsRepository().getReactionCounts(postId);
}

// ---------------------------------------------------------------------------
// 2. Current user's reaction for a post
// ---------------------------------------------------------------------------
final userReactionProvider =
    FutureProvider.family<String?, String>((ref, postId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;

  final repo = ref.watch(postsRepositoryProvider);
  return repo.getUserReaction(postId);
});

// ---------------------------------------------------------------------------
// 3. Per-post optimistic reaction state
//    This overrides the server state with local optimistic updates.
// ---------------------------------------------------------------------------
class PostReactionState {
  final String? activeReaction;
  final Map<String, int> counts;
  final bool isLoading;

  const PostReactionState({
    this.activeReaction,
    this.counts = const {'favorite': 0, 'fire': 0, 'pan_tool': 0},
    this.isLoading = false,
  });

  PostReactionState copyWith({
    String? Function()? activeReaction,
    Map<String, int>? counts,
    bool? isLoading,
  }) {
    return PostReactionState(
      activeReaction: activeReaction != null ? activeReaction() : this.activeReaction,
      counts: counts ?? this.counts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PostReactionNotifier extends StateNotifier<PostReactionState> {
  final String postId;
  final PostsRepository _repository;

  PostReactionNotifier(this.postId, this._repository)
      : super(const PostReactionState());

  /// Initialize from server data
  void initialize(String? userReaction, Map<String, int> counts) {
    if (!mounted) return;
    state = PostReactionState(
      activeReaction: userReaction,
      counts: counts,
    );
  }

  /// Optimistic toggle reaction
  Future<void> toggleReaction(String reactionType) async {
    if (state.isLoading) return;

    final previousState = state;

    // Compute optimistic state
    final newCounts = Map<String, int>.from(state.counts);

    if (state.activeReaction == reactionType) {
      // Same reaction → remove
      newCounts[reactionType] = (newCounts[reactionType] ?? 1) - 1;
      state = state.copyWith(
        activeReaction: () => null,
        counts: newCounts,
        isLoading: true,
      );
    } else {
      // Different reaction → switch
      if (state.activeReaction != null) {
        newCounts[state.activeReaction!] =
            (newCounts[state.activeReaction!] ?? 1) - 1;
      }
      newCounts[reactionType] = (newCounts[reactionType] ?? 0) + 1;
      state = state.copyWith(
        activeReaction: () => reactionType,
        counts: newCounts,
        isLoading: true,
      );
    }

    try {
      await _repository.toggleReaction(postId, reactionType);
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      AppLogger.warning('Reaction failed, rolling back: $e');
      // Rollback on error
      if (mounted) {
        state = previousState;
      }
    }
  }
}

/// Family provider that creates a notifier per post
final postReactionNotifierProvider = StateNotifierProvider.family<
    PostReactionNotifier, PostReactionState, String>((ref, postId) {
  final repo = ref.watch(postsRepositoryProvider);
  final notifier = PostReactionNotifier(postId, repo);

  // Initialize from server data asynchronously
  Future.microtask(() async {
    try {
      final userReaction = await repo.getUserReaction(postId);
      final counts = await _fetchReactionCounts(postId);
      notifier.initialize(userReaction, counts);
    } catch (e) {
      AppLogger.warning('Failed to initialize reaction state for $postId: $e');
    }
  });

  // Subscribe to realtime changes from other users
  final channelName = 'rt_reactions:$postId';
  final channel = SupabaseConfig.client
      .channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_post_reactions',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'post_id',
              value: postId),
          callback: (payload) {
            // Re-fetch from server on external changes
            Future.microtask(() async {
              try {
                final userReaction = await repo.getUserReaction(postId);
                final counts = await _fetchReactionCounts(postId);
                if (notifier.mounted && !notifier.state.isLoading) {
                  notifier.initialize(userReaction, counts);
                }
              } catch (_) {}
            });
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  return notifier;
});

// ---------------------------------------------------------------------------
// 4. Per-post comment count (for display on post card)
// ---------------------------------------------------------------------------
final postCommentCountProvider =
    FutureProvider.family<int, String>((ref, postId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return 0;

  try {
    final data = await SupabaseConfig.client
        .from('comments')
        .select('id')
        .eq('entity_id', postId)
        .eq('is_deleted', false);
    return (data as List).length;
  } catch (e) {
    return 0;
  }
});

// ---------------------------------------------------------------------------
// 5. Comments list with realtime for bottom sheet
// ---------------------------------------------------------------------------
final postCommentsProvider =
    FutureProvider.family<List<ClubPostComment>, String>((ref, entityId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'rt_comments:$entityId';
  final channel = SupabaseConfig.client
      .channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'entity_id',
              value: entityId),
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
