import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/blog.dart';
import '../providers/admin_providers.dart';

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
    ref.invalidate(dashboardStatsProvider);
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
      ref.invalidate(dashboardStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogsAsync = ref.watch(pendingBlogsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          blogsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
            ),
            data: (blogs) {
              if (blogs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131F).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                      SizedBox(height: 16),
                      Text('Queue is Clear', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('No pending blog submissions awaiting administrative review.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
                    ],
                  ),
                );
              }
              return Column(
                children: blogs.map((blog) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131F).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.05), blurRadius: 15)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: const Text('PENDING REVIEW', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                            const Spacer(),
                            Text(DateFormat('MMM d, y').format(blog.createdAt), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(blog.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('By ${blog.authorName ?? 'Unknown Member'} · ${blog.category.displayName}', style: const TextStyle(color: AppColors.tertiary, fontSize: 14, fontWeight: FontWeight.w600)),
                        if (blog.excerpt != null) ...[
                          const SizedBox(height: 12),
                          Text(blog.excerpt!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approve(context, ref, blog),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Approve & Publish'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reject(context, ref, blog),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Reject Submission'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('SYSTEM ADMINISTRATION', style: TextStyle(color: AppColors.tertiary, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Club Blog Moderation', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.5)),
      ],
    );
  }
}
