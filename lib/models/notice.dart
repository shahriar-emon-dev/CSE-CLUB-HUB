class Notice {
  final String id;
  final String title;
  final String body;
  final NoticeCategory category;
  final int priority;
  final bool isPinned;
  final DateTime? expiresAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.isPinned,
    this.expiresAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUrgent => category == NoticeCategory.urgent;

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: NoticeCategory.fromString(json['category'] as String? ?? 'general'),
      priority: json['priority'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'category': category.value,
    'priority': priority,
    'is_pinned': isPinned,
    'expires_at': expiresAt?.toIso8601String(),
  };
}

enum NoticeCategory {
  urgent('urgent', 'Urgent'),
  general('general', 'General'),
  event('event', 'Event'),
  academic('academic', 'Academic'),
  other('other', 'Other');

  final String value;
  final String displayName;
  const NoticeCategory(this.value, this.displayName);

  static NoticeCategory fromString(String value) {
    return NoticeCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => NoticeCategory.general,
    );
  }
}

class GalleryAlbum {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? eventId;
  final String? createdBy;
  final DateTime createdAt;
  final int? photoCount;

  const GalleryAlbum({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.eventId,
    this.createdBy,
    required this.createdAt,
    this.photoCount,
  });

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    return GalleryAlbum(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      eventId: json['event_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      photoCount: json['photo_count'] as int?,
    );
  }
}

class GalleryPhoto {
  final String id;
  final String albumId;
  final String url;
  final String? caption;
  final String? uploadedBy;
  final DateTime createdAt;
  int likeCount;
  bool isLikedByMe;

  GalleryPhoto({
    required this.id,
    required this.albumId,
    required this.url,
    this.caption,
    this.uploadedBy,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByMe = false,
  });

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) {
    return GalleryPhoto(
      id: json['id'] as String,
      albumId: json['album_id'] as String,
      url: json['url'] as String,
      caption: json['caption'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
