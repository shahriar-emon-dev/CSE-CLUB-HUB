import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../providers/home_feed_provider.dart';
import '../providers/post_interaction_provider.dart';
import '../../../models/unified_feed_item.dart';
import '../../../models/club_post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class UnifiedPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const UnifiedPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<UnifiedPostDetailScreen> createState() => _UnifiedPostDetailScreenState();
}

class _UnifiedPostDetailScreenState extends ConsumerState<UnifiedPostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment(UnifiedFeedItemType type) async {
    if (_isSubmittingComment) return;
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return;
      final entityType = type == UnifiedFeedItemType.event ? 'event' : 'club_post';
      await SupabaseConfig.client.from('comments').insert({
        'entity_type': entityType,
        'entity_id': widget.postId,
        'author_id': userId,
        'content': content,
      });
      _commentController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      ref.invalidate(postCommentsProvider(widget.postId));
      ref.invalidate(unifiedFeedItemProvider(widget.postId));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  void _toggleReaction(String type) {
    ref.read(postReactionNotifierProvider(widget.postId).notifier).toggleReaction(type);
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(unifiedFeedItemProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => context.pop(),
              ),
              title: const Text('Post', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondaryDark),
                  onPressed: () {},
                )
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: Colors.white.withValues(alpha: 0.1), height: 1),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Atmospheric Orbs
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.transparent)),
            ),
          ),
          Positioned(
            bottom: -100, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
            ),
          ),
          Positioned.fill(
            child: postAsync.when(
              data: (post) => _buildBody(post, commentsAsync),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: postAsync.maybeWhen(
          data: (post) => _buildStickyCommentInput(post.type),
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildBody(UnifiedFeedItem post, AsyncValue<List<ClubPostComment>> commentsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostArticle(post),
              const SizedBox(height: 32),
              _buildCommentsSection(commentsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostArticle(UnifiedFeedItem post) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x992B1C16), // surface-container/60
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author & Club Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF6A00), width: 2),
                        image: post.clubLogoUrl != null && post.clubLogoUrl!.isNotEmpty
                          ? DecorationImage(image: CachedNetworkImageProvider(post.clubLogoUrl!), fit: BoxFit.cover)
                          : null,
                      ),
                      child: (post.clubLogoUrl == null || post.clubLogoUrl!.isEmpty) 
                          ? const Icon(Icons.people, color: Color(0xFFFF6A00)) 
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.clubName, style: const TextStyle(color: Color(0xFFFFB694), fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Text(post.authorName, style: const TextStyle(color: Color(0xFFE2BFB0), fontSize: 13)),
                            const Text(' • ', style: TextStyle(color: Color(0xFFE2BFB0), fontSize: 13)),
                            Text(timeago.format(post.createdAt), style: const TextStyle(color: Color(0xFFE2BFB0), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (post.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6A00).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('PINNED', style: TextStyle(color: Color(0xFFFFDBCC), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
              ],
            ),
          ),

          if (post.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(post.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),

          // Optional Image
          if (post.mediaAssetUrl != null && post.mediaAssetUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post.mediaAssetUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(height: 200, color: Colors.white.withValues(alpha: 0.05)),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Content Text
          if (post.description != null && post.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(post.description!, style: const TextStyle(color: Color(0xFFE2BFB0), fontSize: 16, height: 1.6)),
            ),
          
          // Reaction Bar (Posts only)
          if (post.type == UnifiedFeedItemType.post)
            Consumer(builder: (context, ref, _) {
              final rs = ref.watch(postReactionNotifierProvider(post.id));
              final fav = rs.counts.values.any((v) => v > 0) ? (rs.counts['favorite'] ?? 0) : post.favoriteCount;
              final fire = rs.counts.values.any((v) => v > 0) ? (rs.counts['fire'] ?? 0) : post.fireCount;
              final hand = rs.counts.values.any((v) => v > 0) ? (rs.counts['pan_tool'] ?? 0) : post.handCount;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      _buildReactionButton(
                        rs.activeReaction == 'favorite' ? Icons.favorite : Icons.favorite_border,
                        fav, 'favorite',
                        isActive: rs.activeReaction == 'favorite',
                        activeColor: const Color(0xFFFF4757),
                      ),
                      const SizedBox(width: 24),
                      _buildReactionButton(Icons.chat_bubble_outline, post.commentCount, 'comment', isStatic: true),
                      const SizedBox(width: 24),
                      _buildReactionButton(
                        rs.activeReaction == 'fire' ? Icons.local_fire_department : Icons.local_fire_department_outlined,
                        fire, 'fire',
                        isActive: rs.activeReaction == 'fire',
                        activeColor: const Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 24),
                      _buildReactionButton(
                        rs.activeReaction == 'pan_tool' ? Icons.front_hand : Icons.front_hand_outlined,
                        hand, 'pan_tool',
                        isActive: rs.activeReaction == 'pan_tool',
                        activeColor: const Color(0xFFFFD93D),
                      ),
                    ],
                  ),
                ),
              );
            }),
          
          if (post.type != UnifiedFeedItemType.post)
            const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReactionButton(IconData icon, int count, String type, {bool isStatic = false, bool isActive = false, Color? activeColor}) {
    final color = isActive ? (activeColor ?? const Color(0xFFE2BFB0)) : const Color(0xFFE2BFB0);
    return InkWell(
      onTap: isStatic ? null : () => _toggleReaction(type),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(count.toString(), style: TextStyle(color: color, fontSize: 15, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(AsyncValue<List<ClubPostComment>> commentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Community Discussion', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            commentsAsync.maybeWhen(
              data: (comments) => Text('${comments.length} comments', style: const TextStyle(color: Color(0xFFE2BFB0), fontSize: 14)),
              orElse: () => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return const Text('No comments yet. Be the first to start the discussion!', style: TextStyle(color: Color(0xFFE2BFB0)));
            }
            return Column(
              children: comments.map((comment) => _buildCommentItem(comment)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, st) => Text('Error loading comments', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  Widget _buildCommentItem(ClubPostComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: comment.authorAvatarUrl != null ? CachedNetworkImageProvider(comment.authorAvatarUrl!) : null,
            child: comment.authorAvatarUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName ?? 'Unknown', style: const TextStyle(color: Color(0xFFFFB694), fontWeight: FontWeight.bold, fontSize: 14)),
                    if (comment.isExecutive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6A00),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('EXECUTIVE', style: TextStyle(color: Color(0xFF571F00), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    const Spacer(),
                    Text(timeago.format(comment.createdAt), style: TextStyle(color: const Color(0xFFE2BFB0).withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: const Text('REPLY', style: TextStyle(color: Color(0xFFE2BFB0), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCommentInput(UnifiedFeedItemType type) {
    final isLoading = _isSubmittingComment;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2B1C16).withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: const Color(0xFFE2BFB0).withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: const Color(0xFF1D100A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: isLoading ? null : () => _submitComment(type),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6A00),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                        blurRadius: 15,
                      )
                    ],
                  ),
                  child: isLoading
                      ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Color(0xFF571F00), strokeWidth: 2.5))
                      : const Icon(Icons.send, color: Color(0xFF571F00)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
