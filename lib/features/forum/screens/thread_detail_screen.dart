import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/forum.dart';
import '../../auth/providers/auth_provider.dart';

final threadDetailProvider = FutureProvider.family<ForumThread?, String>((ref, threadId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;

  final data = await SupabaseConfig.client
      .from('forum_threads')
      .select('*, profiles!author_id(full_name, avatar_url), forum_categories(name)')
      .eq('id', threadId)
      .maybeSingle();
  if (data == null) return null;
  // Increment view count
  await SupabaseConfig.client.rpc('increment_thread_views', params: {'thread_id': threadId});
  final json = Map<String, dynamic>.from(data);
  if (json['profiles'] != null) { json['author_name'] = json['profiles']['full_name']; json['author_avatar'] = json['profiles']['avatar_url']; }
  return ForumThread.fromJson(json);
});

final threadPostsProvider = FutureProvider.family<List<ForumPost>, String>((ref, threadId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final data = await SupabaseConfig.client
      .from('forum_posts')
      .select('*, profiles!author_id(full_name, avatar_url)')
      .eq('thread_id', threadId)
      .eq('is_deleted', false)
      .order('created_at');
  return (data as List).map((p) {
    final json = Map<String, dynamic>.from(p);
    if (json['profiles'] != null) { json['author_name'] = json['profiles']['full_name']; json['author_avatar'] = json['profiles']['avatar_url']; }
    return ForumPost.fromJson(json);
  }).toList();
});

class ThreadDetailScreen extends ConsumerStatefulWidget {
  final String threadId;
  const ThreadDetailScreen({super.key, required this.threadId});

  @override
  ConsumerState<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _submitReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await SupabaseConfig.client.from('forum_posts').insert({
        'thread_id': widget.threadId,
        'author_id': SupabaseConfig.currentUserId,
        'content': _replyCtrl.text.trim(),
      });
      _replyCtrl.clear();
      ref.invalidate(threadPostsProvider(widget.threadId));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(threadDetailProvider(widget.threadId));
    final postsAsync = ref.watch(threadPostsProvider(widget.threadId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark),
      body: Column(
        children: [
          Expanded(
            child: threadAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (thread) {
                if (thread == null) return const Center(child: Text('Thread not found'));
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Thread body
                    if (thread.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(thread.categoryName!, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(height: 12),
                    Text(thread.title, style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 12),
                    _AuthorRow(name: thread.authorName ?? 'Unknown', avatar: thread.authorAvatar, date: thread.createdAt),
                    const SizedBox(height: 16),
                    Text(thread.body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7)),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.borderDark),
                    const SizedBox(height: 8),
                    postsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                      data: (posts) => Column(
                        children: [
                          Text('${posts.length} Replies', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          ...posts.map((p) => _PostCard(post: p)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
          // Reply box
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.borderDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    decoration: const InputDecoration(hintText: 'Write a reply...', border: InputBorder.none),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _submitting ? null : _submitReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  final String name;
  final String? avatar;
  final DateTime date;
  const _AuthorRow({required this.name, this.avatar, required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          backgroundImage: avatar != null ? NetworkImage(avatar!) : null,
          child: avatar == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 12)) : null,
        ),
        const SizedBox(width: 8),
        Text(name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 8),
        Text(DateFormat('MMM d, y').format(date), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final ForumPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: post.authorName ?? 'Unknown', avatar: post.authorAvatar, date: post.createdAt),
          const SizedBox(height: 10),
          Text(post.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
