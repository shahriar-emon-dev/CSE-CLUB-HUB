import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/blogs_provider.dart';

class BlogDetailScreen extends ConsumerWidget {
  final String blogId;
  const BlogDetailScreen({super.key, required this.blogId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogAsync = ref.watch(blogDetailProvider(blogId));
    final likedAsync = ref.watch(blogLikeProvider(blogId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: blogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (blog) {
          if (blog == null) return const Center(child: Text('Blog not found'));

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.bgDark,
                actions: [
                  likedAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, _) => const SizedBox(),
                    data: (isLiked) => IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_outline,
                        color: isLiked ? AppColors.error : null,
                      ),
                      onPressed: () async {
                        await ref.read(blogNotifierProvider.notifier).toggleLike(blogId, isLiked);
                        ref.invalidate(blogLikeProvider(blogId));
                        ref.invalidate(blogDetailProvider(blogId));
                      },
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          blog.category.displayName,
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(blog.title, style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 16),

                      // Author row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            backgroundImage: blog.authorAvatar != null
                                ? NetworkImage(blog.authorAvatar!)
                                : null,
                            child: blog.authorAvatar == null
                                ? Text(blog.authorName?.isNotEmpty == true ? blog.authorName![0] : 'U',
                                    style: const TextStyle(color: AppColors.primary))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(blog.authorName ?? 'Unknown', style: Theme.of(context).textTheme.titleLarge),
                              Text(
                                '${blog.readTimeMins ?? 1} min read · ${blog.viewCount} views',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.borderDark),
                      const SizedBox(height: 20),

                      // Cover image
                      if (blog.coverImageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(blog.coverImageUrl!, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Content (plain text for now; integrate flutter_quill for rich text)
                      Text(blog.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7)),
                      const SizedBox(height: 32),

                      // Tags
                      if (blog.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: blog.tags.map((t) => Chip(label: Text('#$t'))).toList(),
                        ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
