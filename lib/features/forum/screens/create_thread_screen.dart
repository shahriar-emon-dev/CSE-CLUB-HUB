import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/supabase_config.dart';
import 'forum_screen.dart';

class CreateThreadScreen extends ConsumerStatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  ConsumerState<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends ConsumerState<CreateThreadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseConfig.currentUserId!;
      final data = await SupabaseConfig.client.from('forum_threads').insert({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'category_id': _selectedCategoryId,
        'author_id': userId,
      }).select('id').single();

      ref.invalidate(forumThreadsProvider(null));
      ref.invalidate(forumThreadsProvider(_selectedCategoryId));

      if (mounted) {
        context.pushReplacement('/forum/thread/${data['id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(forumCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(AppStrings.createThread),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Post'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            catsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox(),
              data: (cats) => DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                dropdownColor: AppColors.surfaceDark,
                decoration: const InputDecoration(labelText: 'Category'),
                items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: const InputDecoration(
                hintText: 'Thread title...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              maxLines: null,
              validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
            ),
            const Divider(color: AppColors.borderDark),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
              decoration: const InputDecoration(
                hintText: 'Write your post content here...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              maxLines: null,
              minLines: 10,
              validator: (v) => (v == null || v.isEmpty) ? 'Content is required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
