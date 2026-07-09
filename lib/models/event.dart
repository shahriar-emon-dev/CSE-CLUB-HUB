class Event {
  final String id;
  final String title;
  final String? description;
  final EventCategory category;
  final String? venue;
  final DateTime eventDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final int? capacity;
  final List<String> tags;
  final bool isPublished;
  final bool isCancelled;
  final String visibility; // 'public' or 'internal'
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields from event_list_view
  final String? organizingClubId;
  final String? authorName;
  final String? organizerName;
  final String? organizerAvatar;
  final int? rsvpCount;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.venue,
    required this.eventDate,
    this.endDate,
    this.coverImageUrl,
    this.capacity,
    this.tags = const [],
    required this.isPublished,
    required this.isCancelled,
    this.visibility = 'public',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.organizingClubId,
    this.authorName,
    this.organizerName,
    this.organizerAvatar,
    this.rsvpCount,
  });

  bool get isUpcoming => eventDate.isAfter(DateTime.now());
  bool get isPast => eventDate.isBefore(DateTime.now());
  bool get isFull => capacity != null && (rsvpCount ?? 0) >= capacity!;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: EventCategory.fromString(json['category'] as String? ?? 'general'),
      venue: json['venue'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String).toLocal(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String).toLocal() : null,
      coverImageUrl: json['cover_image_url'] as String? ?? json['media_asset_url'] as String?,
      capacity: json['capacity'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPublished: json['is_published'] as bool? ?? false,
      isCancelled: json['is_cancelled'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'public',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      organizingClubId: json['organizing_club_id'] as String? ?? json['club_id'] as String?,
      authorName: json['author_name'] as String?,
      organizerName: json['organizer_name'] as String? ?? json['club_name'] as String?,
      organizerAvatar: json['organizer_avatar'] as String? ?? json['club_logo_url'] as String?,
      rsvpCount: json['rsvp_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category.value,
    'venue': venue,
    'event_date': eventDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'cover_image_url': coverImageUrl,
    'capacity': capacity,
    'tags': tags,
    'is_published': isPublished,
    'is_cancelled': isCancelled,
    'visibility': visibility,
    'organizing_club_id': organizingClubId,
  };
}

enum EventCategory {
  workshop('workshop', 'Workshop'),
  seminar('seminar', 'Seminar'),
  competition('competition', 'Competition'),
  cultural('cultural', 'Cultural'),
  general('general', 'General');

  final String value;
  final String displayName;
  const EventCategory(this.value, this.displayName);

  static EventCategory fromString(String value) {
    return EventCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => EventCategory.general,
    );
  }
}

class EventRsvp {
  final String id;
  final String eventId;
  final String userId;
  final RsvpStatus status;
  final bool attended;
  final DateTime registeredAt;

  const EventRsvp({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.attended,
    required this.registeredAt,
  });

  factory EventRsvp.fromJson(Map<String, dynamic> json) {
    return EventRsvp(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      status: RsvpStatus.fromString(json['status'] as String? ?? 'confirmed'),
      attended: json['attended'] as bool? ?? false,
      registeredAt: DateTime.parse(json['registered_at'] as String).toLocal(),
    );
  }
}

enum RsvpStatus {
  confirmed('confirmed'),
  interested('interested'),
  waitlisted('waitlisted'),
  cancelled('cancelled');

  final String value;
  const RsvpStatus(this.value);

  static RsvpStatus fromString(String value) {
    return RsvpStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RsvpStatus.confirmed,
    );
  }
}
