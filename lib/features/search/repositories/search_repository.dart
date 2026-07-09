import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../core/services/supabase_query_helper.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/user_profile.dart';
import '../../../models/club.dart';
import '../../../models/event.dart';
import '../../../models/blog.dart';

class SearchResultBundle {
  final List<UserProfile> users;
  final List<Club> clubs;
  final List<Event> events;
  final List<Blog> blogs;

  const SearchResultBundle({
    this.users = const [],
    this.clubs = const [],
    this.events = const [],
    this.blogs = const [],
  });

  bool get isEmpty => users.isEmpty && clubs.isEmpty && events.isEmpty && blogs.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class SearchRepository {
  final SupabaseClient _client;

  SearchRepository({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  /// Performs server-side search with clean fallback to parallel explicit-column queries
  Future<SearchResultBundle> searchPlatform(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return const SearchResultBundle();

    return SupabaseQueryHelper.runQuery('searchPlatform', () async {
      final cleanQuery = query.trim();
      
      try {
        // Try RPC first for single-pass server-side search
        final rpcData = await _client.rpc('get_search_results', params: {
          'p_query': cleanQuery,
          'p_limit': limit,
        });

        if (rpcData is List) {
          final List<UserProfile> users = [];
          final List<Club> clubs = [];
          final List<Event> events = [];
          final List<Blog> blogs = [];

          for (final item in rpcData) {
            final type = item['entity_type'] as String?;
            if (type == 'user') {
              users.add(UserProfile(
                id: item['id'] as String,
                fullName: item['title'] as String? ?? '',
                email: item['subtitle'] as String? ?? '',
                avatarUrl: item['image_url'] as String?,
                role: UserRole.fromString(item['extra_data']?['role'] as String? ?? 'student'),
                status: item['extra_data']?['status'] as String? ?? 'active',
                isApproved: true,
                studentId: item['extra_data']?['student_id'] as String?,
                batch: item['extra_data']?['batch'] as String?,
                skills: [],
                joinedAt: DateTime.tryParse(item['extra_data']?['created_at'] as String? ?? '') ?? DateTime.now(),
                updatedAt: DateTime.now(),
              ));
            } else if (type == 'club') {
              clubs.add(Club(
                id: item['id'] as String,
                name: item['title'] as String? ?? '',
                slug: item['extra_data']?['slug'] as String? ?? '',
                description: item['extra_data']?['description'] as String?,
                categories: [item['subtitle'] as String? ?? 'Club'],
                logoUrl: item['image_url'] as String?,
                memberCount: item['extra_data']?['followers_count'] as int? ?? 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
            } else if (type == 'event') {
              events.add(Event(
                id: item['id'] as String,
                title: item['title'] as String? ?? '',
                eventDate: DateTime.tryParse(item['extra_data']?['event_date'] as String? ?? '') ?? DateTime.now(),
                venue: item['extra_data']?['venue'] as String?,
                category: EventCategory.fromString(item['extra_data']?['category'] as String? ?? 'general'),
                coverImageUrl: item['image_url'] as String?,
                organizingClubId: item['extra_data']?['organizing_club_id'] as String?,
                isPublished: true,
                isCancelled: false,
                createdAt: DateTime.tryParse(item['extra_data']?['created_at'] as String? ?? '') ?? DateTime.now(),
                updatedAt: DateTime.now(),
              ));
            } else if (type == 'post') {
              blogs.add(Blog(
                id: item['id'] as String,
                title: item['title'] as String? ?? '',
                slug: item['extra_data']?['slug'] as String? ?? item['id'] as String,
                content: '',
                authorId: item['extra_data']?['author_id'] as String? ?? '',
                authorName: item['subtitle'] as String? ?? 'Author',
                createdAt: DateTime.tryParse(item['extra_data']?['created_at'] as String? ?? '') ?? DateTime.now(),
                updatedAt: DateTime.now(),
                coverImageUrl: item['image_url'] as String?,
                category: BlogCategory.fromString(item['extra_data']?['category'] as String? ?? 'technical'),
                status: BlogStatus.published,
                viewCount: item['extra_data']?['view_count'] as int? ?? 0,
              ));
            }
          }
          return SearchResultBundle(users: users, clubs: clubs, events: events, blogs: blogs);
        }
      } catch (e) {
        AppLogger.warning('RPC get_search_results failed, using parallel fallback queries: $e');
      }

      // Fallback: Parallel queries with explicit column selections and limits
      final pattern = '%$cleanQuery%';
      final results = await Future.wait([
        _client
            .from('profiles')
            .select('id, email, full_name, role, status, avatar_url, student_id, department, batch, skills, bio, created_at')
            .ilike('full_name', pattern)
            .eq('is_approved', true)
            .limit(limit),
        _client
            .from('club_list_view')
            .select('id, name, slug, description, category, logo_url, cover_url, followers_count, status, brand_color, executive_names, upcoming_events_count')
            .ilike('name', pattern)
            .limit(limit),
        _client
            .from('event_list_view')
            .select('id, title, description, category, venue, location, event_date, end_date, cover_image_url, capacity, organizing_club_id, organizing_club_name, is_published, is_cancelled, created_by, created_at')
            .ilike('title', pattern)
            .eq('is_published', true)
            .limit(limit),
        _client
            .from('blogs')
            .select('id, title, content, author_id, created_at, cover_image_url, category, status')
            .ilike('title', pattern)
            .eq('status', 'published')
            .limit(limit),
      ]);

      return SearchResultBundle(
        users: (results[0] as List).map((m) => UserProfile.fromJson(m)).toList(),
        clubs: (results[1] as List).map((c) => Club.fromJson(c)).toList(),
        events: (results[2] as List).map((e) => Event.fromJson(e)).toList(),
        blogs: (results[3] as List).map((b) => Blog.fromJson(b)).toList(),
      );
    }, fallback: const SearchResultBundle());
  }
}
