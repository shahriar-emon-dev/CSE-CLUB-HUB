import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/club_post.dart';
import '../../auth/providers/auth_provider.dart';

final clubPostsProvider = FutureProvider.family<List<ClubPost>, String>((ref, clubId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];
  final channelName = 'public:club_posts:$clubId:${DateTime.now().millisecondsSinceEpoch}';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_posts',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'club_id', value: clubId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('club_post_view')
      .select()
      .eq('club_id', clubId)
      .order('is_pinned', ascending: false)
      .order('created_at', ascending: false);

  return (data as List).map((e) => ClubPost.fromJson(e)).toList();
});

final clubPostDetailProvider = FutureProvider.family<ClubPost, String>((ref, postId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) throw Exception('Unauthenticated');

  final channelName = 'public:club_post_detail:$postId:${DateTime.now().millisecondsSinceEpoch}';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_posts',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: postId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('club_post_view')
      .select()
      .eq('id', postId)
      .single();

  return ClubPost.fromJson(data);
});

final clubPostCommentsProvider = FutureProvider.family<List<ClubPostComment>, String>((ref, postId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:club_post_comments:$postId:${DateTime.now().millisecondsSinceEpoch}';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'entity_id', value: postId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('club_post_comments_view')
      .select()
      .eq('post_id', postId)
      .order('created_at', ascending: true);

  return (data as List).map((e) => ClubPostComment.fromJson(e)).toList();
});

final itemReactionsProvider = FutureProvider.family<Map<String, int>, String>((ref, itemId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return {'favorite': 0, 'fire': 0, 'pan_tool': 0};

  final channelName = 'public:item_reactions:$itemId:${DateTime.now().millisecondsSinceEpoch}';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_post_reactions',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'post_id', value: itemId),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('club_post_reactions')
      .select('reaction_type')
      .eq('post_id', itemId);

  final list = data as List;
  int fav = 0;
  int fire = 0;
  int hand = 0;
  for (final row in list) {
    final type = row['reaction_type'] as String?;
    if (type == 'favorite') {
      fav++;
    } else if (type == 'fire') {
      fire++;
    } else if (type == 'pan_tool' || type == 'hand') {
      hand++;
    }
  }
  return {'favorite': fav, 'fire': fire, 'pan_tool': hand};
});

class ClubPostActionsNotifier extends StateNotifier<AsyncValue<void>> {
  ClubPostActionsNotifier() : super(const AsyncValue.data(null));

  Future<void> addComment(String postId, String content) async {
    if (state.isLoading) return;
    if (content.trim().isEmpty) {
      state = AsyncValue.error(Exception("Comment cannot be empty"), StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");

      await SupabaseConfig.client.from('comments').insert({
        'entity_type': 'club_post',
        'entity_id': postId,
        'author_id': userId,
        'content': content,
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> editComment(String commentId, String newContent) async {
    if (state.isLoading) return;
    if (newContent.trim().isEmpty) {
      state = AsyncValue.error(Exception("Comment cannot be empty"), StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");

      await SupabaseConfig.client
          .from('comments')
          .update({'content': newContent})
          .eq('id', commentId)
          .eq('author_id', userId);

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
          .delete()
          .eq('id', commentId)
          .eq('author_id', userId);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleReaction(String postId, String reactionType) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");

      // Check if reaction exists
      final existing = await SupabaseConfig.client
          .from('club_post_reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (existing['reaction_type'] == reactionType) {
          // Remove it
          await SupabaseConfig.client
              .from('club_post_reactions')
              .delete()
              .eq('id', existing['id']);
        } else {
          // Change it
          await SupabaseConfig.client
              .from('club_post_reactions')
              .update({'reaction_type': reactionType})
              .eq('id', existing['id']);
        }
      } else {
        // Add it
        await SupabaseConfig.client.from('club_post_reactions').insert({
          'post_id': postId,
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

final clubPostActionsNotifierProvider =
    StateNotifierProvider<ClubPostActionsNotifier, AsyncValue<void>>((_) => ClubPostActionsNotifier());

class CreateClubPostNotifier extends StateNotifier<AsyncValue<void>> {
  CreateClubPostNotifier() : super(const AsyncValue.data(null));

  Future<void> createPost({
    required String clubId,
    required String content,
    Uint8List? imageBytes,
    String? imageExtension,
    String? imageUrl,
    bool isPinned = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");

      String? finalImageUrl = imageUrl;
      
      // Handle file upload if present
      if (imageBytes != null) {
        final ext = imageExtension ?? 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 8)}.$ext';
        
        await SupabaseConfig.client.storage
            .from('posts')
            .uploadBinary(fileName, imageBytes);
            
        finalImageUrl = SupabaseConfig.client.storage
            .from('posts')
            .getPublicUrl(fileName);
      }

      // First, if this new post is pinned, maybe unpin others if we only allow 1 pinned post
      // The prompt didn't strictly require only 1 pinned post, but UI says "This replaces your current pinned post".
      if (isPinned) {
        await SupabaseConfig.client
            .from('club_posts')
            .update({'is_pinned': false})
            .eq('club_id', clubId)
            .eq('is_pinned', true);
      }

      // Insert new post
      await SupabaseConfig.client.from('club_posts').insert({
        'club_id': clubId,
        'author_id': userId,
        'content': content,
        'image_url': finalImageUrl,
        'is_pinned': isPinned,
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final createClubPostNotifierProvider =
    StateNotifierProvider<CreateClubPostNotifier, AsyncValue<void>>((_) => CreateClubPostNotifier());
