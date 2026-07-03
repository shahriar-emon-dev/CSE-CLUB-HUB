import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/club_post.dart';

final clubPostsProvider = FutureProvider.family<List<ClubPost>, String>((ref, clubId) async {
  final data = await SupabaseConfig.client
      .from('club_post_view')
      .select()
      .eq('club_id', clubId)
      .order('is_pinned', ascending: false)
      .order('created_at', ascending: false);

  return (data as List).map((e) => ClubPost.fromJson(e)).toList();
});

final clubPostDetailProvider = FutureProvider.family<ClubPost, String>((ref, postId) async {
  final data = await SupabaseConfig.client
      .from('club_post_view')
      .select()
      .eq('id', postId)
      .single();

  return ClubPost.fromJson(data);
});

final clubPostCommentsProvider = FutureProvider.family<List<ClubPostComment>, String>((ref, postId) async {
  final data = await SupabaseConfig.client
      .from('club_post_comments_view')
      .select()
      .eq('post_id', postId)
      .order('created_at', ascending: true);

  return (data as List).map((e) => ClubPostComment.fromJson(e)).toList();
});

class ClubPostActionsNotifier extends StateNotifier<AsyncValue<void>> {
  ClubPostActionsNotifier() : super(const AsyncValue.data(null));

  Future<void> addComment(String postId, String content) async {
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

  Future<void> toggleReaction(String postId, String reactionType) async {
    // Optimistic UI could be handled at the widget level, here we just do DB call
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
          .eq('reaction_type', reactionType)
          .maybeSingle();

      if (existing != null) {
        // Remove it
        await SupabaseConfig.client
            .from('club_post_reactions')
            .delete()
            .eq('id', existing['id']);
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
