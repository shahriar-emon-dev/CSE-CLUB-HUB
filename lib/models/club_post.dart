class ClubPost {
  final String id;
  final String clubId;
  final String authorId;
  final String content;
  final String? imageUrl;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  // View specific fields
  final String? clubName;
  final String? clubLogoUrl;
  final String? authorName;
  final String? authorAvatarUrl;
  final int commentCount;
  final int favoriteCount;
  final int fireCount;
  final int handCount;

  const ClubPost({
    required this.id,
    required this.clubId,
    required this.authorId,
    required this.content,
    this.imageUrl,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.clubName,
    this.clubLogoUrl,
    this.authorName,
    this.authorAvatarUrl,
    this.commentCount = 0,
    this.favoriteCount = 0,
    this.fireCount = 0,
    this.handCount = 0,
  });

  factory ClubPost.fromJson(Map<String, dynamic> json) {
    return ClubPost(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      clubName: json['club_name'] as String?,
      clubLogoUrl: json['club_logo_url'] as String?,
      authorName: json['author_name'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      commentCount: json['comment_count'] as int? ?? 0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      fireCount: json['fire_count'] as int? ?? 0,
      handCount: json['hand_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'club_id': clubId,
    'author_id': authorId,
    'content': content,
    'image_url': imageUrl,
    'is_pinned': isPinned,
  };
}

class ClubPostComment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final bool isExecutive;

  const ClubPostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.isExecutive = false,
  });

  factory ClubPostComment.fromJson(Map<String, dynamic> json) {
    return ClubPostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: json['author_name'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      isExecutive: json['is_executive'] as bool? ?? false,
    );
  }
}
