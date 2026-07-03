import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/blog.dart';

final pendingBlogsProvider = FutureProvider<List<Blog>>((ref) async {
  final data = await SupabaseConfig.client
      .from('blogs')
      .select('*, profiles!author_id(full_name)')
      .eq('status', 'pending')
      .order('created_at');
  return (data as List).map((b) {
    final json = Map<String, dynamic>.from(b);
    if (json['profiles'] != null) json['author_name'] = json['profiles']['full_name'];
    return Blog.fromJson(json);
  }).toList();
});

class AdminBlogsScreen extends ConsumerWidget {
  const AdminBlogsScreen({super.key});

  Future<void> _approve(BuildContext context, WidgetRef ref, Blog blog) async {
    await SupabaseConfig.client.from('blogs').update({
      'status': 'published',
      'published_at': DateTime.now().toIso8601String(),
    }).eq('id', blog.id);
    ref.invalidate(pendingBlogsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blog approved and published!'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, Blog blog) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Reject Blog'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null) {
      await SupabaseConfig.client.from('blogs').update({
        'status': 'rejected',
        'rejection_note': reason,
      }).eq('id', blog.id);
      ref.invalidate(pendingBlogsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogsAsync = ref.watch(pendingBlogsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text(AppStrings.manageBlogs)),
      body: blogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (blogs) {
          if (blogs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                  SizedBox(height: 16),
                  Text('No pending blogs!', style: TextStyle(color: AppColors.textSecondaryDark)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: blogs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final blog = blogs[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Pending', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(DateFormat('MMM d, y').format(blog.createdAt), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(blog.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('By ${blog.authorName ?? 'Unknown'} · ${blog.category.displayName}', style: Theme.of(context).textTheme.bodySmall),
                    if (blog.excerpt != null) ...[
                      const SizedBox(height: 8),
                      Text(blog.excerpt!, style: Theme.of(context).textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approve(context, ref, blog),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text(AppStrings.approve),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _reject(context, ref, blog),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text(AppStrings.reject),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
