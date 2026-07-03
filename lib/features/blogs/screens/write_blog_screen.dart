import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/blogs_provider.dart';
import '../../../models/blog.dart';

class WriteBlogScreen extends ConsumerStatefulWidget {
  const WriteBlogScreen({super.key});

  @override
  ConsumerState<WriteBlogScreen> createState() => _WriteBlogScreenState();
}

class _WriteBlogScreenState extends ConsumerState<WriteBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _excerptCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  BlogCategory _selectedCategory = BlogCategory.technical;
  final List<String> _tags = [];
  final _tagCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _excerptCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag.toLowerCase()));
      _tagCtrl.clear();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = await ref.read(currentProfileProvider.future);
    if (profile == null) return;

    final id = await ref.read(blogNotifierProvider.notifier).submitBlog(
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      category: _selectedCategory.value,
      authorId: profile.id,
      excerpt: _excerptCtrl.text.trim().isEmpty ? null : _excerptCtrl.text.trim(),
      tags: _tags,
    );

    if (mounted) {
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blog submitted for review! 🎉'), backgroundColor: AppColors.success),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.somethingWentWrong), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blogState = ref.watch(blogNotifierProvider);
    final isLoading = blogState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(AppStrings.writeBlog),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(AppStrings.submitForReview),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category picker
            DropdownButtonFormField<BlogCategory>(
              initialValue: _selectedCategory,
              dropdownColor: AppColors.surfaceDark,
              decoration: const InputDecoration(labelText: 'Category'),
              items: BlogCategory.values
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.displayName)))
                  .toList(),
              onChanged: (cat) => setState(() => _selectedCategory = cat ?? BlogCategory.technical),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleCtrl,
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: const InputDecoration(
                hintText: 'Blog title...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              maxLines: null,
              validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
            ),
            const Divider(color: AppColors.borderDark),
            const SizedBox(height: 12),

            // Excerpt
            TextFormField(
              controller: _excerptCtrl,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Short excerpt (optional)...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              maxLines: 2,
            ),
            const Divider(color: AppColors.borderDark),
            const SizedBox(height: 12),

            // Content
            TextFormField(
              controller: _contentCtrl,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
              decoration: const InputDecoration(
                hintText: 'Write your blog post here...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              maxLines: null,
              minLines: 15,
              validator: (v) => (v == null || v.length < 50) ? 'Content must be at least 50 characters' : null,
            ),
            const Divider(color: AppColors.borderDark),
            const SizedBox(height: 16),

            // Tags
            Text('Tags', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a tag and press Enter',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    onFieldSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: () => _addTag(_tagCtrl.text.trim()),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text('#$tag'),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
