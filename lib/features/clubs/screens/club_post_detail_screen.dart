import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/club_posts_provider.dart';
import '../../../models/club_post.dart';
import 'package:timeago/timeago.dart' as timeago;

class ClubPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const ClubPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<ClubPostDetailScreen> createState() => _ClubPostDetailScreenState();
}

class _ClubPostDetailScreenState extends ConsumerState<ClubPostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    await ref.read(clubPostActionsNotifierProvider.notifier).addComment(widget.postId, content);
    _commentController.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    
    // Invalidate so it fetches the new comment
    ref.invalidate(clubPostCommentsProvider(widget.postId));
    ref.invalidate(clubPostDetailProvider(widget.postId));
  }

  void _toggleReaction(String type) async {
    await ref.read(clubPostActionsNotifierProvider.notifier).toggleReaction(widget.postId, type);
    // Invalidate to refresh counts
    ref.invalidate(clubPostDetailProvider(widget.postId));
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(clubPostDetailProvider(widget.postId));
    final commentsAsync = ref.watch(clubPostCommentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
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
      body: postAsync.when(
        data: (post) => _buildBody(post, commentsAsync),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      ),
      bottomNavigationBar: _buildStickyCommentInput(),
    );
  }

  Widget _buildBody(ClubPost post, AsyncValue<List<ClubPostComment>> commentsAsync) {
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

  Widget _buildPostArticle(ClubPost post) {
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
          // Author Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF6A00), width: 2),
                        image: post.clubLogoUrl != null 
                          ? DecorationImage(image: NetworkImage(post.clubLogoUrl!), fit: BoxFit.cover)
                          : null,
                      ),
                      child: post.clubLogoUrl == null ? const Icon(Icons.hub, color: Color(0xFFFF6A00)) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.clubName ?? 'Unknown Club', style: const TextStyle(color: Color(0xFFFFB694), fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(timeago.format(post.createdAt), style: const TextStyle(color: Color(0xFFE2BFB0), fontSize: 12)),
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
                    child: const Text('FEATURED', style: TextStyle(color: Color(0xFFFFDBCC), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
              ],
            ),
          ),

          // Optional Image
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(post.imageUrl!, fit: BoxFit.cover),
                ),
              ),
            ),

          // Content Text
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.content, style: const TextStyle(color: Color(0xFFE2BFB0), fontSize: 16, height: 1.6)),
                const SizedBox(height: 32),
                // Reaction Bar
                Container(
                  padding: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                  ),
                  child: Row(
                    children: [
                      _buildReactionButton(Icons.favorite, post.favoriteCount, 'favorite'),
                      const SizedBox(width: 24),
                      _buildReactionButton(Icons.local_fire_department, post.fireCount, 'fire'),
                      const SizedBox(width: 24),
                      _buildReactionButton(Icons.pan_tool, post.handCount, 'pan_tool'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(IconData icon, int count, String type) {
    return InkWell(
      onTap: () => _toggleReaction(type),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE2BFB0), size: 24),
            const SizedBox(width: 8),
            Text(count.toString(), style: const TextStyle(color: Color(0xFFE2BFB0), fontSize: 14, fontWeight: FontWeight.w500)),
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
              return const Text('No comments yet.', style: TextStyle(color: Color(0xFFE2BFB0)));
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
            backgroundImage: comment.authorAvatarUrl != null ? NetworkImage(comment.authorAvatarUrl!) : null,
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
                Text(comment.content, style: const TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _buildStickyCommentInput() {
    final isLoading = ref.watch(clubPostActionsNotifierProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2B1C16).withValues(alpha: 0.95),
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
                onTap: isLoading ? null : _submitComment,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
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
                      ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: Color(0xFF571F00), strokeWidth: 2))
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
