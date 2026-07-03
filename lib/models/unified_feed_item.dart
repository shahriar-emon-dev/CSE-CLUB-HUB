
enum UnifiedFeedItemType {
  post,
  event,
}

class UnifiedFeedItem {
  final UnifiedFeedItemType type;
  final String id;
  final String? clubId;
  final String clubName;
  final String? clubLogoUrl;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String? description;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Post specific
  final int commentCount;
  final int favoriteCount;
  final int fireCount;
  final int handCount;

  // Event specific
  final DateTime? eventDate;
  final DateTime? endDate;
  final String? venue;
  final String? category;
  final int? capacity;
  final int? rsvpCount;
  final String? mediaAssetUrl;

  UnifiedFeedItem({
    required this.type,
    required this.id,
    this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.title,
    this.description,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    this.commentCount = 0,
    this.favoriteCount = 0,
    this.fireCount = 0,
    this.handCount = 0,
    this.eventDate,
    this.endDate,
    this.venue,
    this.category,
    this.capacity,
    this.rsvpCount,
    this.mediaAssetUrl,
  });

  factory UnifiedFeedItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['item_type'] as String? ?? 'post';
    final type = typeStr == 'event' ? UnifiedFeedItemType.event : UnifiedFeedItemType.post;

    return UnifiedFeedItem(
      type: type,
      id: json['id'] as String,
      clubId: json['club_id'] as String?,
      clubName: json['club_name'] as String? ?? 'Unknown',
      clubLogoUrl: json['club_logo_url'] as String?,
      authorId: json['author_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Unknown',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      commentCount: json['comment_count'] as int? ?? 0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      fireCount: json['fire_count'] as int? ?? 0,
      handCount: json['hand_count'] as int? ?? 0,
      eventDate: json['event_date'] != null ? DateTime.parse(json['event_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      venue: json['venue'] as String?,
      category: json['category'] as String?,
      capacity: json['capacity'] as int?,
      rsvpCount: json['rsvp_count'] as int?,
      mediaAssetUrl: json['media_asset_url'] as String? ?? json['cover_image_url'] as String? ?? json['image_url'] as String?,
    );
  }
}
