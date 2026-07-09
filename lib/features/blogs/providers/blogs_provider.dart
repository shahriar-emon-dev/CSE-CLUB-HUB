import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/blog.dart';
import '../../auth/providers/auth_provider.dart';

// All published blogs
final blogsProvider = FutureProvider<List<Blog>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:blogs';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'blogs',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('blog_list_view')
      .select()
      .eq('status', 'published')
      .order('published_at', ascending: false);
  return (data as List).map((b) => Blog.fromJson(b)).toList();
});

// Blogs by category
final blogsByCategoryProvider = FutureProvider.family<List<Blog>, String?>((ref, category) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  var query = SupabaseConfig.client
      .from('blog_list_view')
      .select()
      .eq('status', 'published');
  if (category != null) {
    query = query.eq('category', category);
  }
  final data = await query.order('published_at', ascending: false);
  return (data as List).map((b) => Blog.fromJson(b)).toList();
});

// Single blog detail
final blogDetailProvider = FutureProvider.family<Blog?, String>((ref, blogId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;

  final data = await SupabaseConfig.client
      .from('blogs')
      .select('*, profiles!author_id(full_name, avatar_url)')
      .eq('id', blogId)
      .maybeSingle();
  if (data == null) return null;
  // Increment view count
  await SupabaseConfig.client.rpc('increment_blog_views', params: {'blog_id': blogId});
  return Blog.fromJson(data);
});

// My blogs (author's own)
final myBlogsProvider = FutureProvider<List<Blog>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final userId = SupabaseConfig.currentUserId;
  if (userId == null) return [];
  final data = await SupabaseConfig.client
      .from('blogs')
      .select()
      .eq('author_id', userId)
      .order('created_at', ascending: false);
  return (data as List).map((b) => Blog.fromJson(b)).toList();
});

// Check if user liked a blog
final blogLikeProvider = FutureProvider.family<bool, String>((ref, blogId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return false;

  final userId = SupabaseConfig.currentUserId;
  if (userId == null) return false;
  final data = await SupabaseConfig.client
      .from('blog_likes')
      .select('id')
      .eq('blog_id', blogId)
      .eq('user_id', userId)
      .maybeSingle();
  return data != null;
});

// Blog actions notifier
class BlogNotifier extends StateNotifier<AsyncValue<void>> {
  BlogNotifier() : super(const AsyncValue.data(null));

  Future<void> toggleLike(String blogId, bool isLiked) async {
    try {
      final userId = SupabaseConfig.currentUserId!;
      if (isLiked) {
        await SupabaseConfig.client
            .from('blog_likes')
            .delete()
            .eq('blog_id', blogId)
            .eq('user_id', userId);
      } else {
        await SupabaseConfig.client
            .from('blog_likes')
            .insert({'blog_id': blogId, 'user_id': userId});
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> submitBlog({
    required String title,
    required String content,
    required String category,
    required String authorId,
    String? excerpt,
    String? coverImageUrl,
    List<String> tags = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final slug = '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${DateTime.now().millisecondsSinceEpoch}';

      final wordCount = content.split(RegExp(r'\s+')).length;
      final readTime = (wordCount / 200).ceil();

      final data = await SupabaseConfig.client.from('blogs').insert({
        'title': title,
        'slug': slug,
        'content': content,
        'excerpt': excerpt ?? content.substring(0, content.length > 200 ? 200 : content.length),
        'category': category,
        'author_id': authorId,
        'cover_image_url': coverImageUrl,
        'tags': tags,
        'status': 'pending',
        'read_time_mins': readTime,
      }).select('id').single();

      state = const AsyncValue.data(null);
      return data['id'] as String;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final blogNotifierProvider =
    StateNotifierProvider<BlogNotifier, AsyncValue<void>>(
  (_) => BlogNotifier(),
);
