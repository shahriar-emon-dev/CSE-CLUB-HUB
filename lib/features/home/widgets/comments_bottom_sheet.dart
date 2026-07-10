import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/club_post.dart';
import '../../../models/unified_feed_item.dart';
import '../providers/post_interaction_provider.dart';
import '../repositories/posts_repository.dart';
import '../providers/home_feed_provider.dart';

/// Shows the comments bottom sheet over the feed.
void showCommentsSheet(BuildContext context, {
  required String entityId,
  required UnifiedFeedItemType type,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CommentsBottomSheet(entityId: entityId, type: type),
  );
}

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String entityId;
  final UnifiedFeedItemType type;

  const CommentsBottomSheet({
    super.key,
    required this.entityId,
    required this.type,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  String? _replyingTo; // comment id for reply
  String? _replyingToName;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Not logged in');

      final entityType = widget.type == UnifiedFeedItemType.event ? 'event' : 'club_post';

      final insertData = <String, dynamic>{
        'entity_type': entityType,
        'entity_id': widget.entityId,
        'author_id': userId,
        'content': content,
      };

      if (_replyingTo != null) {
        insertData['parent_id'] = _replyingTo;
      }

      await SupabaseConfig.client.from('comments').insert(insertData);

      _controller.clear();
      _cancelReply();

      // Invalidate to refresh comments
      ref.invalidate(postCommentsProvider(widget.entityId));

      // Scroll to bottom after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send comment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      _replyingTo = commentId;
      _replyingToName = authorName;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyingToName = null;
    });
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await SupabaseConfig.client
          .from('comments')
          .update({'is_deleted': true})
          .eq('id', commentId)
          .eq('author_id', SupabaseConfig.currentUserId ?? '');
      ref.invalidate(postCommentsProvider(widget.entityId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.entityId));
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF13131F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    commentsAsync.when(
                      data: (comments) => Text(
                        'Comments (${comments.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const Text(
                        'Comments',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      error: (_, __) => const Text(
                        'Comments',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF2A2A3A), height: 1),

              // Comments List
              Expanded(
                child: commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'No comments yet',
                              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to start the conversation!',
                              style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    // Separate top-level comments and replies
                    final topLevel = comments.where((c) => true).toList(); // All comments for now (flat until parent_id is populated)
                    
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(postCommentsProvider(widget.entityId));
                      },
                      color: AppColors.primary,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: topLevel.length,
                        itemBuilder: (context, index) {
                          return _buildCommentTile(topLevel[index]);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                        const SizedBox(height: 12),
                        Text('Failed to load comments', style: TextStyle(color: AppColors.textSecondaryDark)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(postCommentsProvider(widget.entityId)),
                          child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Reply indicator
              if (_replyingTo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: const Color(0xFF1A1A2E),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Replying to $_replyingToName',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _cancelReply,
                        child: const Icon(Icons.close, size: 16, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),

              // Input Bar (sticky above keyboard)
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D14),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Text Field
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: _replyingTo != null
                                ? 'Reply to $_replyingToName...'
                                : 'Write a comment...',
                            hintStyle: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _controller.text.trim().isNotEmpty
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send_rounded, size: 18),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              onPressed: _controller.text.trim().isNotEmpty ? _sendComment : null,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentTile(ClubPostComment comment) {
    final currentUserId = SupabaseConfig.currentUserId;
    final isOwn = currentUserId == comment.authorId;
    final timeAgoStr = timeago.format(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: comment.authorAvatarUrl != null && comment.authorAvatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: comment.authorAvatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.person, color: AppColors.primary, size: 20),
                  )
                : const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (comment.isExecutive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EXEC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      timeAgoStr,
                      style: TextStyle(
                        color: AppColors.textSecondaryDark.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _startReply(comment.id, comment.authorName ?? 'User'),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => _deleteComment(comment.id),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
