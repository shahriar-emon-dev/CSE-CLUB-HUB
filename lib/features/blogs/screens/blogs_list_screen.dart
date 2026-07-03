import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../models/blog.dart';
import '../providers/blogs_provider.dart';

class BlogsListScreen extends ConsumerStatefulWidget {
  const BlogsListScreen({super.key});

  @override
  ConsumerState<BlogsListScreen> createState() => _BlogsListScreenState();
}

class _BlogsListScreenState extends ConsumerState<BlogsListScreen> {
  BlogCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final blogsAsync = ref.watch(blogsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(AppStrings.blogs),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.writeBlog,
            onPressed: () => context.push(AppRoutes.writeBlog),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _CategoryChip(label: 'All', isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null)),
                ...BlogCategory.values.map((cat) => _CategoryChip(
                  label: cat.displayName,
                  isSelected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                )),
              ],
            ),
          ),
          Expanded(
            child: blogsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (blogs) {
                final filtered = _selectedCategory == null
                    ? blogs
                    : blogs.where((b) => b.category == _selectedCategory).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article_outlined, size: 64, color: AppColors.textTertiaryDark),
                        const SizedBox(height: 16),
                        const Text(AppStrings.noBlogsYet, style: TextStyle(color: AppColors.textSecondaryDark)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push(AppRoutes.writeBlog),
                          icon: const Icon(Icons.edit),
                          label: const Text(AppStrings.writeBlog),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => BlogCard(blog: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BlogCard extends StatelessWidget {
  final Blog blog;
  const BlogCard({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/blogs/${blog.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.coverImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  blog.coverImageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          blog.category.displayName,
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      if (blog.readTimeMins != null)
                        Text(
                          '${blog.readTimeMins} ${AppStrings.minRead}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(blog.title, style: Theme.of(context).textTheme.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (blog.excerpt != null) ...[
                    const SizedBox(height: 6),
                    Text(blog.excerpt!, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (blog.authorAvatar != null)
                        CircleAvatar(backgroundImage: NetworkImage(blog.authorAvatar!), radius: 14)
                      else
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            blog.authorName?.isNotEmpty == true ? blog.authorName![0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(blog.authorName ?? 'Unknown', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark)),
                          if (blog.publishedAt != null)
                            Text(DateFormat('MMM d, y').format(blog.publishedAt!), style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.favorite_outline, size: 14, color: AppColors.textSecondaryDark),
                          const SizedBox(width: 4),
                          Text('${blog.likeCount ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

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
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
