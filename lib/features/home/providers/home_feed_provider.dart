import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/unified_feed_item.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/posts_repository.dart';

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepository();
});

const _homeFeedPageSize = 30;

class HomeFeedState {
  final List<UnifiedFeedItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  const HomeFeedState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  HomeFeedState copyWith({
    List<UnifiedFeedItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return HomeFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Paginated home feed with realtime invalidation limited to genuinely
/// structural changes (a post/event was created, edited, or removed).
///
/// Reaction counts, RSVP counts, and comment counts are intentionally NOT
/// realtime triggers here — each card already keeps those live via its own
/// per-item provider (postReactionNotifierProvider, eventRsvpCountProvider),
/// so listening for them here only caused the entire feed to refetch on
/// every single reaction/comment/RSVP anywhere in the app.
class HomeFeedNotifier extends StateNotifier<HomeFeedState> {
  final Ref _ref;
  RealtimeChannel? _channel;

  HomeFeedNotifier(this._ref, {required bool isAuthenticated}) : super(const HomeFeedState()) {
    if (isAuthenticated) {
      _subscribe();
      _loadFirstPage();
    } else {
      state = const HomeFeedState(items: [], isLoading: false, hasMore: false);
    }
  }

  void _subscribe() {
    _channel = SupabaseConfig.client
        .channel('public:home_feed')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_posts',
          callback: (payload) => _loadFirstPage(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) => _loadFirstPage(),
        )
        .subscribe();
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(postsRepositoryProvider);
      final items = await repo.getTimelineFeed(limit: _homeFeedPageSize, offset: 0);
      if (!mounted) return;
      state = HomeFeedState(
        items: items,
        isLoading: false,
        hasMore: items.length >= _homeFeedPageSize,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() => _loadFirstPage();

  Future<void> loadMore() async {
    if (!mounted || state.isLoadingMore || state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = _ref.read(postsRepositoryProvider);
      final more = await repo.getTimelineFeed(limit: _homeFeedPageSize, offset: state.items.length);
      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...more],
        isLoadingMore: false,
        hasMore: more.length >= _homeFeedPageSize,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      SupabaseConfig.client.removeChannel(channel);
    }
    super.dispose();
  }
}

final homeFeedProvider = StateNotifierProvider<HomeFeedNotifier, HomeFeedState>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return HomeFeedNotifier(ref, isAuthenticated: session != null);
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
