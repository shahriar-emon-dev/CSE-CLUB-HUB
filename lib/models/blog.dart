class Blog {
  final String id;
  final String title;
  final String slug;
  final String? excerpt;
  final String content;
  final String? coverImageUrl;
  final BlogCategory category;
  final List<String> tags;
  final String authorId;
  final BlogStatus status;
  final String? rejectionNote;
  final int? readTimeMins;
  final int viewCount;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined from blog_list_view
  final String? authorName;
  final String? authorAvatar;
  final int? likeCount;

  const Blog({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    required this.content,
    this.coverImageUrl,
    required this.category,
    this.tags = const [],
    required this.authorId,
    required this.status,
    this.rejectionNote,
    this.readTimeMins,
    required this.viewCount,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.likeCount,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      excerpt: json['excerpt'] as String?,
      content: json['content'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      category: BlogCategory.fromString(json['category'] as String? ?? 'technical'),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      authorId: json['author_id'] as String,
      status: BlogStatus.fromString(json['status'] as String? ?? 'draft'),
      rejectionNote: json['rejection_note'] as String?,
      readTimeMins: json['read_time_mins'] as int?,
      viewCount: json['view_count'] as int? ?? 0,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: json['author_name'] as String?,
      authorAvatar: json['author_avatar'] as String?,
      likeCount: json['like_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'slug': slug,
    'excerpt': excerpt,
    'content': content,
    'cover_image_url': coverImageUrl,
    'category': category.value,
    'tags': tags,
    'author_id': authorId,
    'status': status.value,
    'read_time_mins': readTimeMins,
  };
}

enum BlogCategory {
  technical('technical', 'Technical'),
  creative('creative', 'Creative'),
  eventRecap('event_recap', 'Event Recap'),
  news('news', 'News'),
  opinion('opinion', 'Opinion');

  final String value;
  final String displayName;
  const BlogCategory(this.value, this.displayName);

  static BlogCategory fromString(String value) {
    return BlogCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => BlogCategory.technical,
    );
  }
}

enum BlogStatus {
  draft('draft', 'Draft'),
  pending('pending', 'Pending Review'),
  published('published', 'Published'),
  rejected('rejected', 'Rejected');

  final String value;
  final String displayName;
  const BlogStatus(this.value, this.displayName);

  static BlogStatus fromString(String value) {
    return BlogStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => BlogStatus.draft,
    );
  }
}
