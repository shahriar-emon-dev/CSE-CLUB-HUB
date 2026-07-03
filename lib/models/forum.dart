class ForumCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int sortOrder;
  final DateTime createdAt;
  int? threadCount;

  ForumCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.sortOrder,
    required this.createdAt,
    this.threadCount,
  });

  factory ForumCategory.fromJson(Map<String, dynamic> json) {
    return ForumCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ForumThread {
  final String id;
  final String categoryId;
  final String title;
  final String body;
  final String authorId;
  final bool isPinned;
  final bool isLocked;
  final bool isDeleted;
  final int viewCount;
  final int replyCount;
  final DateTime? lastReplyAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? authorName;
  final String? authorAvatar;
  final String? categoryName;

  const ForumThread({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.body,
    required this.authorId,
    required this.isPinned,
    required this.isLocked,
    required this.isDeleted,
    required this.viewCount,
    required this.replyCount,
    this.lastReplyAt,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.categoryName,
  });

  factory ForumThread.fromJson(Map<String, dynamic> json) {
    return ForumThread(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      authorId: json['author_id'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      viewCount: json['view_count'] as int? ?? 0,
      replyCount: json['reply_count'] as int? ?? 0,
      lastReplyAt: json['last_reply_at'] != null
          ? DateTime.parse(json['last_reply_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: json['author_name'] as String?,
      authorAvatar: json['author_avatar'] as String?,
      categoryName: json['category_name'] as String?,
    );
  }
}

class ForumPost {
  final String id;
  final String threadId;
  final String? parentId;
  final String authorId;
  final String content;
  int upvotes;
  final bool isDeleted;
  final bool isReported;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? authorName;
  final String? authorAvatar;
  bool isUpvotedByMe;

  ForumPost({
    required this.id,
    required this.threadId,
    this.parentId,
    required this.authorId,
    required this.content,
    required this.upvotes,
    required this.isDeleted,
    required this.isReported,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.isUpvotedByMe = false,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      parentId: json['parent_id'] as String?,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      upvotes: json['upvotes'] as int? ?? 0,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isReported: json['is_reported'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: json['author_name'] as String?,
      authorAvatar: json['author_avatar'] as String?,
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final String? entityType;
  final String? entityId;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.entityType,
    this.entityId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Comment {
  final String id;
  final String entityType;
  final String entityId;
  final String? parentId;
  final String authorId;
  final String content;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? authorName;
  final String? authorAvatar;
  List<Comment> replies;

  Comment({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.parentId,
    required this.authorId,
    required this.content,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      parentId: json['parent_id'] as String?,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: json['author_name'] as String?,
      authorAvatar: json['author_avatar'] as String?,
    );
  }
}
