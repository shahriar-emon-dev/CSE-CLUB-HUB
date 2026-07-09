import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../core/services/supabase_query_helper.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/club_post.dart';
import '../../../models/unified_feed_item.dart';

class PostsRepository {
  final SupabaseClient _client;

  PostsRepository({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  /// Fetches paginated timeline feed with explicit column selection
  Future<List<UnifiedFeedItem>> getTimelineFeed({int limit = 30, int offset = 0}) async {
    return SupabaseQueryHelper.runQuery('getTimelineFeed', () async {
      final data = await _client
          .from('unified_feed_timeline')
          .select('id, type, club_id, club_name, club_logo, author_id, author_name, author_avatar, title, content, image_url, created_at, is_pinned, likes_count, comments_count, user_has_liked')
          .order('created_at', ascending: false)
          .range(offset, SupabaseQueryHelper.calcEndRange(offset, limit));

      final feed = (data as List).map((e) => UnifiedFeedItem.fromJson(e)).toList();

      // Ensure pinned items stay clearly ordered at top of current window
      feed.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return feed;
    }, fallback: <UnifiedFeedItem>[]);
  }

  /// Fetches single feed item detail
  Future<UnifiedFeedItem?> getFeedItemById(String itemId) async {
    return SupabaseQueryHelper.runQuery('getFeedItemById', () async {
      final data = await _client
          .from('unified_feed_timeline')
          .select('id, type, club_id, club_name, club_logo, author_id, author_name, author_avatar, title, content, image_url, created_at, is_pinned, likes_count, comments_count, user_has_liked')
          .eq('id', itemId)
          .maybeSingle();

      if (data == null) return null;
      return UnifiedFeedItem.fromJson(data);
    }, fallback: null);
  }

  /// Fetches comments with author profiles explicitly joined
  Future<List<ClubPostComment>> getComments(String entityId) async {
    return SupabaseQueryHelper.runQuery('getComments', () async {
      final data = await _client
          .from('comments')
          .select('id, entity_id, author_id, content, created_at, profiles!inner(full_name, avatar_url, role)')
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
    }, fallback: <ClubPostComment>[]);
  }

  /// Adds a comment
  Future<void> addComment(String entityId, UnifiedFeedItemType type, String content) async {
    return SupabaseQueryHelper.runQuery('addComment', () async {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Authentication required to comment.');

      final entityType = type == UnifiedFeedItemType.event ? 'event' : 'club_post';

      await _client.from('comments').insert({
        'entity_type': entityType,
        'entity_id': entityId,
        'author_id': userId,
        'content': content,
      });
      AppLogger.info('Added comment to $entityType $entityId');
    });
  }

  /// Soft-deletes a comment
  Future<void> deleteComment(String commentId) async {
    return SupabaseQueryHelper.runQuery('deleteComment', () async {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Authentication required to delete comment.');

      await _client
          .from('comments')
          .update({'is_deleted': true})
          .eq('id', commentId)
          .eq('author_id', userId);
      AppLogger.info('Deleted comment $commentId');
    });
  }

  /// Toggles reaction atomically enforcing one reaction per user per post
  Future<void> toggleReaction(String entityId, String reactionType) async {
    return SupabaseQueryHelper.runQuery('toggleReaction', () async {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Authentication required to react.');

      final existing = await _client
          .from('club_post_reactions')
          .select('id, reaction_type')
          .eq('post_id', entityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (existing['reaction_type'] == reactionType) {
          // Same reaction clicked again -> remove reaction
          await _client
              .from('club_post_reactions')
              .delete()
              .eq('id', existing['id']);
        } else {
          // Different reaction -> switch reaction type
          await _client
              .from('club_post_reactions')
              .update({'reaction_type': reactionType})
              .eq('id', existing['id']);
        }
      } else {
        // No existing reaction -> insert atomically
        await _client.from('club_post_reactions').insert({
          'post_id': entityId,
          'user_id': userId,
          'reaction_type': reactionType,
        });
      }
      AppLogger.info('Toggled reaction $reactionType for entity $entityId');
    });
  }
}
