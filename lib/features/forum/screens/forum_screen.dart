import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/forum.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final forumCategoriesProvider = FutureProvider<List<ForumCategory>>((ref) async {
  final data = await SupabaseConfig.client
      .from('forum_categories')
      .select()
      .order('sort_order');
  return (data as List).map((c) => ForumCategory.fromJson(c)).toList();
});

final forumThreadsProvider = FutureProvider.family<List<ForumThread>, String?>((ref, categoryId) async {
  final channelName = 'public:forum_threads:${DateTime.now().millisecondsSinceEpoch}';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'forum_threads',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  var query = SupabaseConfig.client
      .from('forum_threads')
      .select('*, profiles!author_id(full_name, avatar_url), forum_categories(name)')
      .eq('is_deleted', false);
  if (categoryId != null) query = query.eq('category_id', categoryId);
  final data = await query.order('is_pinned', ascending: false).order('last_reply_at', ascending: false);
  return (data as List).map((t) {
    final json = Map<String, dynamic>.from(t);
    if (json['profiles'] != null) {
      json['author_name'] = json['profiles']['full_name'];
      json['author_avatar'] = json['profiles']['avatar_url'];
    }
    if (json['forum_categories'] != null) {
      json['category_name'] = json['forum_categories']['name'];
    }
    return ForumThread.fromJson(json);
  }).toList();
});

class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(forumCategoriesProvider);
    final threadsAsync = ref.watch(forumThreadsProvider(_selectedCategoryId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(AppStrings.forum),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/forum/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category pills
          categoriesAsync.when(
            loading: () => const SizedBox(height: 52, child: Center(child: LinearProgressIndicator())),
            error: (_, _) => const SizedBox(),
            data: (cats) => SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _Pill(label: 'All', isSelected: _selectedCategoryId == null,
                      onTap: () => setState(() => _selectedCategoryId = null)),
                  ...cats.map((c) => _Pill(
                    label: c.name,
                    isSelected: _selectedCategoryId == c.id,
                    onTap: () => setState(() => _selectedCategoryId = c.id),
                  )),
                ],
              ),
            ),
          ),
          Expanded(
            child: threadsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (threads) {
                if (threads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_outlined, size: 64, color: AppColors.textTertiaryDark),
                        const SizedBox(height: 16),
                        const Text(AppStrings.noThreads, style: TextStyle(color: AppColors.textSecondaryDark)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/forum/create'),
                          icon: const Icon(Icons.add),
                          label: const Text(AppStrings.createThread),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ThreadTile(thread: threads[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ForumThread thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/forum/thread/${thread.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: thread.isPinned ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (thread.isPinned) ...[
                  const Icon(Icons.push_pin, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                ],
                if (thread.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(thread.categoryName!, style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                if (thread.isLocked) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondaryDark),
                ],
                const Spacer(),
                Text(
                  thread.lastReplyAt != null ? DateFormat('MMM d').format(thread.lastReplyAt!) : DateFormat('MMM d').format(thread.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(thread.title, style: Theme.of(context).textTheme.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage: thread.authorAvatar != null ? NetworkImage(thread.authorAvatar!) : null,
                  child: thread.authorAvatar == null
                      ? Text(thread.authorName?.isNotEmpty == true ? thread.authorName![0] : 'U',
                          style: const TextStyle(fontSize: 8, color: AppColors.primary))
                      : null,
                ),
                const SizedBox(width: 6),
                Text(thread.authorName ?? 'Unknown', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                const Spacer(),
                const Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.textSecondaryDark),
                const SizedBox(width: 4),
                Text('${thread.replyCount}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                const SizedBox(width: 12),
                const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textSecondaryDark),
                const SizedBox(width: 4),
                Text('${thread.viewCount}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderDark),
          ),
          child: Text(label, style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
            fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          )),
        ),
      ),
    );
  }
}
